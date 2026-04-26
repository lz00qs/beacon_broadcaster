import 'dart:async';
import 'dart:io';

import 'package:beacon_broadcaster/beacon_broadcaster.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'beacon_broadcaster_platform_interface.dart';

/// An implementation of [BeaconBroadcasterPlatform] that uses method channels.
class ChannelsBeaconBroadcaster extends BeaconBroadcasterPlatform {
  static StreamSubscription<dynamic>? _logSubscription;

  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel =
      const MethodChannel('beacon_broadcaster/method_channel');

  /// The event channel used to receive Bluetooth state changes.
  @visibleForTesting
  final bluetoothStateChannel =
      const EventChannel('beacon_broadcaster/bluetooth_state');

  /// The event channel used to receive native log messages.
  @visibleForTesting
  final logChannel = const EventChannel('beacon_broadcaster/log');

  @override
  Future<String?> getPlatformVersion() async {
    final version =
        await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<void> checkBluetoothState() {
    return methodChannel.invokeMethod<void>('checkBluetoothState');
  }

  @override
  Stream<BluetoothState> get bluetoothState {
    return bluetoothStateChannel.receiveBroadcastStream().map((event) {
      try {
        final stateString = event as String;
        return BluetoothState.values.firstWhere(
          (state) => state.toString().split('.').last == stateString,
        );
      } catch (e) {
        return BluetoothState.unknown;
      }
    });
  }

  @override
  void initializeLogger() {
    if (_logSubscription != null) {
      return;
    }
    try {
      _logSubscription = logChannel.receiveBroadcastStream().listen((event) {
        var iLogLevel = LogLevels.debug;
        var message = '';
        try {
          final logLevelString = event['logLevel'] as String;
          iLogLevel = LogLevels.values.firstWhere(
            (level) => level.toString().split('.').last == logLevelString,
          );
          message = event['message'] as String;
        } catch (e) {
          iLogLevel = LogLevels.error;
          message = 'Failed to parse log message: $event';
        }
        if (iLogLevel.index >= BeaconBroadcasterPlatform.logLevel.index) {
          if (kDebugMode) {
            print('Native [${iLogLevel.toString().split('.').last}]: $message');
          }
        }
      });
    } catch (_) {
      _logSubscription = null;
    }
  }

  @override
  Future<int> startAdvertising(
      {required Uint8List uuid,
      required int major,
      required int minor,
      required int txPower,
      required int? durationMs,
      required int advertiseMode,
      required int advertiseTxPower}) async {
    final parameters = <String, dynamic>{
      'uuid': uuid,
      'major': major,
      'minor': minor,
      'txPower': txPower,
      if (durationMs != null) 'durationMs': durationMs,
      // 'advertiseMode': advertiseMode,
      // 'advertiseTxPower': advertiseTxPower,
    };

    // android 平台的广播参数
    if (Platform.isAndroid) {
      parameters['advertiseMode'] = advertiseMode;
      parameters['advertiseTxPower'] = advertiseTxPower;
    }
    final result = await methodChannel.invokeMethod<int>(
      'startAdvertising',
      parameters,
    );
    return result ?? -1;
  }

  @override
  Future<int> stopAdvertising() async {
    final result = await methodChannel.invokeMethod<int>('stopAdvertising');
    return result ?? -1;
  }
}
