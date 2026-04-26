import 'dart:async';
import 'dart:typed_data';

import 'beacon_broadcaster_platform_interface.dart';

/// Bluetooth and advertising states emitted by the native platform.
enum BluetoothState {
  /// The native platform has not reported a concrete state yet.
  unknown,

  /// The device or platform does not support BLE advertising.
  unsupported,

  /// The app is missing the required Bluetooth permission or authorization.
  unauthorized,

  /// Bluetooth is powered on and ready to start iBeacon advertising.
  ready,

  /// iBeacon advertising is currently active.
  beaconing,

  /// Bluetooth is powered off.
  off,

  /// The native platform reported an advertising error.
  error,
}

/// Log levels emitted by the native plugin logger.
enum LogLevels {
  /// Verbose diagnostic messages.
  debug,

  /// Informational lifecycle messages.
  info,

  /// Recoverable issues or degraded behavior.
  warning,

  /// Native errors that prevented an operation from completing.
  error,
}

/// Android-only BLE advertising constants.
///
/// These values map to Android's `AdvertiseSettings` mode and transmit power
/// constants. They are ignored on iOS.
class AndroidBleAdvertiseSettings {
  /// Prefer lower power consumption over advertising frequency.
  static const int advertiseModeLowPower = 0;

  /// Use Android's balanced advertising mode.
  static const int advertiseModeBalanced = 1;

  /// Prefer lower latency and higher advertising frequency.
  static const int advertiseModeLowLatency = 2;

  /// Use Android's ultra-low transmit power level.
  static const int advertiseTxPowerUltraLow = 0;

  /// Use Android's low transmit power level.
  static const int advertiseTxPowerLow = 1;

  /// Use Android's medium transmit power level.
  static const int advertiseTxPowerMedium = 2;

  /// Use Android's high transmit power level.
  static const int advertiseTxPowerHigh = 3;
}

/// Returns whether [uuid] is a canonical 16-byte UUID string.
///
/// The expected format is `550e8400-e29b-41d4-a716-446655440000`.
bool isUuidValid(String uuid) {
  RegExp regExp = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
  return regExp.hasMatch(uuid);
}

/// Returns whether [value] is valid for an iBeacon major or minor identifier.
bool isMajorOrMinorValid(int value) {
  return value >= 0 && value <= 65535;
}

/// Returns whether [value] is valid for measured iBeacon transmit power.
bool isTxPowerValid(int value) {
  return value >= -127 && value <= 127;
}

/// Converts a canonical UUID string into the 16 bytes used by native APIs.
///
/// Throws an [ArgumentError] if [uuid] is not in canonical UUID format.
Uint8List uuidStringToBytes(String uuid) {
  if (!isUuidValid(uuid)) {
    throw ArgumentError('Invalid UUID');
  }
  final uuidWithoutDashes = uuid.replaceAll('-', '');
  final uuidBytes = Uint8List(16);
  for (var i = 0; i < 16; i++) {
    uuidBytes[i] =
        int.parse(uuidWithoutDashes.substring(i * 2, i * 2 + 2), radix: 16);
  }
  return uuidBytes;
}

/// Broadcasts iBeacon packets and exposes Bluetooth state updates.
class BeaconBroadcaster {
  static bool _loggerInitialized = false;

  /// Creates a broadcaster and initializes the native log stream once.
  BeaconBroadcaster() {
    if (!_loggerInitialized) {
      BeaconBroadcasterPlatform.instance.initializeLogger();
      _loggerInitialized = true;
    }
  }

  /// Sets the minimum [LogLevels] value printed from native log events.
  void setLogLevel(LogLevels level) {
    BeaconBroadcasterPlatform.logLevel = level;
  }

  /// Returns the native platform version string.
  Future<String?> getPlatformVersion() {
    return BeaconBroadcasterPlatform.instance.getPlatformVersion();
  }

  /// Requests an immediate Bluetooth state update from the native platform.
  Future<void> checkBluetoothState() {
    return BeaconBroadcasterPlatform.instance.checkBluetoothState();
  }

  /// Streams Bluetooth and advertising state changes from the native platform.
  Stream<BluetoothState> get bluetoothState {
    return BeaconBroadcasterPlatform.instance.bluetoothState;
  }

  /// Starts broadcasting an iBeacon packet.
  ///
  /// [uuid] must be a canonical UUID string. [major] and [minor] must be in the
  /// range `0..65535`. [txPower] must be in the signed byte range `-127..127`.
  /// When [durationMs] is provided, native advertising stops automatically after
  /// that many milliseconds.
  ///
  /// [advertiseMode] and [advertiseTxPower] are Android-only settings and are
  /// ignored on iOS.
  Future<int> startAdvertising(
      {required String uuid,
      required int major,
      required int minor,
      required int txPower,
      int? durationMs,
      int advertiseMode = AndroidBleAdvertiseSettings.advertiseModeBalanced,
      int advertiseTxPower =
          AndroidBleAdvertiseSettings.advertiseTxPowerMedium}) {
    var uuidBytes = Uint8List(16);
    try {
      uuidBytes = uuidStringToBytes(uuid);
    } catch (e) {
      return Future.error(e);
    }
    if (!isMajorOrMinorValid(major)) {
      return Future.error('Invalid major');
    }
    if (!isMajorOrMinorValid(minor)) {
      return Future.error('Invalid minor');
    }
    if (!isTxPowerValid(txPower)) {
      return Future.error('Invalid txPower');
    }
    if (durationMs != null && durationMs <= 0) {
      return Future.error('Invalid durationMs');
    }
    if (advertiseMode < 0 || advertiseMode > 2) {
      return Future.error('Invalid advertiseMode');
    }
    if (advertiseTxPower < 0 || advertiseTxPower > 3) {
      return Future.error('Invalid advertiseTxPower');
    }
    return BeaconBroadcasterPlatform.instance.startAdvertising(
        uuid: uuidBytes,
        major: major,
        minor: minor,
        txPower: txPower,
        durationMs: durationMs,
        advertiseMode: advertiseMode,
        advertiseTxPower: advertiseTxPower);
  }

  /// Stops the active iBeacon advertising session.
  Future<int> stopAdvertising() {
    return BeaconBroadcasterPlatform.instance.stopAdvertising();
  }
}
