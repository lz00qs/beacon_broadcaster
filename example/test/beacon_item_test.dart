import 'dart:async';
import 'dart:typed_data';

import 'package:beacon_broadcaster/beacon_broadcaster.dart';
import 'package:beacon_broadcaster/beacon_broadcaster_platform_interface.dart';
import 'package:beacon_broadcaster_example/models/beacon.dart';
import 'package:beacon_broadcaster_example/providers.dart';
import 'package:beacon_broadcaster_example/widgets/beacon_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class FakeBeaconBroadcasterPlatform
    with MockPlatformInterfaceMixin
    implements BeaconBroadcasterPlatform {
  FakeBeaconBroadcasterPlatform(this._bluetoothState);

  final Stream<BluetoothState> _bluetoothState;

  int stopAdvertisingCallCount = 0;
  StartAdvertisingCall? lastStartAdvertisingCall;

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
  }) async {
    lastStartAdvertisingCall = StartAdvertisingCall(
      major: major,
      minor: minor,
      txPower: txPower,
      durationMs: durationMs,
      advertiseMode: advertiseMode,
      advertiseTxPower: advertiseTxPower,
    );
    return 0;
  }

  @override
  Future<int> stopAdvertising() async {
    stopAdvertisingCallCount++;
    return 0;
  }
}

class StartAdvertisingCall {
  StartAdvertisingCall({
    required this.major,
    required this.minor,
    required this.txPower,
    required this.durationMs,
    required this.advertiseMode,
    required this.advertiseTxPower,
  });

  final int major;
  final int minor;
  final int txPower;
  final int? durationMs;
  final int advertiseMode;
  final int advertiseTxPower;
}

BoxDecoration _itemDecoration(WidgetTester tester) {
  final container = tester.widget<Container>(
    find.descendant(
      of: find.byType(BeaconItem),
      matching: find.byWidgetPredicate(
        (widget) => widget is Container && widget.decoration is BoxDecoration,
      ),
    ).first,
  );

  return container.decoration! as BoxDecoration;
}

Future<ProviderContainer> _pumpBeaconItem(
  WidgetTester tester, {
  required Beacon beacon,
  required bool isToggle,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: BeaconItem(
            id: beacon.id,
            beacon: beacon,
            isToggle: isToggle,
          ),
        ),
      ),
    ),
  );

  return ProviderScope.containerOf(tester.element(find.byType(BeaconItem)));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late BeaconBroadcasterPlatform originalPlatform;
  late StreamController<BluetoothState> bluetoothStateController;
  late FakeBeaconBroadcasterPlatform fakePlatform;

  final beacon = Beacon(
    name: 'Test Beacon',
    uuid: '550e8400-e29b-41d4-a716-446655440000',
    major: 0x66,
    minor: 0x99,
    txPower: 0,
  )..id = 7;

  setUp(() {
    originalPlatform = BeaconBroadcasterPlatform.instance;
    bluetoothStateController = StreamController<BluetoothState>.broadcast();
    fakePlatform = FakeBeaconBroadcasterPlatform(bluetoothStateController.stream);
    BeaconBroadcasterPlatform.instance = fakePlatform;
  });

  tearDown(() async {
    BeaconBroadcasterPlatform.instance = originalPlatform;
    await bluetoothStateController.close();
  });

  testWidgets('press-and-hold mode darkens while pressed and stops on release',
      (tester) async {
    await _pumpBeaconItem(tester, beacon: beacon, isToggle: false);

    expect(_itemDecoration(tester).color, Colors.blue);

    final gesture = await tester.startGesture(tester.getCenter(find.text('Test Beacon')));
    await tester.pump();

    expect(_itemDecoration(tester).color, const Color(0xFF1976D2));
    expect(fakePlatform.lastStartAdvertisingCall, isNotNull);

    await gesture.up();
    await tester.pump();

    expect(_itemDecoration(tester).color, Colors.blue);
    expect(fakePlatform.stopAdvertisingCallCount, greaterThanOrEqualTo(2));
  });

  testWidgets(
      'toggle mode uses durationMs and reflects beaconing state with item color',
      (tester) async {
    final container = await _pumpBeaconItem(tester, beacon: beacon, isToggle: true);
    container.read(broadcastDurationMsProvider.notifier).set(3000);
    await tester.pump();

    expect(_itemDecoration(tester).color, Colors.blue);

    await tester.tap(find.text('Test Beacon'));
    await tester.pump();

    expect(fakePlatform.lastStartAdvertisingCall, isNotNull);
    expect(fakePlatform.lastStartAdvertisingCall!.durationMs, 3000);
    expect(_itemDecoration(tester).color, Colors.blue);

    bluetoothStateController.add(BluetoothState.beaconing);
    await tester.pump();
    await tester.pump();

    expect(_itemDecoration(tester).color, const Color(0xFF1976D2));

    bluetoothStateController.add(BluetoothState.ready);
    await tester.pump();
    await tester.pump();

    expect(_itemDecoration(tester).color, Colors.blue);
  });
}
