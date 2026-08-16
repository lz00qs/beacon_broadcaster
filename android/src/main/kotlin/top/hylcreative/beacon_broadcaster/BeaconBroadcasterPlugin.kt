package top.hylcreative.beacon_broadcaster

import android.Manifest
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.bluetooth.le.AdvertiseCallback
import android.bluetooth.le.AdvertiseData
import android.bluetooth.le.AdvertiseSettings
import android.bluetooth.le.BluetoothLeAdvertiser
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import androidx.core.content.ContextCompat
import androidx.core.content.ContextCompat.registerReceiver
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.EventChannel.EventSink
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.nio.ByteBuffer
import java.nio.ByteOrder

enum class BluetoothState(val nameString: String) {
    UNKNOWN("unknown"),
    UNSUPPORTED("unsupported"),
    UNAUTHORIZED("unauthorized"),
    READY("ready"),
    BEACONING("beaconing"),
    OFF("off"),
    ERROR("error")
}

enum class ChannelName(val nameString: String) {
    BLUETOOTH_STATE("beacon_broadcaster/bluetooth_state"),
    METHOD("beacon_broadcaster/method_channel"),
    LOG("beacon_broadcaster/log")
}

enum class LogLevel(val nameString: String) {
    DEBUG("debug"),
    INFO("info"),
    WARNING("warning"),
    ERROR("error")
}

class BeaconBroadcasterPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var methodChannel: MethodChannel
    private lateinit var bluetoothStateChannel: EventChannel
    private var bluetoothStateEventSink: EventSink? = null
    private lateinit var logChannel: EventChannel
    private var logEventSink: EventSink? = null
    private lateinit var bluetoothManager: BluetoothManager
    private var bluetoothAdapter: BluetoothAdapter? = null
    private lateinit var applicationContext: Context
    private val mainHandler = Handler(Looper.getMainLooper())
    private val advertisingSession = AdvertisingSessionTracker<BeaconAdvertiseCallback>()
    private var autoStopRunnable: Runnable? = null
    private var adapterStateChangedReceiver: BroadcastReceiver? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = binding.applicationContext
        bluetoothManager =
            binding.applicationContext.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
        bluetoothAdapter = bluetoothManager.adapter

        logChannel = EventChannel(binding.binaryMessenger, ChannelName.LOG.nameString)
        logChannel.setStreamHandler(LogStreamHandler())

        methodChannel = MethodChannel(binding.binaryMessenger, ChannelName.METHOD.nameString)
        methodChannel.setMethodCallHandler(this)

        bluetoothStateChannel =
            EventChannel(binding.binaryMessenger, ChannelName.BLUETOOTH_STATE.nameString)
        bluetoothStateChannel.setStreamHandler(BluetoothStateStreamHandler())
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getPlatformVersion" -> result.success("Android ${Build.VERSION.RELEASE}")
            "checkBluetoothState" -> {
                checkBluetoothState()
                result.success(null)
            }

            "startAdvertising" -> {
                try {
                    val args = call.arguments as Map<*, *>
                    val uuid = args["uuid"] as ByteArray
                    val major = args["major"] as Int
                    val minor = args["minor"] as Int
                    val txPower = args["txPower"] as Int
                    val durationMs = args["durationMs"] as Int?
                    val advertiseMode = args["advertiseMode"] as Int
                    val advertiseTxPower = args["advertiseTxPower"] as Int
                    result.success(
                        startAdvertising(
                            uuid = uuid,
                            major = major,
                            minor = minor,
                            txPower = txPower,
                            durationMs = durationMs,
                            advertiseMode = advertiseMode,
                            advertiseTxPower = advertiseTxPower
                        )
                    )
                } catch (e: Exception) {
                    logE("Failed to start advertising: ${e.message}")
                    result.error("invalid_args", e.message, null)
                }
            }

            "stopAdvertising" -> result.success(stopAdvertising())
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        clearAutoStop()
        if (hasAdvertisePermission()) {
            stopActiveAdvertising()
        } else {
            advertisingSession.clear()
        }
        unregisterAdapterStateChangedReceiver()
        methodChannel.setMethodCallHandler(null)
        bluetoothStateChannel.setStreamHandler(null)
        logChannel.setStreamHandler(null)
        bluetoothStateEventSink = null
        logEventSink = null
    }

    private fun checkBluetoothState() {
        if (!applicationContext.packageManager.hasSystemFeature(PackageManager.FEATURE_BLUETOOTH_LE)) {
            bluetoothStateEventSink?.success(BluetoothState.UNSUPPORTED.nameString)
            return
        }
        if (!hasAdvertisePermission()) {
            bluetoothStateEventSink?.success(BluetoothState.UNAUTHORIZED.nameString)
            return
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && !hasConnectPermission()) {
            val state =
                if (advertisingSession.hasStarted) BluetoothState.BEACONING else BluetoothState.READY
            bluetoothStateEventSink?.success(state.nameString)
            return
        }
        when (bluetoothAdapter?.isEnabled) {
            true -> {
                val state =
                    if (advertisingSession.hasStarted) BluetoothState.BEACONING else BluetoothState.READY
                bluetoothStateEventSink?.success(state.nameString)
            }
            false -> bluetoothStateEventSink?.success(BluetoothState.OFF.nameString)
            null -> bluetoothStateEventSink?.success(BluetoothState.UNKNOWN.nameString)
        }
    }

    private fun startAdvertising(
        uuid: ByteArray,
        major: Int,
        minor: Int,
        txPower: Int,
        durationMs: Int?,
        advertiseMode: Int,
        advertiseTxPower: Int,
    ): Int {
        if (!applicationContext.packageManager.hasSystemFeature(PackageManager.FEATURE_BLUETOOTH_LE)) {
            bluetoothStateEventSink?.success(BluetoothState.UNSUPPORTED.nameString)
            logE("BLE advertising is not supported on this device.")
            return -1
        }
        if (!hasAdvertisePermission()) {
            bluetoothStateEventSink?.success(BluetoothState.UNAUTHORIZED.nameString)
            logE("Missing BLUETOOTH_ADVERTISE permission.")
            return -1
        }
        if (hasConnectPermission() && bluetoothAdapter?.isEnabled != true) {
            bluetoothStateEventSink?.success(BluetoothState.OFF.nameString)
            logW("Bluetooth adapter is off.")
            return -1
        }

        val advertiser = bluetoothAdapter?.bluetoothLeAdvertiser
        if (advertiser == null) {
            val state =
                if (hasConnectPermission()) BluetoothState.UNSUPPORTED else BluetoothState.UNKNOWN
            bluetoothStateEventSink?.success(state.nameString)
            logE("Bluetooth LE advertiser is unavailable.")
            return -1
        }

        var payload = byteArrayOf(0x02.toByte(), 0x15.toByte())
        payload += uuid
        payload += ByteBuffer.allocate(2).order(ByteOrder.BIG_ENDIAN).putShort(major.toShort()).array()
        payload += ByteBuffer.allocate(2).order(ByteOrder.BIG_ENDIAN).putShort(minor.toShort()).array()
        payload += txPower.toByte()

        logD("payload: ${payload.joinToString("") { it.toUByte().toString(16).padStart(2, '0') }}")

        val settingsBuilder = AdvertiseSettings.Builder()
            .setConnectable(true)
            .setAdvertiseMode(advertiseMode)
            .setTxPowerLevel(advertiseTxPower)
            .setTimeout(0)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            settingsBuilder.setDiscoverable(true)
        }
        val settings = settingsBuilder.build()

        val data = AdvertiseData.Builder()
            .setIncludeDeviceName(false)
            .setIncludeTxPowerLevel(false)
            .addManufacturerData(0x004c, payload)
            .build()

        clearAutoStop()
        stopActiveAdvertising(advertiser)

        val advertiseCallback = BeaconAdvertiseCallback()
        advertisingSession.begin(advertiseCallback)
        try {
            advertiser.startAdvertising(settings, data, advertiseCallback)
        } catch (exception: Exception) {
            advertisingSession.finish(advertiseCallback)
            throw exception
        }
        scheduleAutoStop(durationMs, advertiseCallback)
        return 0
    }

    private fun stopAdvertising(): Int {
        if (!hasAdvertisePermission()) {
            bluetoothStateEventSink?.success(BluetoothState.UNAUTHORIZED.nameString)
            logE("Missing BLUETOOTH_ADVERTISE permission.")
            return -1
        }
        clearAutoStop()
        stopActiveAdvertising()
        checkBluetoothState()
        return 0
    }

    private fun stopActiveAdvertising(
        advertiser: BluetoothLeAdvertiser? = bluetoothAdapter?.bluetoothLeAdvertiser,
    ): Boolean {
        val callback = advertisingSession.clear() ?: return false
        advertiser?.stopAdvertising(callback)
        return true
    }

    private fun scheduleAutoStop(durationMs: Int?, advertiseCallback: BeaconAdvertiseCallback) {
        clearAutoStop()
        if (durationMs == null) {
            return
        }

        autoStopRunnable =
            Runnable {
                if (advertisingSession.activeCallback === advertiseCallback) {
                    stopAdvertising()
                }
            }
        mainHandler.postDelayed(autoStopRunnable!!, durationMs.toLong())
    }

    private fun clearAutoStop() {
        autoStopRunnable?.let { mainHandler.removeCallbacks(it) }
        autoStopRunnable = null
    }

    private fun checkBluetoothPermissions(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) {
            val bluetoothPermission = ContextCompat.checkSelfPermission(
                applicationContext,
                Manifest.permission.BLUETOOTH
            )
            val bluetoothAdminPermission = ContextCompat.checkSelfPermission(
                applicationContext,
                Manifest.permission.BLUETOOTH_ADMIN
            )
            return bluetoothPermission == PackageManager.PERMISSION_GRANTED &&
                bluetoothAdminPermission == PackageManager.PERMISSION_GRANTED
        }
        return hasAdvertisePermission()
    }

    private fun hasConnectPermission(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) {
            return true
        }
        return ContextCompat.checkSelfPermission(
            applicationContext,
            Manifest.permission.BLUETOOTH_CONNECT
        ) == PackageManager.PERMISSION_GRANTED
    }

    private fun hasAdvertisePermission(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) {
            return true
        }
        return ContextCompat.checkSelfPermission(
            applicationContext,
            Manifest.permission.BLUETOOTH_ADVERTISE
        ) == PackageManager.PERMISSION_GRANTED
    }

    inner class BeaconAdvertiseCallback : AdvertiseCallback() {
        override fun onStartSuccess(settingsInEffect: AdvertiseSettings) {
            super.onStartSuccess(settingsInEffect)
            if (!advertisingSession.markStarted(this)) {
                logD("Ignoring a stale advertising success callback.")
                return
            }
            logD("onStartSuccess: $settingsInEffect")
            bluetoothStateEventSink?.success(BluetoothState.BEACONING.nameString)
        }

        override fun onStartFailure(errorCode: Int) {
            super.onStartFailure(errorCode)
            if (!advertisingSession.finish(this)) {
                logD("Ignoring a stale advertising failure callback: $errorCode")
                return
            }
            clearAutoStop()
            logE("onStartFailure: $errorCode")
            bluetoothStateEventSink?.success(BluetoothState.ERROR.nameString)
        }
    }

    inner class BluetoothStateStreamHandler : EventChannel.StreamHandler {
        override fun onListen(arguments: Any?, events: EventSink?) {
            unregisterAdapterStateChangedReceiver()
            bluetoothStateEventSink = events
            checkBluetoothState()
            val receiver = object : BroadcastReceiver() {
                override fun onReceive(context: Context?, intent: Intent?) {
                    if (intent?.action != BluetoothAdapter.ACTION_STATE_CHANGED) {
                        return
                    }
                    val state = intent.getIntExtra(BluetoothAdapter.EXTRA_STATE, -1)
                    when (state) {
                        BluetoothAdapter.STATE_ON -> {
                            if (checkBluetoothPermissions()) {
                                events?.success(BluetoothState.READY.nameString)
                            } else {
                                events?.success(BluetoothState.UNAUTHORIZED.nameString)
                            }
                        }

                        BluetoothAdapter.STATE_TURNING_OFF -> {
                            advertisingSession.clear()
                            clearAutoStop()
                        }

                        BluetoothAdapter.STATE_OFF -> {
                            advertisingSession.clear()
                            clearAutoStop()
                            events?.success(BluetoothState.OFF.nameString)
                        }
                    }
                }
            }
            registerReceiver(
                applicationContext,
                receiver,
                IntentFilter(BluetoothAdapter.ACTION_STATE_CHANGED),
                ContextCompat.RECEIVER_NOT_EXPORTED
            )
            adapterStateChangedReceiver = receiver
        }

        override fun onCancel(arguments: Any?) {
            unregisterAdapterStateChangedReceiver()
            bluetoothStateEventSink = null
        }
    }

    private fun unregisterAdapterStateChangedReceiver() {
        adapterStateChangedReceiver?.let { applicationContext.unregisterReceiver(it) }
        adapterStateChangedReceiver = null
    }

    inner class LogStreamHandler : EventChannel.StreamHandler {
        override fun onListen(arguments: Any?, events: EventSink?) {
            logEventSink = events
        }

        override fun onCancel(arguments: Any?) {
            logEventSink = null
        }
    }

    private fun log(level: LogLevel, message: String) {
        logEventSink?.success(mapOf("logLevel" to level.nameString, "message" to message))
    }

    private fun logD(message: String) {
        log(LogLevel.DEBUG, message)
    }

    private fun logW(message: String) {
        log(LogLevel.WARNING, message)
    }

    private fun logE(message: String) {
        log(LogLevel.ERROR, message)
    }
}
