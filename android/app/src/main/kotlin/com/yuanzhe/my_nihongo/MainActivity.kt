package com.yuanzhe.my_nihongo

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * The app's only activity.
 *
 * Its app-owned `com.yuanzhe.my_nihongo/system` channel lets Settings
 * send the user to the system text-to-speech settings when no Japanese voice is
 * installed: there is no Flutter plugin for that intent and it is one call, so
 * the channel stays deliberately small. AI is registered by the generated myapps_ai_platform plugin.
 */
class MainActivity : FlutterActivity() {

    /**
     * Purpose: Register the system channel and generated plugins.
     * Inputs: `flutterEngine` — the engine this activity attaches to.
     * Returns: None.
     * Side effects: Adds method-call handlers to the engine.
     * Notes: `openSpeechSettings` answers true when the intent was started and
     * false when no activity on the device handles it, so the Dart side can
     * show a message rather than leaving the user waiting. Shared AI clients
     * are created lazily by the plugin.
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
