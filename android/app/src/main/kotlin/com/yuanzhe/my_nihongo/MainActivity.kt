package com.yuanzhe.my_nihongo

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * The app's only activity.
 *
 * It hosts two method channels. `com.yuanzhe.my_nihongo/system` lets Settings
 * send the user to the system text-to-speech settings when no Japanese voice is
 * installed: there is no Flutter plugin for that intent and it is one call, so
 * the channel stays deliberately small. `com.yuanzhe.my_nihongo/genai` is
 * [GenAiChannel], the bridge to Android AICore.
 */
class MainActivity : FlutterActivity() {
    private val genAi = GenAiChannel(this)

    /**
     * Purpose: Register the two method channels.
     * Inputs: `flutterEngine` — the engine this activity attaches to.
     * Returns: None.
     * Side effects: Adds method-call handlers to the engine.
     * Notes: `openSpeechSettings` answers true when the intent was started and
     * false when no activity on the device handles it, so the Dart side can
     * show a message rather than leaving the user waiting. [GenAiChannel]
     * creates no AICore client here — see its own note on why.
     */
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.yuanzhe.my_nihongo/system",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "openSpeechSettings" -> result.success(openSpeechSettings())
                else -> result.notImplemented()
            }
        }
        genAi.attach(flutterEngine)
    }

    /**
     * Purpose: Release the AICore clients when the activity goes away.
     * Inputs: None.
     * Returns: None.
     * Side effects: Closes both generative models.
     * Notes: An open model holds an AICore session, which is shared across the
     * device; leaking one would deny it to whatever the user opens next.
     */
    override fun onDestroy() {
        genAi.detach()
        super.onDestroy()
    }

    /**
     * Purpose: Start the system text-to-speech settings screen.
     * Inputs: None.
     * Returns: `Boolean` — false when no activity handles the intent.
     * Side effects: Starts another activity.
     * Notes: The action is `com.android.settings.TTS_SETTINGS`, which most but
     * not all Android builds provide; the return value is what tells the caller.
     */
    private fun openSpeechSettings(): Boolean {
        return try {
            val intent = Intent("com.android.settings.TTS_SETTINGS")
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
            true
        } catch (e: Exception) {
            false
        }
    }
}
