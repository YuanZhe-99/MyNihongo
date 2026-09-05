package com.yuanzhe.my_nihongo

import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import com.google.common.util.concurrent.ListenableFuture
import com.google.mlkit.genai.common.DownloadCallback
import com.google.mlkit.genai.common.DownloadStatus
import com.google.mlkit.genai.common.FeatureStatus
import com.google.mlkit.genai.common.GenAiException
import com.google.mlkit.genai.common.internal.GenAiUtils
import com.google.mlkit.genai.prompt.Generation
import com.google.mlkit.genai.prompt.GenerationConfig
import com.google.mlkit.genai.prompt.GenerativeModel
import com.google.mlkit.genai.prompt.ModelConfig
import com.google.mlkit.genai.prompt.ModelPreference
import com.google.mlkit.genai.prompt.ModelReleaseStage
import com.google.mlkit.genai.prompt.TextPart
import com.google.mlkit.genai.prompt.generateContentRequest
import com.google.mlkit.genai.proofreading.Proofreader
import com.google.mlkit.genai.proofreading.ProofreaderOptions
import com.google.mlkit.genai.proofreading.Proofreading
import com.google.mlkit.genai.proofreading.ProofreadingRequest
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.suspendCancellableCoroutine
import java.util.concurrent.ExecutionException
import java.util.concurrent.Executor
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

/**
 * The bridge to Android AICore, on the method channel
 * `com.yuanzhe.my_nihongo/genai`.
 *
 * Two ML Kit GenAI clients live behind it: the Prompt API's [GenerativeModel],
 * which answers a free-form request, and the Proofreading API's [Proofreader],
 * which corrects one short Japanese sentence. Both run on the device through
 * the AICore system service.
 *
 * There is no Flutter plugin here on purpose. The published ones are 0.x, wrap
 * the Prompt API only, and would each apply the Kotlin Gradle Plugin — the
 * constraint that already pins `file_picker` and `speech_to_text`. See
 * `doc/en-us/android-aicore.md`.
 *
 * Policy — whether the feature is on, what the prompt says, how the answer is
 * trimmed — lives on the Dart side, where it is testable without a device.
 * This class is a pipe.
 */
