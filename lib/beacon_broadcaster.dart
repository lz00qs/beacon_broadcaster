import 'dart:async';
import 'dart:typed_data';

import 'beacon_broadcaster_platform_interface.dart';

enum BluetoothState {
  unknown,
  unsupported,
  unauthorized,
  ready,
  beaconing,
  off,
  error,
}

enum LogLevels {
  debug,
  info,
  warning,
  error,
}

class AndroidBleAdvertiseSettings {
  static const int advertiseModeLowPower = 0;
  static const int advertiseModeBalanced = 1;
  static const int advertiseModeLowLatency = 2;
  static const int advertiseTxPowerUltraLow = 0;
  static const int advertiseTxPowerLow = 1;
  static const int advertiseTxPowerMedium = 2;
  static const int advertiseTxPowerHigh = 3;
}

// 检验 16Bytes 的 16 进制 UUID 是否合法 550e8400-e29b-41d4-a716-446655440000
bool isUUID(String uuid) {
  RegExp regExp = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
  return regExp.hasMatch(uuid);
}

Uint8List uuidStringToBytes(String uuid) {
  if (!isUUID(uuid)) {
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

class BeaconBroadcaster {
  BeaconBroadcaster() {
    BeaconBroadcasterPlatform.instance.initializeLogger();
  }

  void setLogLevel(LogLevels level) {
    BeaconBroadcasterPlatform.logLevel = level;
  }

  Future<String?> getPlatformVersion() {
    return BeaconBroadcasterPlatform.instance.getPlatformVersion();
  }

  Future<void> checkBluetoothState() {
    return BeaconBroadcasterPlatform.instance.checkBluetoothState();
  }

  Stream<BluetoothState> get bluetoothState {
    return BeaconBroadcasterPlatform.instance.bluetoothState;
  }

  Future<int> startAdvertising(
      {required String uuid,
      required int major,
      required int minor,
      required int txPower,
      int advertiseMode = AndroidBleAdvertiseSettings.advertiseModeBalanced,
      int advertiseTxPower =
          AndroidBleAdvertiseSettings.advertiseTxPowerMedium}) {
    var uuidBytes = Uint8List(16);
    try {
      uuidBytes = uuidStringToBytes(uuid);
    } catch (e) {
      return Future.error(e);
    }
    if (major < 0 || major > 65535) {
      return Future.error('Invalid major');
    }
    if (minor < 0 || minor > 65535) {
      return Future.error('Invalid minor');
    }
    if (txPower < -100 || txPower > 20) {
      return Future.error('Invalid txPower');
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
        advertiseMode: advertiseMode,
        advertiseTxPower: advertiseTxPower);
  }

  Future<int> stopAdvertising() {
    return BeaconBroadcasterPlatform.instance.stopAdvertising();
  }
}
