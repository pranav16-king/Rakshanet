package org.rakshanet.nativemodules

import com.facebook.react.bridge.*
import com.facebook.react.modules.core.DeviceEventManagerModule

/**
 * React Native NativeModule Bridge for Android BLE Mesh
 */
class BluetoothModule(private val reactContext: ReactApplicationContext) :
    ReactContextBaseJavaModule(reactContext) {

    private val meshManager = MeshManager(reactContext)

    init {
        meshManager.onDeviceFound = { deviceId, name, rssi ->
            val map = Arguments.createMap().apply {
                putString("id", "dev_$deviceId")
                putString("deviceId", deviceId)
                putString("displayName", name)
                putString("connectionType", "BLE")
                putInt("signalStrength", rssi)
                putString("proximityBand", if (rssi > -65) "IMMEDIATE" else if (rssi > -80) "NEAR" else "FAR")
                putDouble("lastSeen", System.currentTimeMillis().toDouble())
                putDouble("firstSeen", System.currentTimeMillis().toDouble())
                putBoolean("isConnected", true)
                putInt("hopCount", 1)
            }
            sendEvent("onDeviceDiscovered", map)
        }

        meshManager.onPacketReceived = { packetJson ->
            val map = Arguments.createMap().apply {
                putString("raw", packetJson)
            }
            sendEvent("onPacketReceived", map)
        }
    }

    override fun getName(): String = "RakshaNetBluetooth"

    @ReactMethod
    fun startMesh(deviceId: String, displayName: String, promise: Promise) {
        try {
            meshManager.startMesh(deviceId, displayName)
            promise.resolve(true)
        } catch (e: Exception) {
            promise.reject("MESH_START_ERR", e.message, e)
        }
    }

    @ReactMethod
    fun stopMesh(promise: Promise) {
        try {
            meshManager.stopMesh()
            promise.resolve(true)
        } catch (e: Exception) {
            promise.reject("MESH_STOP_ERR", e.message, e)
        }
    }

    @ReactMethod
    fun broadcastPacket(packetJson: String, promise: Promise) {
        try {
            val result = meshManager.broadcastPacket(packetJson)
            promise.resolve(result)
        } catch (e: Exception) {
            promise.reject("PACKET_SEND_ERR", e.message, e)
        }
    }

    private fun sendEvent(eventName: String, params: WritableMap) {
        if (reactContext.hasActiveReactInstance()) {
            reactContext
                .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter::class.java)
                .emit(eventName, params)
        }
    }
}
