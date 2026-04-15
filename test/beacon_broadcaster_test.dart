import 'dart:async';
import 'dart:typed_data';

import 'package:beacon_broadcaster/beacon_broadcaster.dart';
import 'package:beacon_broadcaster/beacon_broadcaster_channels.dart';
import 'package:beacon_broadcaster/beacon_broadcaster_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class FakeBeaconBroadcasterPlatform
    with MockPlatformInterfaceMixin
    implements BeaconBroadcasterPlatform {
  FakeBeaconBroadcasterPlatform({
    Stream<BluetoothState>? bluetoothState,
    this.platformVersion = '42',
    this.startAdvertisingResult = 0,
    this.stopAdvertisingResult = 0,
  }) : _bluetoothState = bluetoothState ?? const Stream.empty();

  final Stream<BluetoothState> _bluetoothState;
  final String? platformVersion;
  final int startAdvertisingResult;
  final int stopAdvertisingResult;

  int initializeLoggerCallCount = 0;
  int checkBluetoothStateCallCount = 0;
  int stopAdvertisingCallCount = 0;
  StartAdvertisingCall? lastStartAdvertisingCall;

  @override
  Stream<BluetoothState> get bluetoothState => _bluetoothState;

  @override
  Future<void> checkBluetoothState() async {
    checkBluetoothStateCallCount++;
  }

  @override
  Future<String?> getPlatformVersion() async => platformVersion;

  @override
  void initializeLogger() {
    initializeLoggerCallCount++;
  }

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
      uuid: uuid,
      major: major,
      minor: minor,
      txPower: txPower,
      durationMs: durationMs,
      advertiseMode: advertiseMode,
      advertiseTxPower: advertiseTxPower,
    );
    return startAdvertisingResult;
  }

  @override
  Future<int> stopAdvertising() async {
    stopAdvertisingCallCount++;
    return stopAdvertisingResult;
  }
}

class StartAdvertisingCall {
  StartAdvertisingCall({
    required this.uuid,
    required this.major,
    required this.minor,
    required this.txPower,
    required this.durationMs,
    required this.advertiseMode,
    required this.advertiseTxPower,
  });

  final Uint8List uuid;
  final int major;
  final int minor;
  final int txPower;
  final int? durationMs;
  final int advertiseMode;
  final int advertiseTxPower;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late BeaconBroadcasterPlatform originalPlatform;

  setUp(() {
    originalPlatform = BeaconBroadcasterPlatform.instance;
    BeaconBroadcasterPlatform.logLevel = LogLevels.debug;
  });

  tearDown(() {
    BeaconBroadcasterPlatform.instance = originalPlatform;
  });

  group('defaults', () {
    test('$ChannelsBeaconBroadcaster is the default instance', () {
      expect(BeaconBroadcasterPlatform.instance,
          isInstanceOf<ChannelsBeaconBroadcaster>());
    });
  });

