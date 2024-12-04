package top.hylcreative.beacon_broadcaster

import android.Manifest
import android.bluetooth.BluetoothManager
import android.bluetooth.le.AdvertiseCallback
import android.bluetooth.le.AdvertiseData
import android.bluetooth.le.AdvertiseSettings
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.os.Build
import androidx.annotation.RequiresApi
import androidx.core.app.ActivityCompat
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

/** BeaconBroadcasterPlugin */
class BeaconBroadcasterPlugin : FlutterPlugin, MethodCallHandler {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private lateinit var methodChannel: MethodChannel
    private lateinit var bluetoothStateChannel: EventChannel
    private var bluetoothStateEventSink: EventSink? = null
    private lateinit var logChannel: EventChannel
    private var logEventSink: EventSink? = null
    private lateinit var bluetoothManager: BluetoothManager
    private var bluetoothAdapter: android.bluetooth.BluetoothAdapter? = null
    private lateinit var applicationContext: Context
    private val beaconAdvertiseCallback = BeaconAdvertiseCallback()

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = flutterPluginBinding.applicationContext
        bluetoothManager =
            flutterPluginBinding.applicationContext.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
        bluetoothAdapter = bluetoothManager.adapter
        logChannel = EventChannel(
            flutterPluginBinding.binaryMessenger, ChannelName.LOG.nameString
        )
        logChannel.setStreamHandler(LogStreamHandler())
        methodChannel =
            MethodChannel(flutterPluginBinding.binaryMessenger, ChannelName.METHOD.nameString)
        methodChannel.setMethodCallHandler(this)
        bluetoothStateChannel = EventChannel(
            flutterPluginBinding.binaryMessenger, ChannelName.BLUETOOTH_STATE.nameString
        )

