package top.hylcreative.beacon_broadcaster

import android.bluetooth.BluetoothManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import androidx.core.content.ContextCompat
import androidx.core.content.ContextCompat.registerReceiver

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.EventChannel.EventSink
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

enum class BluetoothState(val nameString: String) {
    UNKNOWN("unknown"),
    UNSUPPORTED("unsupported"),
    UNAUTHORIZED("unauthorized"),
    READY("ready"),
    BEACONING("beaconing"),
    OFF("off")
}

enum class ChannelName(val nameString: String) {
    BLUETOOTH_STATE("beacon_broadcaster/bluetooth_state"), METHOD("beacon_broadcaster/method_channel")
}

/** BeaconBroadcasterPlugin */
class BeaconBroadcasterPlugin : FlutterPlugin, MethodCallHandler {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private lateinit var methodChannel: MethodChannel
    private lateinit var bluetoothStateChannel: EventChannel
    private lateinit var bluetoothManager: BluetoothManager
    private var bluetoothAdapter: android.bluetooth.BluetoothAdapter? = null
    private lateinit var applicationContext: Context
    private lateinit var bluetoothStateStreamHandler: BluetoothStateStreamHandler

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = flutterPluginBinding.applicationContext
        bluetoothManager =
            flutterPluginBinding.applicationContext.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
        bluetoothAdapter = bluetoothManager.adapter
        methodChannel =
            MethodChannel(flutterPluginBinding.binaryMessenger, ChannelName.METHOD.nameString)
        methodChannel.setMethodCallHandler(this)
        bluetoothStateChannel = EventChannel(
            flutterPluginBinding.binaryMessenger, ChannelName.BLUETOOTH_STATE.nameString
        )
        bluetoothStateStreamHandler = BluetoothStateStreamHandler()
        bluetoothStateChannel.setStreamHandler(bluetoothStateStreamHandler)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        if (call.method == "getPlatformVersion") {
            result.success("Android ${android.os.Build.VERSION.RELEASE}")
        } else {
            result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
    }

    private fun checkBluetoothState() {
        if (bluetoothAdapter == null) {
            bluetoothStateStreamHandler.eventSink?.success(BluetoothState.UNSUPPORTED.nameString)
        } else if (bluetoothAdapter?.isEnabled == false) {
            bluetoothStateStreamHandler.eventSink?.success(BluetoothState.OFF.nameString)
        } else {
            bluetoothStateStreamHandler.eventSink?.success(BluetoothState.READY.nameString)
        }
    }

    private fun checkBluetoothPermissions(): Boolean {
        // 当 SDK < 31 时需要检查 BLUETOOTH 和 BLUETOOTH_ADMIN 权限
        if (android.os.Build.VERSION.SDK_INT < android.os.Build.VERSION_CODES.S) {
            val bluetoothPermission = ContextCompat.checkSelfPermission(
                applicationContext, android.Manifest.permission.BLUETOOTH
            )
            val bluetoothAdminPermission = ContextCompat.checkSelfPermission(
                applicationContext, android.Manifest.permission.BLUETOOTH_ADMIN
            )
            if (!(bluetoothPermission == PackageManager.PERMISSION_GRANTED &&
                        bluetoothAdminPermission == PackageManager.PERMISSION_GRANTED)
            ) return false
        }
        // 检查 BLUETOOTH_ADVERTISE
        if (ContextCompat.checkSelfPermission(
                applicationContext, android.Manifest.permission.BLUETOOTH_ADVERTISE
            ) == PackageManager.PERMISSION_GRANTED
        ) {
            return true
        }
        return false
    }

    inner class BluetoothStateStreamHandler : EventChannel.StreamHandler {
        private lateinit var adapterStateChangedReceiver: BroadcastReceiver
        var eventSink: EventSink? = null

        override fun onListen(arguments: Any?, events: EventSink?) {
            val bluetoothLEAvailable =
                applicationContext.packageManager.hasSystemFeature(PackageManager.FEATURE_BLUETOOTH_LE)
            if (!bluetoothLEAvailable) {
                events?.success(BluetoothState.UNSUPPORTED.nameString)
                return
            }
            if (bluetoothAdapter?.isEnabled == false) {
                events?.success(BluetoothState.OFF.nameString)
                return
            }
            eventSink = events
            if (!checkBluetoothPermissions()) {
                events?.success(BluetoothState.UNAUTHORIZED.nameString)
                eventSink = null
                return
            }
            adapterStateChangedReceiver = object : BroadcastReceiver() {
                override fun onReceive(context: Context?, intent: Intent?) {
                    println("Bluetooth state changed")
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
            if (bluetoothAdapter?.isEnabled == true) events?.success(BluetoothState.READY.nameString)
        }

        override fun onCancel(arguments: Any?) {
            applicationContext.unregisterReceiver(adapterStateChangedReceiver)
            eventSink = null
        }

    }
}