class GenAiChannel(private val activity: MainActivity) : MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)

    /** The one request allowed to be in flight; a second is refused as busy. */
    private var inFlight: Job? = null

    /** The Prompt API client for [promptVariant], built by the first probe. */
    private var model: GenerativeModel? = null

    /** Which variant [model] asks AICore for; null until one is found. */
    private var promptVariant: Variant? = null

    /** The variants AICore refused, in the order they were tried. */
    private var refusedVariants: List<String> = emptyList()

    private var proofreader: Proofreader? = null

    /**
     * Purpose: Attach the channel to a Flutter engine.
     * Inputs: `flutterEngine` — the engine the activity attached.
     * Returns: None.
     * Side effects: Registers this object as the channel handler.
     * Notes: The AICore clients are not created here. Constructing one on a
     * device without AICore is what fails, and it has to fail inside a call
     * that can answer `unavailable`, not during engine setup.
     */
    fun attach(flutterEngine: FlutterEngine) {
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler(this)
    }

    /**
     * Purpose: Release both models and stop any request in flight.
     * Inputs: None.
     * Returns: None.
     * Side effects: Closes both AICore clients and cancels the scope.
     * Notes: Called from `MainActivity.onDestroy`. A model left open holds an
     * AICore session, which is a shared device resource.
     */
    fun detach() {
        scope.cancel()
        closePrompt()
        runCatching { proofreader?.close() }
        proofreader = null
        refusedVariants = emptyList()
    }

    /**
     * Purpose: Route one method call.
     * Inputs: `call`, `result`.
     * Returns: None.
     * Side effects: May run a model on the device.
     * Notes: Every failure is a `result.error` carrying one of the codes the
     * Dart `GenAiFailure` enum knows, never an exception across the channel:
     * the Dart side turns each into a sentence the learner can act on.
     */
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "status" -> run(result) { status(call.argument<String>("feature")) }
            "aicore" -> run(result) { aiCoreInfo() }
            "download" -> run(result) { download(call.argument<String>("feature")) }
            "explain" -> run(result) {
                explain(
                    call.argument<String>("prompt").orEmpty(),
                    call.argument<Int>("maxOutputTokens") ?: 256,
                    (call.argument<Double>("temperature") ?: 0.2).toFloat(),
                    call.argument<Int>("topK") ?: 16,
                )
            }
            "proofread" -> run(result) { proofread(call.argument<String>("text").orEmpty()) }
            "cancel" -> {
                inFlight?.cancel()
                inFlight = null
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    /**
     * Purpose: Run one suspending body as the channel's single in-flight job.
     * Inputs: `result`, and the `body` producing the value to send back.
     * Returns: None.
     * Side effects: Starts a coroutine; replies on the channel exactly once.
     * Notes: Internal helper used within this file only. The busy check lives
     * here rather than in each method so no path can forget it: AICore serves
     * one inference at a time per app, and a second concurrent request fails
     * in a way much harder to explain than "one at a time".
     */
    private fun run(result: MethodChannel.Result, body: suspend () -> Any?) {
        if (inFlight?.isActive == true) {
            result.error("busy", "Another request is already running", null)
            return
        }
        inFlight = scope.launch {
            try {
                result.success(body())
            } catch (e: CancellationException) {
                result.error("cancelled", "The request was cancelled", null)
            } catch (e: Throwable) {
                // Logged, not silent: by the time this reaches Dart it is one
                // of five codes, and "unavailable" on a device that should be
                // supported is otherwise undiagnosable. The exception only —
                // never the prompt, which is the learner's own writing.
                Log.w(TAG, "GenAI call failed: ${e.javaClass.simpleName}", e)
                result.error(codeFor(e), e.message, null)
            }
        }
    }

    /**
     * Purpose: Report whether a feature can be used, downloaded, or not at all.
     * Inputs: `feature` — `prompt` or `proofread`.
     * Returns: A map of `status` (`available`, `downloadable`, `downloading`,
     * `unavailable`, `unknown` or `unreachable`), the raw `code`, and for the
     * Prompt API the `variant` that answered, the ones that `refused`, and the
     * model's `baseModelName` and `tokenLimit` when it is ready; plus a
     * `detail` line when there is something to explain.
     * Side effects: Queries AICore, and may build and close model clients.
     * Notes: Internal helper used within this file only. Asked before every
     * use rather than once: the system can remove a model between two
     * requests, and a stale "available" produces a failure the learner cannot
     * interpret.
     *
     * The Prompt API answer is the **probe's**, not one fixed model's. Asking
     * for a single variant and reporting its refusal as the device's answer is
     * what produced two wrong diagnoses in a row; see [probePrompt].
     */
    private suspend fun status(feature: String?): Map<String, Any?> {
        if (feature == FEATURE_PROOFREAD) {
            val code = try {
                proofreader().checkFeatureStatus().await()
            } catch (e: Throwable) {
                return unreachable("proofread", e)
            }
            Log.i(TAG, "status(proofread) = $code")
            val name = nameFor(code)
            return mapOf(
                "status" to name,
                "code" to code,
                "detail" to if (name == "available") null else "FeatureStatus=$code",
            )
        }

        val probe = probePrompt()
        probe.error?.let { return unreachable("prompt", it) }
        val name = nameFor(probe.code)
        val ready = name == "available"
        Log.i(TAG, "status(prompt) = ${probe.code} ($name) via ${probe.variant?.label}")
        return mapOf(
            "status" to name,
            "code" to probe.code,
            "variant" to probe.variant?.label,
            "refused" to refusedVariants.joinToString(", ").ifEmpty { null },
            // Only when a model is actually ready: on a refusing device these
            // two calls throw, and a diagnostic that throws is worse than one
            // that is absent.
            "baseModelName" to
                if (ready) runCatching { model?.getBaseModelName() }.getOrNull() else null,
            "tokenLimit" to
                if (ready) runCatching { model?.getTokenLimit() }.getOrNull() else null,
            "detail" to if (ready) null else detail(probe.code),
        )
    }

    /**
     * Purpose: Name a `FeatureStatus` value.
     * Inputs: `code`.
     * Returns: `String`.
     * Side effects: None.
     * Notes: Internal helper used within this file only. An unrecognised value
     * is `unknown` rather than `unavailable`: this set has grown before, and
     * reading a future value as a refusal is the same mistake that had the app
     * telling a working device it was not supported.
     */
    private fun nameFor(code: Int): String = when (code) {
        FeatureStatus.AVAILABLE -> "available"
        FeatureStatus.DOWNLOADABLE -> "downloadable"
        FeatureStatus.DOWNLOADING -> "downloading"
        FeatureStatus.UNAVAILABLE -> "unavailable"
        else -> "unknown"
    }

    /**
     * Purpose: Build the diagnostic line shown under a refusal.
     * Inputs: `code`.
     * Returns: `String`.
     * Side effects: None.
     * Notes: Internal helper used within this file only. It names every
     * variant that was tried, because "unavailable" on its own is the sentence
     * that took two releases to disprove.
     */
    private fun detail(code: Int): String {
        val refused = refusedVariants
        return if (refused.isEmpty()) {
            "FeatureStatus=$code"
        } else {
            "FeatureStatus=$code · refused: ${refused.joinToString(", ")}"
        }
    }

    /**
     * Purpose: Answer a status request that could not be asked at all.
     * Inputs: `feature`, for the log line, and the `error` that was thrown.
     * Returns: The reply map.
     * Side effects: Logs.
     * Notes: Internal helper used within this file only. Not rethrown. "AICore
     * answered UNAVAILABLE" and "AICore could not be asked at all" are
     * different facts with different fixes, and collapsing them into one reply
     * is what left a device that has AICore installed reporting that it has no
     * on-device model.
     */
    private fun unreachable(feature: String, error: Throwable): Map<String, Any?> {
        val cause = if (error is ExecutionException) error.cause ?: error else error
        Log.w(TAG, "status($feature) failed", cause)
        return mapOf(
            "status" to "unreachable",
            "code" to -1,
            "detail" to "${cause.javaClass.simpleName}: ${cause.message}",
        )
    }

    /**
     * Purpose: Describe the AICore installation this device actually has.
     * Inputs: None.
     * Returns: A map naming the AICore package version, the API level, the
     * device and whether AICore considers itself compatible here, or
     * `installed = false`.
     * Side effects: Queries the package manager and ML Kit.
     * Notes: Internal helper used within this file only. The published device
     * lists differ per API and are a floor rather than the truth, so the only
     * way to tell "this phone is not on the list" from "AICore here is too old"
     * is to report what is installed. Reading it needs the `<queries>` entry in
     * the manifest on API 30 and up, or the package is invisible and this
     * answers `installed = false` on a device that has it.
     *
     * `compatible` comes from ML Kit's own internal helper, the same check its
     * clients make before they will serve anything. On a device that refuses
     * every model variant it separates "AICore is absent or too old here" from
     * "AICore is fine, this model is simply not offered", which no public API
     * answers. It is an internal API, so it is guarded and optional rather than
     * relied on; the exact Gradle pins are what keep that safe.
     */
    private fun aiCoreInfo(): Map<String, Any?> {
        val device = "${Build.MANUFACTURER} ${Build.MODEL}"
        val compatible = runCatching { GenAiUtils.isAiCoreCompatible(activity) }.getOrNull()
        return try {
            val info = activity.packageManager.getPackageInfo(AICORE_PACKAGE, 0)
            mapOf(
                "installed" to true,
                "versionName" to info.versionName,
                "sdk" to Build.VERSION.SDK_INT,
                "device" to device,
                "compatible" to compatible,
            )
        } catch (e: PackageManager.NameNotFoundException) {
            mapOf(
                "installed" to false,
                "sdk" to Build.VERSION.SDK_INT,
                "device" to device,
                "compatible" to compatible,
            )
        }
    }

    /**
     * Purpose: Ask AICore to fetch a feature's model.
     * Inputs: `feature`.
     * Returns: `Boolean` — true when the download completed.
     * Side effects: AICore downloads a model over the network; progress is
     * pushed back to Dart as `downloadProgress`.
     * Notes: Internal helper used within this file only. **The app downloads
     * nothing itself** — it asks the AICore system service to, and the privacy
     * policy says so. The two APIs report progress differently: the Prompt API
     * emits a `Flow`, the feature APIs take a callback.
     */
    private suspend fun download(feature: String?): Boolean {
        if (feature == FEATURE_PROOFREAD) {
            return suspendCancellableCoroutine { cont ->
                val future = proofreader().downloadFeature(
                    object : DownloadCallback {
                        override fun onDownloadStarted(bytesToDownload: Long) =
                            reportProgress(FEATURE_PROOFREAD, 0L, bytesToDownload)

                        override fun onDownloadProgress(totalBytesDownloaded: Long) =
                            reportProgress(FEATURE_PROOFREAD, totalBytesDownloaded, -1L)

                        override fun onDownloadCompleted() {
                            if (cont.isActive) cont.resume(true)
                        }

                        override fun onDownloadFailed(e: GenAiException) {
                            if (cont.isActive) cont.resumeWithException(e)
                        }
                    },
                )
                cont.invokeOnCancellation { future.cancel(true) }
            }
        }
        var failure: Throwable? = null
        promptModel().download().collect { status ->
            when (status) {
                is DownloadStatus.DownloadStarted ->
                    reportProgress(FEATURE_PROMPT, 0L, status.bytesToDownload)
                is DownloadStatus.DownloadProgress ->
                    reportProgress(FEATURE_PROMPT, status.totalBytesDownloaded, -1L)
                is DownloadStatus.DownloadFailed -> failure = status.e
                else -> Unit
            }
        }
        failure?.let { throw it }
        return true
    }

    /**
     * Purpose: Generate one answer from a prompt.
     * Inputs: `prompt`, `maxOutputTokens`, `temperature`, `topK`.
     * Returns: `String` — the first candidate's text, or empty.
     * Side effects: Runs Gemini Nano on the device.
     * Notes: Internal helper used within this file only. Non-streaming: the
     * answer is at most four sentences and is shown as one block, so streaming
     * would add a partial state to the UI for no gain. One candidate, because
     * showing a second would mean ranking them, and nothing here can.
     */
    private suspend fun explain(
        prompt: String,
        maxOutputTokens: Int,
        temperature: Float,
        topK: Int,
    ): String {
        val request = generateContentRequest(TextPart(prompt)) {
            this.temperature = temperature
            this.topK = topK
            this.candidateCount = 1
            this.maxOutputTokens = maxOutputTokens
        }
        val response = promptModel().generateContent(request)
        return response.candidates.firstOrNull()?.text.orEmpty()
    }

    /**
     * Purpose: Ask for corrected versions of one short Japanese sentence.
     * Inputs: `text`.
     * Returns: `List<String>` — the suggestions, best first, possibly empty.
     * Side effects: Runs the proofreading model on the device.
     * Notes: Internal helper used within this file only. The client is built
     * for Japanese keyboard input; the length cap is applied on the Dart side,
     * which is the layer that knows the API's 256-token limit.
     */
    private suspend fun proofread(text: String): List<String> {
        val request = ProofreadingRequest.builder(text).build()
        val result = proofreader().runInference(request).await()
        val suggestions = ArrayList<String>()
        for (suggestion in result.results) {
            suggestions.add(suggestion.text)
        }
        return suggestions
    }

    /**
     * Purpose: Get the Prompt API client for the variant this device serves.
     * Inputs: None.
     * Returns: `GenerativeModel`.
     * Side effects: Probes AICore on first use.
     * Notes: Internal helper used within this file only. Throws rather than
     * handing back a client for a variant nothing will serve: a request sent
     * to one of those fails later and further from the cause.
     */
    private suspend fun promptModel(): GenerativeModel {
        model?.let { return it }
        probePrompt()
        return model ?: throw IllegalStateException(
            "the Prompt API is not available on this device " +
                "(refused: ${refusedVariants.joinToString(", ").ifEmpty { "none" }})",
        )
    }

    /**
     * Purpose: Find a Prompt API model variant this device will actually serve.
     * Inputs: None.
     * Returns: [Probe] — the status of the variant that answered, or the error
     * when none of them could be asked.
     * Side effects: Builds AICore clients, keeps at most one, closes the rest.
     * Notes: Internal helper used within this file only.
     *
     * **This is the fix for two wrong diagnoses.** The app used to call
     * `Generation.getClient()` with no configuration, which asks for exactly
     * one variant: the stable, full-size model. ML Kit's own guidance is that
     * not every device serves every release stage and size preference, that an
     * `UNAVAILABLE` from `checkStatus()` is *that variant's* answer rather than
     * the device's, and that an app must implement a fallback. Without one, a
     * Galaxy Z Fold8 with a working AICore reported "no on-device model"
     * through two releases, and both attempts to explain it were wrong.
     *
     * So the variants are tried in order and the first that is not
     * `UNAVAILABLE` wins. Nothing here names a device, a client version or a
     * model: a variant this list does not yet know is one line, and a model
     * AICore begins serving tomorrow is picked up with no change at all.
     *
     * A variant already serving is kept rather than re-probed, because a probe
     * costs one round trip per variant and this runs before every generation.
     * It is re-probed the moment that variant stops serving.
     */
    private suspend fun probePrompt(): Probe {
        val chosen = promptVariant
        val current = model
        if (chosen != null && current != null) {
            val code = runCatching { current.checkStatus() }.getOrNull()
            if (code != null && code != FeatureStatus.UNAVAILABLE) {
                return Probe(code, chosen, null)
            }
        }
        closePrompt()

        val refused = ArrayList<String>()
        var refusal: Int? = null
        var lastError: Throwable? = null
        for (variant in VARIANTS) {
            val client = try {
                Generation.getClient(
                    GenerationConfig.Builder().apply {
                        modelConfig = ModelConfig.builder().apply {
                            releaseStage = variant.stage
                            preference = variant.preference
                        }.build()
                    }.build(),
                )
            } catch (e: Throwable) {
                Log.w(TAG, "getClient(${variant.label}) failed", e)
                lastError = e
                refused.add("${variant.label} (${e.javaClass.simpleName})")
                continue
            }
            val code = try {
                client.checkStatus()
            } catch (e: Throwable) {
                Log.w(TAG, "checkStatus(${variant.label}) failed", e)
                lastError = e
                refused.add("${variant.label} (${e.javaClass.simpleName})")
                runCatching { client.close() }
                continue
            }
            if (code == FeatureStatus.UNAVAILABLE) {
                Log.i(TAG, "checkStatus(${variant.label}) = UNAVAILABLE")
                refusal = code
                refused.add(variant.label)
                runCatching { client.close() }
                continue
            }
            Log.i(TAG, "serving ${variant.label}, FeatureStatus=$code")
            model = client
            promptVariant = variant
            refusedVariants = refused
            return Probe(code, variant, null)
        }
        refusedVariants = refused
        // One refusal means AICore was reachable and said no, which is
        // `unavailable`. Only a device where every variant threw is
        // `unreachable`, and that is a different problem with a different fix.
        return if (refusal != null) {
            Probe(refusal, null, null)
        } else {
            Probe(-1, null, lastError ?: IllegalStateException("no variants configured"))
        }
    }

    /**
     * Purpose: Drop the Prompt API client and everything known about it.
     * Inputs: None.
     * Returns: None.
     * Side effects: Closes the client.
     * Notes: Internal helper used within this file only. A client left open
     * holds an AICore session, which is a shared device resource.
     */
    private fun closePrompt() {
        runCatching { model?.close() }
        model = null
        promptVariant = null
    }

    /**
     * One Prompt API model variant, and the name it is reported under.
     *
     * `label` is what Settings shows and what the log prints, deliberately the
     * same string in both, so a screenshot and a logcat line can be lined up.
     */
    private class Variant(val stage: Int, val preference: Int, val label: String)

    /** What one round of probing found: a status, or the reason there is none. */
    private class Probe(val code: Int, val variant: Variant?, val error: Throwable?)

    /**
     * Purpose: Get the proofreading client, creating it once.
     * Inputs: None.
     * Returns: `Proofreader`.
     * Side effects: Creates an AICore client on first use.
     * Notes: Internal helper used within this file only. Japanese and keyboard
     * input are fixed: this app proofreads a sentence the learner typed, in
     * the one language it teaches.
     */
    private fun proofreader(): Proofreader = proofreader ?: Proofreading.getClient(
        ProofreaderOptions.builder(activity)
            .setLanguage(ProofreaderOptions.Language.JAPANESE)
            .setInputType(ProofreaderOptions.InputType.KEYBOARD)
            .build(),
    ).also { proofreader = it }

    /**
     * Purpose: Tell Dart how far a model download has got.
     * Inputs: `feature`, `bytes` downloaded so far, `total` or -1 when unknown.
     * Returns: None.
     * Side effects: Sends a method call to Dart.
     * Notes: Internal helper used within this file only. Advisory: a dropped
     * progress message costs one progress-bar update and never correctness,
     * so it is sent without a result callback.
     */
    private fun reportProgress(feature: String, bytes: Long, total: Long) {
        channel.invokeMethod(
            "downloadProgress",
            mapOf("feature" to feature, "bytes" to bytes, "total" to total),
        )
    }

    /**
     * Purpose: Turn a thrown error into one of the codes Dart knows.
     * Inputs: `error`.
     * Returns: `String`.
     * Side effects: None.
     * Notes: Internal helper used within this file only. A `ListenableFuture`
     * wraps its cause in an `ExecutionException`, so the cause is unwrapped
     * before anything is read. The library's own `errorCode` is used whenever
     * there is one: matching English substrings was a guess that a reworded or
     * localized message would have broken silently. Anything unrecognised is
     * `failed`, which the UI words as "could not generate" — guessing a more
     * specific cause would put a wrong explanation in front of the learner.
     */
    private fun codeFor(error: Throwable): String {
        val cause = if (error is ExecutionException) error.cause ?: error else error
        if (cause is GenAiException) {
            when (cause.errorCode) {
                GenAiException.ErrorCode.NOT_AVAILABLE,
                GenAiException.ErrorCode.NOT_SUPPORTED,
                GenAiException.ErrorCode.AICORE_INCOMPATIBLE,
                GenAiException.ErrorCode.NEEDS_SYSTEM_UPDATE,
                -> return "unavailable"
                GenAiException.ErrorCode.REQUEST_TOO_LARGE -> return "tooLong"
                GenAiException.ErrorCode.BUSY -> return "busy"
                GenAiException.ErrorCode.CANCELLED -> return "cancelled"
            }
        }
        val message = cause.message.orEmpty().lowercase()
        return when {
            message.contains("not available") || message.contains("unavailable") -> "unavailable"
            message.contains("too long") || message.contains("token") -> "tooLong"
            else -> "failed"
        }
    }

    /**
     * Purpose: Await a `ListenableFuture` from a coroutine.
     * Inputs: The future.
     * Returns: Its value.
     * Side effects: Cancels the future if the coroutine is cancelled.
     * Notes: Internal helper used within this file only. Written out rather
     * than taken from `kotlinx-coroutines-guava`, which would pull the whole
     * of Guava into the APK for one function.
     */
    private suspend fun <T> ListenableFuture<T>.await(): T =
        suspendCancellableCoroutine { cont ->
            addListener(
                {
                    try {
                        cont.resume(get())
                    } catch (e: Throwable) {
                        cont.resumeWithException(e)
                    }
                },
                Executor { it.run() },
            )
            cont.invokeOnCancellation { cancel(true) }
        }

    companion object {
        /** The channel name, matched by `MethodChannelGenAiBackend` in Dart. */
        const val CHANNEL = "com.yuanzhe.my_nihongo/genai"

        /** The log tag; see doc/en-us/android-aicore.md for what to grep. */
        private const val TAG = "MyNihongoGenAi"

        /** The Prompt API, used for explanations. */
        const val FEATURE_PROMPT = "prompt"

        /** The Proofreading API, used for correction suggestions. */
        const val FEATURE_PROOFREAD = "proofread"

        /** The AICore system service, whose version decides what is served. */
        private const val AICORE_PACKAGE = "com.google.android.aicore"

        /**
         * The Prompt API model variants, in the order they are tried.
         *
         * Preference order, not capability order: the full-size model gives
         * the better explanation, so it is asked for first at each release
         * stage, and the preview stage is asked only after both stable sizes
         * have refused. A device on the AICore developer preview reaches a
         * model this way; a device on the consumer build never sees one
         * offered, which is a refusal like any other and is reported as such.
         *
         * Adding a stage or a preference is one line here and nothing else.
         */
        private val VARIANTS = listOf(
            Variant(ModelReleaseStage.STABLE, ModelPreference.FULL, "stable/full"),
            Variant(ModelReleaseStage.STABLE, ModelPreference.FAST, "stable/fast"),
            Variant(ModelReleaseStage.PREVIEW, ModelPreference.FULL, "preview/full"),
            Variant(ModelReleaseStage.PREVIEW, ModelPreference.FAST, "preview/fast"),
        )
    }
}
