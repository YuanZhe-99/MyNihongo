package com.yuanzhe.my_nihongo

import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import com.google.common.util.concurrent.ListenableFuture
import com.google.mlkit.genai.common.DownloadCallback
import com.google.mlkit.genai.common.DownloadStatus
import com.google.mlkit.genai.common.FeatureStatus
import com.google.mlkit.genai.common.GenAiException
import com.google.mlkit.genai.prompt.Generation
import com.google.mlkit.genai.prompt.GenerativeModel
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

    private var model: GenerativeModel? = null
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
        runCatching { model?.close() }
        runCatching { proofreader?.close() }
        model = null
        proofreader = null
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
     * `unavailable` or `unreachable`), the raw `code`, and a `detail` line when
     * there is something to explain.
     * Side effects: Queries AICore.
     * Notes: Internal helper used within this file only. Asked before every
     * use rather than once: the system can remove a model between two
     * requests, and a stale "available" produces a failure the learner cannot
     * interpret. The raw code and the exception travel with the answer because
     * the published device lists differ per API and are a floor rather than the
     * truth — without them a phone that has AICore and is simply not on the
     * Prompt API's list is indistinguishable from one where the call threw.
     */
    private suspend fun status(feature: String?): Map<String, Any?> {
        val code = try {
            if (feature == FEATURE_PROOFREAD) {
                proofreader().checkFeatureStatus().await()
            } else {
                model().checkStatus()
            }
        } catch (e: Throwable) {
            // Not rethrown. "AICore answered UNAVAILABLE" and "AICore could not
            // be asked at all" are different facts with different fixes, and
            // collapsing them into one reply is what left a device that has
            // AICore installed reporting that it has no on-device model.
            val cause = if (e is ExecutionException) e.cause ?: e else e
            Log.w(TAG, "status($feature) failed", cause)
            return mapOf(
                "status" to "unreachable",
                "code" to -1,
                "detail" to "${cause.javaClass.simpleName}: ${cause.message}",
            )
        }
        Log.i(TAG, "status($feature) = $code")
        val name = when (code) {
            FeatureStatus.AVAILABLE -> "available"
            FeatureStatus.DOWNLOADABLE -> "downloadable"
            FeatureStatus.DOWNLOADING -> "downloading"
            else -> "unavailable"
        }
        return mapOf(
            "status" to name,
            "code" to code,
            // Only when there is something to explain: a working feature needs
            // no diagnostic line under it.
            "detail" to if (name == "unavailable") "FeatureStatus=$code" else null,
        )
    }

    /**
     * Purpose: Describe the AICore installation this device actually has.
     * Inputs: None.
     * Returns: A map naming the AICore package version, the API level and the
     * device, or `installed = false`.
     * Side effects: Queries the package manager.
     * Notes: Internal helper used within this file only. The published device
     * lists differ per API and are a floor rather than the truth, so the only
     * way to tell "this phone is not on the list" from "AICore here is too old"
     * is to report what is installed. Reading it needs the `<queries>` entry in
     * the manifest on API 30 and up, or the package is invisible and this
     * answers `installed = false` on a device that has it.
     */
    private fun aiCoreInfo(): Map<String, Any?> {
        val device = "${Build.MANUFACTURER} ${Build.MODEL}"
        return try {
            val info = activity.packageManager.getPackageInfo(AICORE_PACKAGE, 0)
            mapOf(
                "installed" to true,
                "versionName" to info.versionName,
                "sdk" to Build.VERSION.SDK_INT,
                "device" to device,
            )
        } catch (e: PackageManager.NameNotFoundException) {
            mapOf(
                "installed" to false,
                "sdk" to Build.VERSION.SDK_INT,
                "device" to device,
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
        model().download().collect { status ->
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
        val response = model().generateContent(request)
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
     * Purpose: Get the Prompt API client, creating it once.
     * Inputs: None.
     * Returns: `GenerativeModel`.
     * Side effects: Creates an AICore client on first use.
     * Notes: Internal helper used within this file only.
     */
    private fun model(): GenerativeModel =
        model ?: Generation.getClient().also { model = it }

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
     * before the message is read. Anything unrecognised is `failed`, which the
     * UI words as "could not generate": guessing a more specific cause would
     * put a wrong explanation in front of the learner.
     */
    private fun codeFor(error: Throwable): String {
        val cause = if (error is ExecutionException) error.cause ?: error else error
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
    }
}