        bluetoothStateChannel.setStreamHandler(BluetoothStateStreamHandler())
    }

    @RequiresApi(Build.VERSION_CODES.UPSIDE_DOWN_CAKE)
    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getPlatformVersion" -> result.success("Android ${Build.VERSION.RELEASE}")
            "checkBluetoothState" -> {
                checkBluetoothState()
                result.success("")
            }

            "startAdvertising" -> {
                try {
                    val args = call.arguments as Map<*, *>
                    val uuid = args["uuid"] as ByteArray
                    val major = args["major"] as Int
                    val minor = args["minor"] as Int
                    val txPower = args["txPower"] as Int
                    val advertiseMode = args["advertiseMode"] as Int
                    val advertiseTxPower = args["advertiseTxPower"] as Int
                    logD("uuid: ${uuid.toList()}, major: $major, minor: $minor, txPower: $txPower, advertiseMode: $advertiseMode, advertiseTxPower: $advertiseTxPower")
                    result.success(
                        startAdvertising(
                            uuid,
                            major,
                            minor,
                            txPower,
                            advertiseMode,
                            advertiseTxPower
                        )
                    )
                } catch (e: Exception) {
                    result.error("-1", e.message, e)
                }
            }

            "stopAdvertising" -> {
                result.success(stopAdvertising())
            }

            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
    }

    private fun checkBluetoothState() {
        if (!applicationContext.packageManager.hasSystemFeature(PackageManager.FEATURE_BLUETOOTH_LE)) {
            bluetoothStateEventSink?.success(BluetoothState.UNSUPPORTED.nameString)
            return
        }
        if (!checkBluetoothPermissions()) {
            bluetoothStateEventSink?.success(BluetoothState.UNAUTHORIZED.nameString)
            return
        }
        if (bluetoothAdapter?.isEnabled == false) {
            bluetoothStateEventSink?.success(BluetoothState.OFF.nameString)
            return
        }
        if (bluetoothAdapter?.isEnabled == true) bluetoothStateEventSink?.success(
            BluetoothState.READY.nameString
        )
    }

    @RequiresApi(Build.VERSION_CODES.UPSIDE_DOWN_CAKE)
    private fun startAdvertising(
        uuid: ByteArray,
        major: Int,
        minor: Int,
        txPower: Int,
        advertiseMode: Int,
        advertiseTxPower: Int,
    ): Int {
        var payload = byteArrayOf(
            0x02.toByte(),
            0x15.toByte(), // iBeacon 标识符
//            0x39.toByte(),
//            0xED.toByte(),
//            0x98.toByte(),
//            0xFF.toByte(),
//            0x29.toByte(),
//            0x00.toByte(),
//            0x44.toByte(),
//            0x1A.toByte(),
//            0x80.toByte(),
//            0x2F.toByte(),
//            0x9C.toByte(),
//            0x39.toByte(),
//            0x8F.toByte(),
//            0xC1.toByte(),
//            0x99.toByte(),
//            0xD2.toByte(),
//            0x00.toByte(),
//            0x01.toByte(), // Major
//            0x00.toByte(),
//            0x02.toByte(), // Minor
//            0xC5.toByte()
        ) // Minor

        payload += uuid
        payload += ByteBuffer.allocate(2).order(ByteOrder.BIG_ENDIAN).putShort(major.toShort())
            .array()
        payload += ByteBuffer.allocate(2).order(ByteOrder.BIG_ENDIAN).putShort(minor.toShort())
            .array()
        payload += txPower.toByte()

        // 用十六进制打印 payload
        logD("payload: ${payload.joinToString("") { it.toUByte().toString(16).padStart(2, '0') }}")


        val settings: AdvertiseSettings = AdvertiseSettings.Builder()
            .setConnectable(true)
            .setDiscoverable(true)
            .setAdvertiseMode(advertiseMode)
            .setTxPowerLevel(advertiseTxPower)
            .setTimeout(0)
            .build()

        val data = AdvertiseData.Builder()
            .setIncludeDeviceName(false)
            .setIncludeTxPowerLevel(false)
            .addManufacturerData(0x004c, payload)
            .build()

        if (ActivityCompat.checkSelfPermission(
                applicationContext,
                Manifest.permission.BLUETOOTH_ADVERTISE
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            return -1
        }
        bluetoothAdapter?.bluetoothLeAdvertiser?.startAdvertising(
            settings,
            data,
            beaconAdvertiseCallback
        )
        return 0
    }

    private fun stopAdvertising(): Int {
        if (ActivityCompat.checkSelfPermission(
                applicationContext,
                Manifest.permission.BLUETOOTH_ADVERTISE
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            // TODO: Consider calling
            //    ActivityCompat#requestPermissions
            // here to request the missing permissions, and then overriding
            //   public void onRequestPermissionsResult(int requestCode, String[] permissions,
            //                                          int[] grantResults)
            // to handle the case where the user grants the permission. See the documentation
            // for ActivityCompat#requestPermissions for more details.
            return -1
        }
        bluetoothAdapter?.bluetoothLeAdvertiser?.stopAdvertising(beaconAdvertiseCallback)
        bluetoothStateEventSink?.success(BluetoothState.READY.nameString)
        return 0
    }

    inner class BeaconAdvertiseCallback :
        AdvertiseCallback() {
        override fun onStartSuccess(settingsInEffect: AdvertiseSettings) {
            super.onStartSuccess(settingsInEffect)
            logD("onAdvertisingSetStarted: $settingsInEffect")
            bluetoothStateEventSink?.success(BluetoothState.BEACONING.nameString)
        }

        override fun onStartFailure(errorCode: Int) {
            super.onStartFailure(errorCode)
            logD("onStartFailure: $errorCode")
            bluetoothStateEventSink?.success(BluetoothState.ERROR.nameString)
        }
    }

    private fun checkBluetoothPermissions(): Boolean {
        // 当 SDK < 31 时需要检查 BLUETOOTH 和 BLUETOOTH_ADMIN 权限
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) {
            val bluetoothPermission = ContextCompat.checkSelfPermission(
                applicationContext, Manifest.permission.BLUETOOTH
            )
            val bluetoothAdminPermission = ContextCompat.checkSelfPermission(
                applicationContext, Manifest.permission.BLUETOOTH_ADMIN
            )
            if (!(bluetoothPermission == PackageManager.PERMISSION_GRANTED &&
                        bluetoothAdminPermission == PackageManager.PERMISSION_GRANTED)
            ) return false
        }
        // 检查 BLUETOOTH_ADVERTISE
        if (ContextCompat.checkSelfPermission(
                applicationContext, Manifest.permission.BLUETOOTH_ADVERTISE
            ) == PackageManager.PERMISSION_GRANTED
        ) {
            return true
        }
        return false
    }

    inner class BluetoothStateStreamHandler : EventChannel.StreamHandler {
        private lateinit var adapterStateChangedReceiver: BroadcastReceiver

        override fun onListen(arguments: Any?, events: EventSink?) {
            bluetoothStateEventSink = events
            checkBluetoothState()
            adapterStateChangedReceiver = object : BroadcastReceiver() {
                override fun onReceive(context: Context?, intent: Intent?) {
                    if (intent?.action == "android.bluetooth.adapter.action.STATE_CHANGED") {
                        val state = intent.getIntExtra("android.bluetooth.adapter.extra.STATE", -1)
                        if (state == android.bluetooth.BluetoothAdapter.STATE_ON) {
                            if (checkBluetoothPermissions()) {
                                events?.success(BluetoothState.READY.nameString)
                            } else {
                                events?.success(BluetoothState.UNAUTHORIZED.nameString)
                            }
                        } else if (state == android.bluetooth.BluetoothAdapter.STATE_OFF) {
                            events?.success(BluetoothState.OFF.nameString)
                        }
                    }
                }
            }
            val filter = IntentFilter("android.bluetooth.adapter.action.STATE_CHANGED")
            registerReceiver(
                applicationContext,
                adapterStateChangedReceiver,
                filter,
                ContextCompat.RECEIVER_NOT_EXPORTED
            )
        }

        override fun onCancel(arguments: Any?) {
            applicationContext.unregisterReceiver(adapterStateChangedReceiver)
            bluetoothStateEventSink = null
        }

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

    private fun logI(message: String) {
        log(LogLevel.INFO, message)
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