  group('validation helpers', () {
    test('isUuidValid accepts canonical UUIDs', () {
      expect(isUuidValid('550e8400-e29b-41d4-a716-446655440000'), isTrue);
    });

    test('isUuidValid rejects malformed UUIDs', () {
      expect(isUuidValid('550e8400e29b41d4a716446655440000'), isFalse);
    });

    test('major and minor support full uint16 range', () {
      expect(isMajorOrMinorValid(0), isTrue);
      expect(isMajorOrMinorValid(65535), isTrue);
      expect(isMajorOrMinorValid(-1), isFalse);
      expect(isMajorOrMinorValid(65536), isFalse);
    });

    test('txPower enforces signed byte range', () {
      expect(isTxPowerValid(-127), isTrue);
      expect(isTxPowerValid(127), isTrue);
      expect(isTxPowerValid(-128), isFalse);
      expect(isTxPowerValid(128), isFalse);
    });

    test('uuidStringToBytes converts UUID into 16 bytes', () {
      final bytes = uuidStringToBytes('550e8400-e29b-41d4-a716-446655440000');

      expect(bytes.length, 16);
      expect(bytes[0], 0x55);
      expect(bytes[15], 0x00);
    });

    test('uuidStringToBytes throws on invalid UUID', () {
      expect(
        () => uuidStringToBytes('invalid-uuid'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('BeaconBroadcaster', () {
    test('initializes logger only once across instances', () {
      final fakePlatform = FakeBeaconBroadcasterPlatform();
      BeaconBroadcasterPlatform.instance = fakePlatform;

      BeaconBroadcaster();
      BeaconBroadcaster();

      expect(fakePlatform.initializeLoggerCallCount, 1);
    });

    test('setLogLevel updates platform log level', () {
      final broadcaster = BeaconBroadcaster();

      broadcaster.setLogLevel(LogLevels.error);

      expect(BeaconBroadcasterPlatform.logLevel, LogLevels.error);
    });

    test('getPlatformVersion delegates to platform', () async {
      final fakePlatform =
          FakeBeaconBroadcasterPlatform(platformVersion: 'Android 14');
      BeaconBroadcasterPlatform.instance = fakePlatform;
      final broadcaster = BeaconBroadcaster();

      expect(await broadcaster.getPlatformVersion(), 'Android 14');
    });

    test('checkBluetoothState delegates to platform', () async {
      final fakePlatform = FakeBeaconBroadcasterPlatform();
      BeaconBroadcasterPlatform.instance = fakePlatform;
      final broadcaster = BeaconBroadcaster();

      await broadcaster.checkBluetoothState();

      expect(fakePlatform.checkBluetoothStateCallCount, 1);
    });

    test('bluetoothState exposes the platform stream', () async {
      final controller = StreamController<BluetoothState>();
      final fakePlatform =
          FakeBeaconBroadcasterPlatform(bluetoothState: controller.stream);
      BeaconBroadcasterPlatform.instance = fakePlatform;
      final broadcaster = BeaconBroadcaster();

      final states = <BluetoothState>[];
      final subscription = broadcaster.bluetoothState.listen(states.add);
      controller.add(BluetoothState.ready);
      await Future<void>.delayed(Duration.zero);

      await subscription.cancel();
      await controller.close();

      expect(states, [BluetoothState.ready]);
    });

    test('startAdvertising forwards validated values to the platform',
        () async {
      final fakePlatform = FakeBeaconBroadcasterPlatform();
      BeaconBroadcasterPlatform.instance = fakePlatform;
      final broadcaster = BeaconBroadcaster();

      final result = await broadcaster.startAdvertising(
        uuid: '550e8400-e29b-41d4-a716-446655440000',
        major: 65535,
        minor: 65535,
        txPower: -59,
        durationMs: 5000,
        advertiseMode: AndroidBleAdvertiseSettings.advertiseModeLowLatency,
        advertiseTxPower: AndroidBleAdvertiseSettings.advertiseTxPowerHigh,
      );

      expect(result, 0);
      expect(fakePlatform.lastStartAdvertisingCall, isNotNull);
      expect(fakePlatform.lastStartAdvertisingCall!.uuid.length, 16);
      expect(fakePlatform.lastStartAdvertisingCall!.major, 65535);
      expect(fakePlatform.lastStartAdvertisingCall!.minor, 65535);
      expect(fakePlatform.lastStartAdvertisingCall!.txPower, -59);
      expect(fakePlatform.lastStartAdvertisingCall!.durationMs, 5000);
      expect(
        fakePlatform.lastStartAdvertisingCall!.advertiseMode,
        AndroidBleAdvertiseSettings.advertiseModeLowLatency,
      );
      expect(
        fakePlatform.lastStartAdvertisingCall!.advertiseTxPower,
        AndroidBleAdvertiseSettings.advertiseTxPowerHigh,
      );
    });

    test('stopAdvertising delegates to platform', () async {
      final fakePlatform =
          FakeBeaconBroadcasterPlatform(stopAdvertisingResult: 7);
      BeaconBroadcasterPlatform.instance = fakePlatform;
      final broadcaster = BeaconBroadcaster();

      expect(await broadcaster.stopAdvertising(), 7);
      expect(fakePlatform.stopAdvertisingCallCount, 1);
    });

    test('rejects invalid UUID', () async {
      final broadcaster = BeaconBroadcaster();

      await expectLater(
        broadcaster.startAdvertising(
          uuid: 'invalid-uuid',
          major: 1,
          minor: 1,
          txPower: -59,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects invalid major', () async {
      final broadcaster = BeaconBroadcaster();

      await expectLater(
        broadcaster.startAdvertising(
          uuid: '550e8400-e29b-41d4-a716-446655440000',
          major: -1,
          minor: 1,
          txPower: -59,
        ),
        throwsA('Invalid major'),
      );
    });

    test('rejects invalid minor', () async {
      final broadcaster = BeaconBroadcaster();

      await expectLater(
        broadcaster.startAdvertising(
          uuid: '550e8400-e29b-41d4-a716-446655440000',
          major: 1,
          minor: 65536,
          txPower: -59,
        ),
        throwsA('Invalid minor'),
      );
    });

    test('rejects invalid txPower', () async {
      final broadcaster = BeaconBroadcaster();

      await expectLater(
        broadcaster.startAdvertising(
          uuid: '550e8400-e29b-41d4-a716-446655440000',
          major: 1,
          minor: 1,
          txPower: 128,
        ),
        throwsA('Invalid txPower'),
      );
    });

    test('rejects non-positive durationMs', () async {
      final broadcaster = BeaconBroadcaster();

      await expectLater(
        broadcaster.startAdvertising(
          uuid: '550e8400-e29b-41d4-a716-446655440000',
          major: 1,
          minor: 1,
          txPower: -59,
          durationMs: 0,
        ),
        throwsA('Invalid durationMs'),
      );
    });

    test('rejects invalid advertiseMode', () async {
      final broadcaster = BeaconBroadcaster();

      await expectLater(
        broadcaster.startAdvertising(
          uuid: '550e8400-e29b-41d4-a716-446655440000',
          major: 1,
          minor: 1,
          txPower: -59,
          advertiseMode: 99,
        ),
        throwsA('Invalid advertiseMode'),
      );
    });

    test('rejects invalid advertiseTxPower', () async {
      final broadcaster = BeaconBroadcaster();

      await expectLater(
        broadcaster.startAdvertising(
          uuid: '550e8400-e29b-41d4-a716-446655440000',
          major: 1,
          minor: 1,
          txPower: -59,
          advertiseTxPower: 99,
        ),
        throwsA('Invalid advertiseTxPower'),
      );
    });
  });
}
