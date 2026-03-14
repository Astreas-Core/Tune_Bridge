package com.tunebridge.tune_bridge

import androidx.annotation.NonNull
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.media.audiofx.Equalizer

class MainActivity : AudioServiceActivity() {
    private val CHANNEL = "com.tunebridge/equalizer"

    companion object {
        private var equalizer: Equalizer? = null
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            try {
                if (call.method == "init") {
                        val sessionId = call.argument<Int>("sessionId")
                        if (sessionId != null) {
                            // Release previous if exists to avoid leaks or multi-effects
                            equalizer?.release()
                            equalizer = Equalizer(0, sessionId)
                            equalizer?.enabled = true
                            result.success(true)
                        } else {
                            result.error("INVALID_ARGS", "Session ID required", null)
                        }
                } else if (call.method == "enable") {
                        val enabled = call.argument<Boolean>("enabled") ?: false
                        equalizer?.enabled = enabled
                        result.success(null)
                } else if (call.method == "getBandLevelRange") {
                        val range = equalizer?.bandLevelRange
                        if (range != null) {
                            result.success(listOf(range[0].toInt(), range[1].toInt()))
                        } else {
                            result.error("NO_EQUALIZER", "Equalizer not initialized", null)
                        }
                } else if (call.method == "getCenterBandFreqs") {
                        val bands = equalizer?.numberOfBands ?: 0.toShort()
                        val freqs = mutableListOf<Int>()
                        for (i in 0 until bands) {
                            freqs.add(equalizer?.getCenterFreq(i.toShort()) ?: 0)
                        }
                        result.success(freqs)
                } else if (call.method == "getBandLevel") {
                        val bandId = call.argument<Int>("bandId")
                        if (bandId != null && equalizer != null) {
                             val level = equalizer?.getBandLevel(bandId.toShort())
                             result.success(level?.toInt())
                        } else {
                             result.error("NO_EQUALIZER", "Equalizer not initialized or invalid band", null)
                        }
                } else if (call.method == "setBandLevel") {
                        val bandId = call.argument<Int>("bandId")
                        val level = call.argument<Int>("level")
                        if (bandId != null && level != null && equalizer != null) {
                            equalizer?.setBandLevel(bandId.toShort(), level.toShort())
                            result.success(null)
                        } else {
                            result.error("NO_EQUALIZER", "Valid arguments required", null)
                        }
                } else if (call.method == "release") {
                        equalizer?.release()
                        equalizer = null
                        result.success(null)
                } else {
                    result.notImplemented()
                }
            } catch (e: Exception) {
                result.error("ERROR", e.message, null)
            }
        }
    }

    // Removed onDestroy to prevent Equalizer from being released when Activity is destroyed (e.g. backgrounded)
}
