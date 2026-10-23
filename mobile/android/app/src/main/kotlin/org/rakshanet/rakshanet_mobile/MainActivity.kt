package org.rakshanet.rakshanet_mobile

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioRecord
import android.media.AudioTrack
import android.media.MediaRecorder
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.os.BatteryManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.security.MessageDigest
import java.util.concurrent.ArrayBlockingQueue

class MainActivity : FlutterActivity(), LocationListener {
    private val channelName = "org.rakshanet/telemetry"
    private val offlineAudioChannelName = "org.rakshanet/offline_audio"
    private val offlineAudioCaptureChannelName = "org.rakshanet/offline_audio_capture"
    private val pcmSampleRate = 16_000
    private val pcmFrameBytes = 640 // 20ms, mono, 16-bit PCM at 16kHz
    private var locationManager: LocationManager? = null
    private var lastGpsLocation: Location? = null
    private var isListeningToLocation = false

    private var audioRecord: AudioRecord? = null
    private var audioTrack: AudioTrack? = null
    private var captureThread: Thread? = null
    private var playbackThread: Thread? = null
    @Volatile private var captureRunning = false
    @Volatile private var playbackRunning = false
    private var captureEventSink: EventChannel.EventSink? = null
    private val mainHandler = Handler(Looper.getMainLooper())
    private val playbackFrames = ArrayBlockingQueue<ByteArray>(12)

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        locationManager = getSystemService(Context.LOCATION_SERVICE) as? LocationManager
        requestLocationUpdatesIfPermitted()

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "getTelemetry" -> {
                    val battery = getBatteryLevel()
                    val online = isNetworkAvailable()
                    val gps = getGpsStatus()
                    val data = hashMapOf(
                        "batteryLevel" to battery,
                        "isOnline" to online,
                        "hasGpsFix" to (gps["hasGpsFix"] as? Boolean ?: false),
                        "latitude" to gps["latitude"],
                        "longitude" to gps["longitude"],
                        "accuracy" to gps["accuracy"]
                    )
                    result.success(data)
                }
                "getBatteryLevel" -> {
                    result.success(getBatteryLevel())
                }
                "isOnline" -> {
                    result.success(isNetworkAvailable())
                }
                "getGpsStatus" -> {
                    result.success(getGpsStatus())
                }
                "getHardwareImeiId" -> {
                    result.success(getHardwareImeiId())
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, offlineAudioChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startCapture" -> result.success(startOfflineCapture())
                    "stopCapture" -> {
                        stopOfflineCapture()
                        result.success(null)
                    }
                    "startPlayback" -> result.success(startOfflinePlayback())
                    "playFrame" -> {
                        val pcm = call.arguments as? ByteArray
                        if (pcm == null || pcm.isEmpty()) {
                            result.error("invalid_pcm", "A PCM frame is required.", null)
                        } else {
                            enqueuePlaybackFrame(pcm)
                            result.success(null)
                        }
                    }
                    "setSpeakerphone" -> {
                        val enabled = call.arguments as? Boolean
                        if (enabled == null) {
                            result.error("invalid_route", "A speakerphone value is required.", null)
                        } else {
                            setSpeakerphone(enabled)
                            result.success(null)
                        }
                    }
                    "stopAudio" -> {
                        stopOfflineAudio()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, offlineAudioCaptureChannelName)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    captureEventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    captureEventSink = null
                }
            })
    }

    private fun startOfflineCapture(): Boolean {
        if (checkSelfPermission(Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
            return false
        }
        if (captureRunning) return true
        val minBuffer = AudioRecord.getMinBufferSize(
            pcmSampleRate,
            AudioFormat.CHANNEL_IN_MONO,
            AudioFormat.ENCODING_PCM_16BIT
        )
        if (minBuffer <= 0) return false
        return try {
            prepareAudioRoute()
            val recorder = AudioRecord(
                MediaRecorder.AudioSource.VOICE_COMMUNICATION,
                pcmSampleRate,
                AudioFormat.CHANNEL_IN_MONO,
                AudioFormat.ENCODING_PCM_16BIT,
                maxOf(minBuffer, pcmFrameBytes * 10)
            )
            if (recorder.state != AudioRecord.STATE_INITIALIZED) {
                recorder.release()
                return false
            }
            recorder.startRecording()
            audioRecord = recorder
            captureRunning = true
            captureThread = Thread {
                val frame = ByteArray(pcmFrameBytes)
                while (captureRunning) {
                    val read = recorder.read(frame, 0, frame.size, AudioRecord.READ_BLOCKING)
                    if (read > 0 && captureRunning) {
                        val outbound = frame.copyOf(read)
                        mainHandler.post { captureEventSink?.success(outbound) }
                    }
                }
            }.apply {
                name = "RakshaNetNearbyAudioCapture"
                start()
            }
            true
        } catch (_: Exception) {
            stopOfflineCapture()
            false
        }
    }

    private fun stopOfflineCapture() {
        captureRunning = false
        try {
            audioRecord?.stop()
        } catch (_: Exception) {
        }
        try {
            audioRecord?.release()
        } catch (_: Exception) {
        }
        audioRecord = null
        captureThread = null
    }

    private fun startOfflinePlayback(): Boolean {
        if (playbackRunning) return true
        val minBuffer = AudioTrack.getMinBufferSize(
            pcmSampleRate,
            AudioFormat.CHANNEL_OUT_MONO,
            AudioFormat.ENCODING_PCM_16BIT
        )
        if (minBuffer <= 0) return false
        return try {
            prepareAudioRoute()
            val track = AudioTrack.Builder()
                .setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_VOICE_COMMUNICATION)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                        .build()
                )
                .setAudioFormat(
                    AudioFormat.Builder()
                        .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                        .setSampleRate(pcmSampleRate)
                        .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
                        .build()
                )
                // A 240ms queue absorbs ordinary Nearby packet jitter. Excess
                // frames are dropped rather than extending call latency.
                .setBufferSizeInBytes(maxOf(minBuffer, pcmFrameBytes * 12))
                .setTransferMode(AudioTrack.MODE_STREAM)
                .build()
            if (track.state != AudioTrack.STATE_INITIALIZED) {
                track.release()
                return false
            }
            audioTrack = track
            playbackRunning = true
            track.play()
            playbackThread = Thread {
                val silence = ByteArray(pcmFrameBytes)
                while (playbackRunning) {
                    val pcm = playbackFrames.poll() ?: silence
                    track.write(pcm, 0, pcm.size, AudioTrack.WRITE_BLOCKING)
                }
            }.apply {
                name = "RakshaNetNearbyAudioPlayback"
                start()
            }
            true
        } catch (_: Exception) {
            stopOfflinePlayback()
            false
        }
    }

    private fun enqueuePlaybackFrame(pcm: ByteArray) {
        if (!playbackRunning) return
        val copy = pcm.copyOf()
        if (!playbackFrames.offer(copy)) {
            playbackFrames.poll()
            playbackFrames.offer(copy)
        }
    }

    private fun stopOfflinePlayback() {
        playbackRunning = false
        playbackFrames.clear()
        try {
            audioTrack?.pause()
            audioTrack?.flush()
            audioTrack?.stop()
        } catch (_: Exception) {
        }
        try {
            audioTrack?.release()
        } catch (_: Exception) {
        }
        audioTrack = null
        playbackThread = null
    }

    @Suppress("DEPRECATION")
    private fun prepareAudioRoute() {
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as? AudioManager ?: return
        audioManager.mode = AudioManager.MODE_IN_COMMUNICATION
        audioManager.requestAudioFocus(
            null,
            AudioManager.STREAM_VOICE_CALL,
            AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_EXCLUSIVE
        )
    }

    @Suppress("DEPRECATION")
    private fun setSpeakerphone(enabled: Boolean) {
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as? AudioManager ?: return
        audioManager.mode = AudioManager.MODE_IN_COMMUNICATION
        audioManager.isSpeakerphoneOn = enabled
    }

    @Suppress("DEPRECATION")
    private fun stopOfflineAudio() {
        stopOfflineCapture()
        stopOfflinePlayback()
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as? AudioManager
        try {
            audioManager?.isSpeakerphoneOn = false
            audioManager?.mode = AudioManager.MODE_NORMAL
            audioManager?.abandonAudioFocus(null)
        } catch (_: Exception) {
        }
    }

    override fun onPause() {
        // There is intentionally no foreground call service in this offline
        // implementation. Stop capture/playback rather than silently keeping
        // the microphone active while the app is not visible.
        stopOfflineAudio()
        super.onPause()
    }

    override fun onDestroy() {
        stopOfflineAudio()
        super.onDestroy()
    }

    private fun getHardwareImeiId(): String {
        return try {
            val androidId = Settings.Secure.getString(contentResolver, Settings.Secure.ANDROID_ID) ?: ""
            val rawFingerprint = "$androidId|${Build.MANUFACTURER}|${Build.MODEL}|${Build.BOARD}|${Build.HARDWARE}|${Build.DEVICE}"
            val digest = MessageDigest.getInstance("SHA-256").digest(rawFingerprint.toByteArray(Charsets.UTF_8))
            val digits = StringBuilder("86") // Standard 2-digit TAC prefix for mobile equipment
            var idx = 0
            while (digits.length < 14) {
                val b = (digest[idx % digest.size].toInt() and 0xFF)
                digits.append((b % 10).toString())
                idx++
            }
            val base14 = digits.toString().substring(0, 14)
            val checkDigit = computeLuhnCheckDigit(base14)
            "$base14$checkDigit"
        } catch (e: Exception) {
            ""
        }
    }

    private fun computeLuhnCheckDigit(base14: String): Int {
        var sum = 0
        for (i in base14.indices) {
            var d = base14[i].digitToInt()
            if (i % 2 == 1) {
                d *= 2
                if (d > 9) d -= 9
            }
            sum += d
        }
        return (10 - (sum % 10)) % 10
    }

    private fun getBatteryLevel(): Int {
        return try {
            val bm = getSystemService(Context.BATTERY_SERVICE) as? BatteryManager
            val cap = bm?.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY) ?: -1
            if (cap in 0..100) return cap

            val ifilter = IntentFilter(Intent.ACTION_BATTERY_CHANGED)
            val batteryStatus = registerReceiver(null, ifilter)
            val level = batteryStatus?.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) ?: -1
            val scale = batteryStatus?.getIntExtra(BatteryManager.EXTRA_SCALE, -1) ?: -1
            if (level >= 0 && scale > 0) {
                (level * 100 / scale)
            } else {
                -1
            }
        } catch (e: Exception) {
            -1
        }
    }

    private fun isNetworkAvailable(): Boolean {
        return try {
            val cm = getSystemService(Context.CONNECTIVITY_SERVICE) as? ConnectivityManager ?: return false
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val network = cm.activeNetwork ?: return false
                val capabilities = cm.getNetworkCapabilities(network) ?: return false
                capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET) &&
                    capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_VALIDATED)
            } else {
                @Suppress("DEPRECATION")
                val networkInfo = cm.activeNetworkInfo ?: return false
                @Suppress("DEPRECATION")
                networkInfo.isConnected
            }
        } catch (e: Exception) {
            false
        }
    }

    private fun requestLocationUpdatesIfPermitted() {
        if (isListeningToLocation) return
        val lm = locationManager ?: return
        val hasFine = checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
        val hasCoarse = checkSelfPermission(Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED
        if (!hasFine && !hasCoarse) return

        try {
            if (lm.isProviderEnabled(LocationManager.GPS_PROVIDER)) {
                lm.requestLocationUpdates(LocationManager.GPS_PROVIDER, 5000L, 5f, this)
                isListeningToLocation = true
            }
            if (lm.isProviderEnabled(LocationManager.NETWORK_PROVIDER)) {
                lm.requestLocationUpdates(LocationManager.NETWORK_PROVIDER, 5000L, 5f, this)
                isListeningToLocation = true
            }
        } catch (_: Exception) {
        }
    }

    private fun getGpsStatus(): Map<String, Any?> {
        val lm = locationManager ?: return mapOf("hasGpsFix" to false, "latitude" to null, "longitude" to null, "accuracy" to null)
        val hasFine = checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
        val hasCoarse = checkSelfPermission(Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED

        if (!hasFine && !hasCoarse) {
            return mapOf("hasGpsFix" to false, "latitude" to null, "longitude" to null, "accuracy" to null)
        }

        requestLocationUpdatesIfPermitted()

        var bestLocation = lastGpsLocation
        try {
            val providers = listOf(
                LocationManager.GPS_PROVIDER,
                LocationManager.NETWORK_PROVIDER,
                LocationManager.PASSIVE_PROVIDER
            )
            for (provider in providers) {
                if (lm.isProviderEnabled(provider)) {
                    val loc = lm.getLastKnownLocation(provider)
                    if (loc != null && (bestLocation == null || loc.time > bestLocation.time)) {
                        bestLocation = loc
                    }
                }
            }
        } catch (_: Exception) {
        }

        if (bestLocation != null) {
            return mapOf(
                "hasGpsFix" to true,
                "latitude" to bestLocation.latitude,
                "longitude" to bestLocation.longitude,
                "accuracy" to bestLocation.accuracy.toDouble()
            )
        }

        return mapOf("hasGpsFix" to false, "latitude" to null, "longitude" to null, "accuracy" to null)
    }

    override fun onLocationChanged(location: Location) {
        lastGpsLocation = location
    }

    @Deprecated("Deprecated in Java")
    override fun onStatusChanged(provider: String?, status: Int, extras: Bundle?) {}

    override fun onProviderEnabled(provider: String) {}

    override fun onProviderDisabled(provider: String) {
        if (provider == LocationManager.GPS_PROVIDER && lastGpsLocation?.provider == LocationManager.GPS_PROVIDER) {
            lastGpsLocation = null
        }
    }
}
