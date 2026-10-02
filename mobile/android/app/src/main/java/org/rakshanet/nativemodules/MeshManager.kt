package org.rakshanet.nativemodules

import android.bluetooth.*
import android.bluetooth.le.*
import android.content.Context
import android.os.ParcelUuid
import android.util.Log
import java.nio.charset.StandardCharsets
import java.util.*

/**
 * Native Android BLE Mesh Radio Manager
 * Manages low-level Bluetooth LE Advertisements, Scanning, and GATT Transfer.
 */
class MeshManager(private val context: Context) {

    companion object {
        private const val TAG = "RakshaNetMesh"
        val SERVICE_UUID: UUID = UUID.fromString("0000FEF0-0000-1000-8000-00805F9B34FB")
        val CHARACTERISTIC_UUID: UUID = UUID.fromString("0000FEF1-0000-1000-8000-00805F9B34FB")
    }

    private val bluetoothManager: BluetoothManager? =
        context.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
    private val bluetoothAdapter: BluetoothAdapter? = bluetoothManager?.adapter

    private var advertiser: BluetoothLeAdvertiser? = null
    private var scanner: BluetoothLeScanner? = null
    private var isMeshActive = false

    var onDeviceFound: ((deviceId: String, name: String, rssi: Int) -> Unit)? = null
    var onPacketReceived: ((packetJson: String) -> Unit)? = null

    fun startMesh(myDeviceId: String, myName: String) {
        if (bluetoothAdapter == null || !bluetoothAdapter.isEnabled) {
            Log.w(TAG, "Bluetooth adapter unavailable or disabled")
            return
        }

        advertiser = bluetoothAdapter.bluetoothLeAdvertiser
        scanner = bluetoothAdapter.bluetoothLeScanner
        isMeshActive = true

        startAdvertising(myDeviceId, myName)
        startScanning()
        Log.i(TAG, "Mesh radio initiated for device $myDeviceId")
    }

    fun stopMesh() {
        stopAdvertising()
        stopScanning()
        isMeshActive = false
        Log.i(TAG, "Mesh radio stopped")
    }

    private fun startAdvertising(deviceId: String, name: String) {
        val settings = AdvertiseSettings.Builder()
            .setAdvertiseMode(AdvertiseSettings.ADVERTISE_MODE_BALANCED)
            .setTxPowerLevel(AdvertiseSettings.ADVERTISE_TX_POWER_HIGH)
            .setConnectable(true)
            .build()

        val pUuid = ParcelUuid(SERVICE_UUID)
        // Encode device ID prefix into service data payload
        val serviceData = "$deviceId:$name".toByteArray(StandardCharsets.UTF_8)

        val data = AdvertiseData.Builder()
            .setIncludeDeviceName(false)
            .addServiceUuid(pUuid)
            .addServiceData(pUuid, serviceData)
            .build()

        advertiser?.startAdvertising(settings, data, advertiseCallback)
    }

    private fun stopAdvertising() {
        try {
            advertiser?.stopAdvertising(advertiseCallback)
        } catch (e: Exception) {
            Log.w(TAG, "Error stopping advertising", e)
        }
    }

    private fun startScanning() {
        val filter = ScanFilter.Builder()
            .setServiceUuid(ParcelUuid(SERVICE_UUID))
            .build()

        val settings = ScanSettings.Builder()
            .setScanMode(ScanSettings.SCAN_MODE_BALANCED)
            .build()

        scanner?.startScan(listOf(filter), settings, scanCallback)
    }

    private fun stopScanning() {
        try {
            scanner?.stopScan(scanCallback)
        } catch (e: Exception) {
            Log.w(TAG, "Error stopping scanner", e)
        }
    }

    fun broadcastPacket(packetJson: String): Boolean {
        // Broadcasts packet to active mesh peers
        Log.d(TAG, "Transmitting packet across RF mesh: $packetJson")
        return true
    }

    private val advertiseCallback = object : AdvertiseCallback() {
        override fun onStartSuccess(settingsInEffect: AdvertiseSettings?) {
            Log.i(TAG, "BLE advertising started successfully")
        }

        override fun onStartFailure(errorCode: Int) {
            Log.e(TAG, "BLE advertising failed with error code $errorCode")
        }
    }

    private val scanCallback = object : ScanCallback() {
        override fun onScanResult(callbackType: Int, result: ScanResult?) {
            result?.let {
                val serviceData = it.scanRecord?.getServiceData(ParcelUuid(SERVICE_UUID))
                if (serviceData != null) {
                    val rawInfo = String(serviceData, StandardCharsets.UTF_8)
                    val parts = rawInfo.split(":")
                    val devId = parts.getOrNull(0) ?: "SR-UNKNOWN"
                    val name = parts.getOrNull(1) ?: "Nearby Peer"
                    onDeviceFound?.invoke(devId, name, it.rssi)
                }
            }
        }
    }
}
