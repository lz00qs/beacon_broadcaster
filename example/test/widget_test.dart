import 'dart:async';
import 'dart:typed_data';

import 'package:beacon_broadcaster/beacon_broadcaster.dart';
import 'package:beacon_broadcaster/beacon_broadcaster_platform_interface.dart';
import 'package:beacon_broadcaster_example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class FakeBeaconBroadcasterPlatform
    with MockPlatformInterfaceMixin
    implements BeaconBroadcasterPlatform {
  FakeBeaconBroadcasterPlatform(this._bluetoothState);

  final Stream<BluetoothState> _bluetoothState;

  @override
  Stream<BluetoothState> get bluetoothState => _bluetoothState;

  @override
  Future<void> checkBluetoothState() async {}

  @override
  Future<String?> getPlatformVersion() async => 'Android 14';

  @override
  void initializeLogger() {}

  @override
  Future<int> startAdvertising({
    required Uint8List uuid,
    required int major,
    required int minor,
    required int txPower,
    required int? durationMs,
    required int advertiseMode,
    required int advertiseTxPower,
  }) async =>
      0;

  @override
  Future<int> stopAdvertising() async => 0;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late BeaconBroadcasterPlatform originalPlatform;

  setUp(() {
    originalPlatform = BeaconBroadcasterPlatform.instance;
  });

  tearDown(() {
    BeaconBroadcasterPlatform.instance = originalPlatform;
  });

  testWidgets('MyApp shows the disabled page when Bluetooth is off',
      (tester) async {
    BeaconBroadcasterPlatform.instance = FakeBeaconBroadcasterPlatform(
      Stream<BluetoothState>.value(BluetoothState.off),
    );

    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(home: MyApp()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Bluetooth is disabled.'), findsOneWidget);
    expect(find.byType(Switch), findsOneWidget);
  });

  testWidgets('MyApp shows the unsupported page when Bluetooth is unsupported',
      (tester) async {
    BeaconBroadcasterPlatform.instance = FakeBeaconBroadcasterPlatform(
      Stream<BluetoothState>.value(BluetoothState.unsupported),
    );

    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(home: MyApp()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Bluetooth is unsupported.'), findsOneWidget);
  });
}
