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

public class BeaconBroadcasterPlugin: NSObject, FlutterPlugin, CBPeripheralManagerDelegate {
  private let bluetoothStateHandler = BluetoothStateStreamHandler()
  private let logHandler = LogStreamHandler()
  private let peripheralManager = CBPeripheralManager(delegate: nil, queue: nil)
  private var activeAdvertisingRequestID: UInt64?
  private var nextAdvertisingRequestID: UInt64 = 0
  // Core Bluetooth omits a request identifier from its start callback, so keep
  // request order here to recognize callbacks from superseded starts.
  private var pendingAdvertisingRequestIDs: [UInt64] = []
  private var advertisingStarted = false
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
    peripheralManager.delegate = self
    bluetoothStateHandler.onListen = { [weak self] in
      self?.updateBluetoothState()
    }
  }

  private func bluetoothState(for peripheralState: CBManagerState) -> BluetoothState {
    switch peripheralState {
    case .poweredOn:
      return advertisingStarted || peripheralManager.isAdvertising ? .beaconing : .ready
    case .poweredOff:
      return .off
    case .unauthorized:
      return .unauthorized
    case .unsupported:
      return .unsupported
    default:
      return .unknown
    }
  }

  private func emitBluetoothState() {
    bluetoothStateHandler.eventSink?(bluetoothState(for: peripheralManager.state).rawValue)
  }

  private func bluetoothUnavailableError(for peripheralState: CBManagerState) -> FlutterError {
    switch peripheralState {
    case .poweredOff:
      return FlutterError(code: "bluetooth_off", message: "Bluetooth is not powered on.", details: nil)
    case .unauthorized:
      return FlutterError(code: "bluetooth_unauthorized", message: "Bluetooth permission is not authorized.", details: nil)
    case .unsupported:
      return FlutterError(code: "unsupported", message: "Bluetooth advertising is not supported on this device.", details: nil)
    default:
      return FlutterError(code: "bluetooth_unavailable", message: "Bluetooth is not ready to advertise.", details: bluetoothState(for: peripheralState).rawValue)
    }
  }

  private func updateBluetoothState() {
    #if targetEnvironment(simulator)
    bluetoothStateHandler.eventSink?(BluetoothState.ready.rawValue)
    return
    #else
    emitBluetoothState()
    #endif
  }

  private func startAdvertising(call: FlutterMethodCall, result: @escaping FlutterResult) {
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
      let state = bluetoothState(for: peripheralManager.state)
      bluetoothStateHandler.eventSink?(state.rawValue)
      result(bluetoothUnavailableError(for: peripheralManager.state))
      return
    }

    cancelAutoStop()
    stopActiveAdvertising()
    nextAdvertisingRequestID &+= 1
    let requestID = nextAdvertisingRequestID
    activeAdvertisingRequestID = requestID
    advertisingStarted = false
    pendingAdvertisingRequestIDs.append(requestID)
    peripheralManager.startAdvertising(peripheralData)
    lastBeaconRegion = region
    scheduleAutoStop(durationMs: durationMs, requestID: requestID)
    result(0)
  }

  private func stopAdvertising(result: @escaping FlutterResult) {
    cancelAutoStop()
    stopActiveAdvertising()
    updateBluetoothState()
    logHandler.eventSink?(["logLevel": "info", "message": "iBeacon advertising stopped."])
    result(0)
  }

  private func scheduleAutoStop(durationMs: Int?, requestID: UInt64) {
    cancelAutoStop()
    guard let durationMs, durationMs > 0 else {
      return
    }

    let workItem = DispatchWorkItem { [weak self] in
      guard let self, self.activeAdvertisingRequestID == requestID else {
        return
      }
      self.autoStopWorkItem = nil
      if self.stopActiveAdvertising(expectedRequestID: requestID) {
        self.updateBluetoothState()
        self.logHandler.eventSink?(["logLevel": "info", "message": "iBeacon advertising stopped automatically."])
      }
    }
    autoStopWorkItem = workItem
    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(durationMs), execute: workItem)
  }

  private func cancelAutoStop() {
    autoStopWorkItem?.cancel()
    autoStopWorkItem = nil
  }

  @discardableResult
  private func stopActiveAdvertising(expectedRequestID: UInt64? = nil) -> Bool {
    if let expectedRequestID, activeAdvertisingRequestID != expectedRequestID {
      return false
    }

    guard activeAdvertisingRequestID != nil || peripheralManager.isAdvertising else {
      return false
    }

    activeAdvertisingRequestID = nil
    advertisingStarted = false
    peripheralManager.stopAdvertising()
    return true
  }

  public func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
    guard !pendingAdvertisingRequestIDs.isEmpty else {
      if activeAdvertisingRequestID == nil && peripheral.isAdvertising {
        peripheral.stopAdvertising()
      }
      return
    }

    let completedRequestID = pendingAdvertisingRequestIDs.removeFirst()
    guard activeAdvertisingRequestID == completedRequestID else {
      if activeAdvertisingRequestID == nil && peripheral.isAdvertising {
        peripheral.stopAdvertising()
      }
      return
    }

    if let error {
      activeAdvertisingRequestID = nil
      advertisingStarted = false
      cancelAutoStop()
      if peripheral.isAdvertising {
        peripheral.stopAdvertising()
      }
      bluetoothStateHandler.eventSink?(BluetoothState.error.rawValue)
      logHandler.eventSink?(["logLevel": "error", "message": "Failed to start iBeacon advertising: \(error.localizedDescription)"])
      return
    }

    advertisingStarted = true
    bluetoothStateHandler.eventSink?(BluetoothState.beaconing.rawValue)
    logHandler.eventSink?(["logLevel": "info", "message": "iBeacon advertising started."])
  }

  public func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
    if peripheral.state != .poweredOn {
      activeAdvertisingRequestID = nil
      pendingAdvertisingRequestIDs.removeAll()
      advertisingStarted = false
      cancelAutoStop()
    }
    emitBluetoothState()
  }
}
