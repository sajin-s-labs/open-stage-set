package com.example.project_orbit

import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioTrack
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Random
import java.util.concurrent.CopyOnWriteArrayList
import kotlin.math.*

class MainActivity : FlutterActivity() {
    private val channelName = "org.openstageset/audio_synth"
    private var nativeSynth: NativeAudioSynth? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        if (nativeSynth == null) {
            nativeSynth = NativeAudioSynth()
            nativeSynth?.start()
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                val synth = nativeSynth
                if (synth == null) {
                    result.success(null)
                    return@setMethodCallHandler
                }

                when (call.method) {
                    "playMidiNote" -> {
                        val midi = (call.argument<Number>("midi"))?.toInt() ?: 60
                        val duration = (call.argument<Number>("durationSeconds"))?.toDouble() ?: 1.0
                        val volume = (call.argument<Number>("volume"))?.toDouble() ?: 0.4
                        synth.playMidiNote(midi, duration, volume)
                        result.success(true)
                    }
                    "playChord" -> {
                        val rawNotes = call.argument<List<*>>("midiNotes")
                        val midiNotes = rawNotes?.mapNotNull { (it as? Number)?.toInt() } ?: listOf(60, 64, 67)
                        val duration = (call.argument<Number>("durationSeconds"))?.toDouble() ?: 1.6
                        val volume = (call.argument<Number>("volume"))?.toDouble() ?: 0.3
                        synth.playChord(midiNotes, duration, volume)
                        result.success(true)
                    }
                    "playDrum" -> {
                        val type = call.argument<String>("type") ?: "kick"
                        val volume = (call.argument<Number>("volume"))?.toDouble() ?: 0.3
                        synth.playDrum(type, volume)
                        result.success(true)
                    }
                    "stop" -> {
                        synth.stopAll()
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onPause() {
        nativeSynth?.pause()
        super.onPause()
    }

    override fun onResume() {
        super.onResume()
        nativeSynth?.resume()
    }

    override fun onDestroy() {
        nativeSynth?.release()
        nativeSynth = null
        super.onDestroy()
    }
}

/**
 * Real-time procedural audio synthesis engine for Android using a single streaming AudioTrack.
 * Supports polyphonic musical notes (dual oscillator: triangle + sine overtone) and synthesized percussion.
 */
class NativeAudioSynth {
    private val sampleRate = 44100
    private val activeVoices = CopyOnWriteArrayList<ActiveVoice>()
    private val lock = Object()
    @Volatile private var isRunning = false
    private var audioThread: Thread? = null
    private var audioTrack: AudioTrack? = null

    fun start() {
        if (isRunning) return
        isRunning = true

        val minBufSize = AudioTrack.getMinBufferSize(
            sampleRate,
            AudioFormat.CHANNEL_OUT_MONO,
            AudioFormat.ENCODING_PCM_16BIT
        )
        val bufferSize = max(minBufSize, 4096)

        try {
            audioTrack = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                AudioTrack.Builder()
                    .setAudioAttributes(
                        AudioAttributes.Builder()
                            .setUsage(AudioAttributes.USAGE_MEDIA)
                            .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                            .build()
                    )
                    .setAudioFormat(
                        AudioFormat.Builder()
                            .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                            .setSampleRate(sampleRate)
                            .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
                            .build()
                    )
                    .setBufferSizeInBytes(bufferSize)
                    .setTransferMode(AudioTrack.MODE_STREAM)
                    .build()
            } else {
                @Suppress("DEPRECATION")
                AudioTrack(
                    AudioManager.STREAM_MUSIC,
                    sampleRate,
                    AudioFormat.CHANNEL_OUT_MONO,
                    AudioFormat.ENCODING_PCM_16BIT,
                    bufferSize,
                    AudioTrack.MODE_STREAM
                )
            }
            audioTrack?.play()
        } catch (e: Exception) {
            e.printStackTrace()
            return
        }

        audioThread = Thread({
            val frameSize = 256 // ~5.8ms frames for responsive low-latency audio
            val floatBuf = FloatArray(frameSize)
            val shortBuf = ShortArray(frameSize)

            while (isRunning) {
                val track = audioTrack ?: break

                if (activeVoices.isEmpty()) {
                    synchronized(lock) {
                        while (activeVoices.isEmpty() && isRunning) {
                            try {
                                lock.wait(200)
                            } catch (e: InterruptedException) {
                                break
                            }
                        }
                    }
                    if (!isRunning) break
                    if (track.playState != AudioTrack.PLAYSTATE_PLAYING) {
                        try { track.play() } catch (_: Exception) {}
                    }
                }

                floatBuf.fill(0f)

                val it = activeVoices.iterator()
                while (it.hasNext()) {
                    val voice = it.next()
                    val finished = voice.render(floatBuf, frameSize, sampleRate)
                    if (finished) {
                        activeVoices.remove(voice)
                    }
                }

                for (i in 0 until frameSize) {
                    var s = floatBuf[i]
                    // Soft clipping to avoid digital harshness
                    if (s > 1.0f) s = 1.0f
                    else if (s < -1.0f) s = -1.0f
                    shortBuf[i] = (s * 32767f).toInt().toShort()
                }

                track.write(shortBuf, 0, frameSize)
            }
        }, "OpenStageSet-AudioMixer")

        audioThread?.priority = Thread.MAX_PRIORITY
        audioThread?.isDaemon = true
        audioThread?.start()
    }

    fun playMidiNote(midi: Int, durationSeconds: Double, volume: Double) {
        val freq = 440.0 * 2.0.pow((midi - 69).toDouble() / 12.0)
        val voice = SynthNoteVoice(doubleArrayOf(freq), durationSeconds, volume.toFloat())
        activeVoices.add(voice)
        synchronized(lock) {
            lock.notifyAll()
        }
    }

    fun playChord(midiNotes: List<Int>, durationSeconds: Double, volume: Double) {
        if (midiNotes.isEmpty()) return
        val freqs = DoubleArray(midiNotes.size) { i ->
            440.0 * 2.0.pow((midiNotes[i] - 69).toDouble() / 12.0)
        }
        val voice = SynthNoteVoice(freqs, durationSeconds, volume.toFloat())
        activeVoices.add(voice)
        synchronized(lock) {
            lock.notifyAll()
        }
    }

    fun playDrum(type: String, volume: Double) {
        val voice = DrumVoice(type, volume.toFloat())
        activeVoices.add(voice)
        synchronized(lock) {
            lock.notifyAll()
        }
    }

    fun pause() {
        try {
            audioTrack?.pause()
        } catch (_: Exception) {}
    }

    fun resume() {
        try {
            if (audioTrack?.playState != AudioTrack.PLAYSTATE_PLAYING) {
                audioTrack?.play()
            }
        } catch (_: Exception) {}
    }

    fun stopAll() {
        activeVoices.clear()
    }

    fun release() {
        isRunning = false
        synchronized(lock) {
            lock.notifyAll()
        }
        try {
            audioThread?.join(500)
        } catch (_: Exception) {}
        try {
            audioTrack?.stop()
            audioTrack?.release()
        } catch (_: Exception) {}
        audioTrack = null
        activeVoices.clear()
    }
}

interface ActiveVoice {
    fun render(outBuffer: FloatArray, frameSize: Int, sampleRate: Int): Boolean
}

class SynthNoteVoice(
    private val frequencies: DoubleArray,
    private val durationSeconds: Double,
    private val volume: Float
) : ActiveVoice {
    private var sampleIndex = 0
    private val totalSamples = max(1, (durationSeconds * 44100.0).toInt())
    private val noteVolume = (volume / max(1.0f, frequencies.size * 0.45f)).coerceIn(0.05f, 0.6f)

    override fun render(outBuffer: FloatArray, frameSize: Int, sampleRate: Int): Boolean {
        val totalSec = durationSeconds
        val sr = sampleRate.toDouble()
        for (i in 0 until frameSize) {
            if (sampleIndex >= totalSamples) return true

            val t = sampleIndex.toDouble() / sr

            // ADSR Envelope: 20ms attack, decay to 50% at 250ms, exponential release fade
            val env = when {
                t < 0.02 -> (t / 0.02)
                t < 0.25 -> 1.0 - 0.5 * ((t - 0.02) / 0.23)
                else -> {
                    val rem = ((t - 0.25) / max(0.01, totalSec - 0.25)).coerceIn(0.0, 1.0)
                    0.5 * (1.0 - rem)
                }
            }

            var sampleVal = 0.0
            for (freq in frequencies) {
                // Triangle wave body
                val phase = (t * freq) % 1.0
                val tri = 4.0 * abs(phase - 0.5) - 1.0
                // Sine wave overtone (1 octave higher for sparkle)
                val overtone = sin(2.0 * PI * (freq * 2.0) * t) * 0.15
                sampleVal += (tri + overtone)
            }

            // Ramp-in during the first 88 samples (~2ms) to prevent initial click
            val ramp = if (sampleIndex < 88) (sampleIndex.toFloat() / 88f) else 1.0f

            outBuffer[i] += (sampleVal * env * noteVolume * ramp).toFloat()
            sampleIndex++
        }
        return sampleIndex >= totalSamples
    }
}

class DrumVoice(
    private val type: String,
    private val volume: Float
) : ActiveVoice {
    private var sampleIndex = 0
    private val random = Random()

    override fun render(outBuffer: FloatArray, frameSize: Int, sampleRate: Int): Boolean {
        val sr = sampleRate.toDouble()
        for (i in 0 until frameSize) {
            val t = sampleIndex.toDouble() / sr
            var sampleVal = 0.0
            var finished = false

            when (type) {
                "kick" -> {
                    if (t >= 0.28) finished = true
                    else {
                        val freq = 36.0 + (150.0 - 36.0) * exp(-t * 22.0)
                        val env = exp(-t * 12.0)
                        sampleVal = sin(2.0 * PI * freq * t) * env * 0.95
                    }
                }
                "snare" -> {
                    if (t >= 0.2) finished = true
                    else {
                        val freq = 65.0 + (220.0 - 65.0) * exp(-t * 20.0)
                        val toneEnv = exp(-t * 16.0)
                        val phase = (t * freq) % 1.0
                        val tone = (4.0 * abs(phase - 0.5) - 1.0) * toneEnv * 0.6
                        val noise = (random.nextFloat() * 2.0 - 1.0) * exp(-t * 24.0) * 0.4
                        sampleVal = tone + noise
                    }
                }
                "hihat" -> {
                    if (t >= 0.05) finished = true
                    else {
                        val noise = (random.nextFloat() * 2.0 - 1.0)
                        val env = exp(-t * 70.0)
                        sampleVal = noise * env * 0.35
                    }
                }
                "click_accent" -> {
                    if (t >= 0.05) finished = true
                    else {
                        val freq = 600.0 + 600.0 * exp(-t * 50.0)
                        val env = exp(-t * 40.0)
                        sampleVal = sin(2.0 * PI * freq * t) * env * 0.8
                    }
                }
                "click_regular" -> {
                    if (t >= 0.04) finished = true
                    else {
                        val freq = 400.0 + 400.0 * exp(-t * 60.0)
                        val env = exp(-t * 50.0)
                        sampleVal = sin(2.0 * PI * freq * t) * env * 0.5
                    }
                }
                else -> finished = true
            }

            if (finished) return true

            val ramp = if (sampleIndex < 88) (sampleIndex.toFloat() / 88f) else 1.0f
            outBuffer[i] += (sampleVal * volume * ramp).toFloat()
            sampleIndex++
        }
        return false
    }
}
