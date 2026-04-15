import 'dart:typed_data';

import 'package:beacon_broadcaster/beacon_broadcaster_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

class MinimalBeaconBroadcasterPlatform extends BeaconBroadcasterPlatform {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BeaconBroadcasterPlatform default methods', () {
    final platform = MinimalBeaconBroadcasterPlatform();

    test('bluetoothState throws UnimplementedError', () {
      expect(() => platform.bluetoothState, throwsUnimplementedError);
    });

    test('getPlatformVersion throws UnimplementedError', () {
      expect(platform.getPlatformVersion, throwsUnimplementedError);
    });

    test('checkBluetoothState throws UnimplementedError', () {
      expect(platform.checkBluetoothState, throwsUnimplementedError);
    });

    test('initializeLogger throws UnimplementedError', () {
      expect(platform.initializeLogger, throwsUnimplementedError);
    });

    test('startAdvertising throws UnimplementedError', () {
      expect(
        () => platform.startAdvertising(
          uuid: Uint8List(16),
          major: 1,
          minor: 1,
          txPower: -59,
          durationMs: null,
          advertiseMode: 1,
          advertiseTxPower: 1,
        ),
        throwsUnimplementedError,
      );
    });

    test('stopAdvertising throws UnimplementedError', () {
      expect(platform.stopAdvertising, throwsUnimplementedError);
    });
  });
}
