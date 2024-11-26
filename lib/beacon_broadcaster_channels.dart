import 'package:beacon_broadcaster/beacon_broadcaster.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'beacon_broadcaster_platform_interface.dart';

/// An implementation of [BeaconBroadcasterPlatform] that uses method channels.
class ChannelsBeaconBroadcaster extends BeaconBroadcasterPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel =
      const MethodChannel('beacon_broadcaster/method_channel');

  @visibleForTesting
  final bluetoothStateChannel =
      const EventChannel('beacon_broadcaster/bluetooth_state');

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
  Stream<String> get nativeLog {
    return logChannel.receiveBroadcastStream().map((event) {
      try {
        return event as String;
      } catch (e) {
        return '';
      }
    });
  }
}
