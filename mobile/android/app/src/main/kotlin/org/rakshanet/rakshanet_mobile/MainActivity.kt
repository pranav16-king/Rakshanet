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
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

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
                else -> {
                    result.notImplemented()
                }
            }
        }
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
            } else if (lm.isProviderEnabled(LocationManager.NETWORK_PROVIDER)) {
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
            val lastGps = if (lm.isProviderEnabled(LocationManager.GPS_PROVIDER)) lm.getLastKnownLocation(LocationManager.GPS_PROVIDER) else null
            val lastNet = if (lm.isProviderEnabled(LocationManager.NETWORK_PROVIDER)) lm.getLastKnownLocation(LocationManager.NETWORK_PROVIDER) else null

            if (lastGps != null && (bestLocation == null || lastGps.time > bestLocation.time)) {
                bestLocation = lastGps
            }
            if (lastNet != null && (bestLocation == null || lastNet.time > bestLocation.time)) {
                bestLocation = lastNet
            }
        } catch (_: Exception) {
        }

        if (bestLocation != null) {
            // Fresh GPS fix within last 3 minutes
            val isFresh = (System.currentTimeMillis() - bestLocation.time) < 180000L
            if (isFresh) {
                return mapOf(
                    "hasGpsFix" to true,
                    "latitude" to bestLocation.latitude,
                    "longitude" to bestLocation.longitude,
                    "accuracy" to bestLocation.accuracy.toDouble()
                )
            }
        }

        // Never fake coordinates! Accurately report hasGpsFix = false
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
