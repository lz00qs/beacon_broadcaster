import Flutter
import UIKit

private enum ChannelName {
  static let method = "beacon_broadcaster/method_channel"
  static let bluetoothState = "beacon_broadcaster/bluetooth_state"
  static let log = "beacon_broadcaster/log"
}

private enum BluetoothState: String {
  case unknown
  case unsupported
  case unauthorized
  case ready
  case beaconing
  case off
  case error
}

private final class BluetoothStateStreamHandler: NSObject, FlutterStreamHandler {
  var eventSink: FlutterEventSink?

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    eventSink = events
    #if targetEnvironment(simulator)
    events(BluetoothState.ready.rawValue)
    #else
    events(BluetoothState.unsupported.rawValue)
    #endif
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }
}

private final class LogStreamHandler: NSObject, FlutterStreamHandler {
  var eventSink: FlutterEventSink?

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    eventSink = events
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }
}

public class BeaconBroadcasterPlugin: NSObject, FlutterPlugin {
  private let bluetoothStateHandler = BluetoothStateStreamHandler()
  private let logHandler = LogStreamHandler()

  public static func register(with registrar: FlutterPluginRegistrar) {
    let methodChannel = FlutterMethodChannel(
      name: ChannelName.method,
      binaryMessenger: registrar.messenger()
    )
    let bluetoothStateChannel = FlutterEventChannel(
      name: ChannelName.bluetoothState,
      binaryMessenger: registrar.messenger()
    )
    let logChannel = FlutterEventChannel(
      name: ChannelName.log,
      binaryMessenger: registrar.messenger()
    )

    let instance = BeaconBroadcasterPlugin()
    registrar.addMethodCallDelegate(instance, channel: methodChannel)
    bluetoothStateChannel.setStreamHandler(instance.bluetoothStateHandler)
    logChannel.setStreamHandler(instance.logHandler)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    case "checkBluetoothState":
      #if targetEnvironment(simulator)
      bluetoothStateHandler.eventSink?(BluetoothState.ready.rawValue)
      #else
      bluetoothStateHandler.eventSink?(BluetoothState.unsupported.rawValue)
      #endif
      result(nil)
    case "startAdvertising":
      #if targetEnvironment(simulator)
      result(0)
      #else
      result(FlutterError(code: "unimplemented", message: "iOS implementation not available.", details: nil))
      #endif
    case "stopAdvertising":
      #if targetEnvironment(simulator)
      result(0)
      #else
      result(FlutterError(code: "unimplemented", message: "iOS implementation not available.", details: nil))
      #endif
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
