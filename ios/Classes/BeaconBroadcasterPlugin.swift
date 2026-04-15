import CoreBluetooth
import CoreLocation
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
  var onListen: (() -> Void)?

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    eventSink = events
    onListen?()
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

public class BeaconBroadcasterPlugin: NSObject, FlutterPlugin, CLLocationManagerDelegate, CBPeripheralManagerDelegate {
  private let bluetoothStateHandler = BluetoothStateStreamHandler()
  private let logHandler = LogStreamHandler()
  private let locationManager = CLLocationManager()
  private let peripheralManager = CBPeripheralManager(delegate: nil, queue: nil)
  private var isAdvertising = false
  private var lastBeaconRegion: CLBeaconRegion?
  private var autoStopWorkItem: DispatchWorkItem?

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
      updateBluetoothState()
      #endif
      result(nil)
    case "startAdvertising":
      #if targetEnvironment(simulator)
      result(0)
      #else
      startAdvertising(call: call, result: result)
      #endif
    case "stopAdvertising":
      #if targetEnvironment(simulator)
      result(0)
      #else
      stopAdvertising(result: result)
      #endif
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  public override init() {
    super.init()
    locationManager.delegate = self
    peripheralManager.delegate = self
    bluetoothStateHandler.onListen = { [weak self] in
      self?.updateBluetoothState()
    }
  }

  private func updateBluetoothState() {
    #if targetEnvironment(simulator)
    bluetoothStateHandler.eventSink?(BluetoothState.ready.rawValue)
    return
    #else
    if !CLLocationManager.isMonitoringAvailable(for: CLBeaconRegion.self) {
      bluetoothStateHandler.eventSink?(BluetoothState.unsupported.rawValue)
      return
    }
    switch peripheralManager.state {
    case .poweredOn:
      bluetoothStateHandler.eventSink?(isAdvertising ? BluetoothState.beaconing.rawValue : BluetoothState.ready.rawValue)
    case .poweredOff:
      bluetoothStateHandler.eventSink?(BluetoothState.off.rawValue)
    case .unauthorized:
      bluetoothStateHandler.eventSink?(BluetoothState.unauthorized.rawValue)
    case .unsupported:
      bluetoothStateHandler.eventSink?(BluetoothState.unsupported.rawValue)
    default:
      bluetoothStateHandler.eventSink?(BluetoothState.unknown.rawValue)
    }
    #endif
  }

  private func startAdvertising(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard CLLocationManager.isMonitoringAvailable(for: CLBeaconRegion.self),
          CLLocationManager.isRangingAvailable() else {
      bluetoothStateHandler.eventSink?(BluetoothState.unsupported.rawValue)
      result(FlutterError(code: "unsupported", message: "iBeacon not supported on this device.", details: nil))
      return
    }

    guard let args = call.arguments as? [String: Any] else {
      result(FlutterError(code: "invalid_args", message: "Missing parameters.", details: nil))
      return
    }

    guard let uuidBytes = args["uuid"] as? FlutterStandardTypedData,
          let major = args["major"] as? Int,
          let minor = args["minor"] as? Int,
          let txPower = args["txPower"] as? Int else {
      result(FlutterError(code: "invalid_args", message: "Invalid parameters.", details: nil))
      return
    }

    let durationMs = args["durationMs"] as? Int

    let uuidData = uuidBytes.data
    guard uuidData.count == 16 else {
      result(FlutterError(code: "invalid_args", message: "UUID must be 16 bytes.", details: nil))
      return
    }

    let uuid = UUID(uuid: (
      uuidData[0], uuidData[1], uuidData[2], uuidData[3],
      uuidData[4], uuidData[5], uuidData[6], uuidData[7],
      uuidData[8], uuidData[9], uuidData[10], uuidData[11],
      uuidData[12], uuidData[13], uuidData[14], uuidData[15]
    ))

    let clUUID = UUID(uuid: uuid.uuid)
    let identifier = "beacon_broadcaster"
    let region = CLBeaconRegion(uuid: clUUID, major: CLBeaconMajorValue(major), minor: CLBeaconMinorValue(minor), identifier: identifier)
    let payload = region.peripheralData(withMeasuredPower: NSNumber(value: txPower)) as? [String: Any]

    guard let peripheralData = payload else {
      result(FlutterError(code: "payload_error", message: "Failed to build iBeacon payload.", details: nil))
      return
    }

    if peripheralManager.state != .poweredOn {
      bluetoothStateHandler.eventSink?(BluetoothState.off.rawValue)
      result(FlutterError(code: "bluetooth_off", message: "Bluetooth is not powered on.", details: nil))
      return
    }

    cancelAutoStop()
    if isAdvertising {
      peripheralManager.stopAdvertising()
      isAdvertising = false
    }
    peripheralManager.startAdvertising(peripheralData)
    lastBeaconRegion = region
    isAdvertising = true
    scheduleAutoStop(durationMs: durationMs)
    bluetoothStateHandler.eventSink?(BluetoothState.beaconing.rawValue)
    logHandler.eventSink?(["logLevel": "info", "message": "iBeacon advertising started."])
    result(0)
  }

  private func stopAdvertising(result: @escaping FlutterResult) {
    cancelAutoStop()
    peripheralManager.stopAdvertising()
    isAdvertising = false
    updateBluetoothState()
    logHandler.eventSink?(["logLevel": "info", "message": "iBeacon advertising stopped."])
    result(0)
  }

  private func scheduleAutoStop(durationMs: Int?) {
    cancelAutoStop()
    guard let durationMs, durationMs > 0 else {
      return
    }

    let workItem = DispatchWorkItem { [weak self] in
      self?.peripheralManager.stopAdvertising()
      self?.isAdvertising = false
      self?.updateBluetoothState()
      self?.logHandler.eventSink?(["logLevel": "info", "message": "iBeacon advertising stopped automatically."])
    }
    autoStopWorkItem = workItem
    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(durationMs), execute: workItem)
  }

  private func cancelAutoStop() {
    autoStopWorkItem?.cancel()
    autoStopWorkItem = nil
  }

  public func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
    switch peripheral.state {
    case .poweredOn:
      if !isAdvertising {
        bluetoothStateHandler.eventSink?(BluetoothState.ready.rawValue)
      }
    case .poweredOff:
      bluetoothStateHandler.eventSink?(BluetoothState.off.rawValue)
    case .unauthorized:
      bluetoothStateHandler.eventSink?(BluetoothState.unauthorized.rawValue)
    case .unsupported:
      bluetoothStateHandler.eventSink?(BluetoothState.unsupported.rawValue)
    default:
      bluetoothStateHandler.eventSink?(BluetoothState.unknown.rawValue)
    }
  }
}
