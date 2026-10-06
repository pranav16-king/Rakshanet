package org.rakshanet.rakshanet_mobile

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.os.BatteryManager
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.security.MessageDigest

class MainActivity : FlutterActivity(), LocationListener {
    private val channelName = "org.rakshanet/telemetry"
    private var locationManager: LocationManager? = null
    private var lastGpsLocation: Location? = null
    private var isListeningToLocation = false

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
