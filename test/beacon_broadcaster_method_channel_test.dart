import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:beacon_broadcaster/beacon_broadcaster_channels.dart';
import 'package:beacon_broadcaster/beacon_broadcaster.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final binding = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  ChannelsBeaconBroadcaster platform = ChannelsBeaconBroadcaster();
  const MethodChannel channel =
      MethodChannel('beacon_broadcaster/method_channel');
  MethodCall? lastMethodCall;
  int bluetoothStateListenCount = 0;
  int logListenCount = 0;

  setUp(() {
    lastMethodCall = null;
    bluetoothStateListenCount = 0;
    logListenCount = 0;
    binding.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        lastMethodCall = methodCall;
        if (methodCall.method == 'startAdvertising') {
          return 0;
        }
        if (methodCall.method == 'stopAdvertising') {
          return 0;
        }
        return '42';
      },
    );
    binding.setMockStreamHandler(
      platform.bluetoothStateChannel,
      MockStreamHandler.inline(
        onListen: (_, events) {
          bluetoothStateListenCount++;
          events.success('ready');
          events.success('unexpected-state');
        },
      ),
    );
    binding.setMockStreamHandler(
      platform.logChannel,
      MockStreamHandler.inline(
        onListen: (_, events) {
          logListenCount++;
          events.success({'logLevel': 'info', 'message': 'hello'});
          events.success({'bad': 'payload'});
        },
      ),
    );
  });

  tearDown(() {
    binding.setMockMethodCallHandler(channel, null);
    binding.setMockStreamHandler(platform.bluetoothStateChannel, null);
    binding.setMockStreamHandler(platform.logChannel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });

  test('checkBluetoothState forwards the method call', () async {
    await platform.checkBluetoothState();

    expect(lastMethodCall?.method, 'checkBluetoothState');
  });

  test('bluetoothState maps valid and invalid native events', () async {
    final states = await platform.bluetoothState.take(2).toList();

    expect(bluetoothStateListenCount, 1);
    expect(states, [
      BluetoothState.ready,
      BluetoothState.unknown,
    ]);
  });

  test('startAdvertising forwards durationMs when provided', () async {
    await platform.startAdvertising(
      uuid: Uint8List(16),
      major: 1,
      minor: 2,
      txPower: -59,
      durationMs: 5000,
      advertiseMode: 1,
      advertiseTxPower: 2,
    );

    expect(lastMethodCall?.method, 'startAdvertising');
    expect(lastMethodCall?.arguments['durationMs'], 5000);
  });

  test('startAdvertising omits durationMs when not provided', () async {
    await platform.startAdvertising(
      uuid: Uint8List(16),
      major: 1,
      minor: 2,
      txPower: -59,
      durationMs: null,
      advertiseMode: 1,
      advertiseTxPower: 2,
    );

    expect(lastMethodCall?.method, 'startAdvertising');
    expect(lastMethodCall?.arguments.containsKey('durationMs'), isFalse);
  });

  test('startAdvertising returns -1 when the native side returns null',
      () async {
    binding.setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      lastMethodCall = methodCall;
      if (methodCall.method == 'startAdvertising') {
        return null;
      }
      return '42';
    });

    final result = await platform.startAdvertising(
      uuid: Uint8List(16),
      major: 1,
      minor: 2,
      txPower: -59,
      durationMs: null,
      advertiseMode: 1,
      advertiseTxPower: 2,
    );

    expect(result, -1);
  });

  test('stopAdvertising returns -1 when the native side returns null',
      () async {
    binding.setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      lastMethodCall = methodCall;
      if (methodCall.method == 'stopAdvertising') {
        return null;
      }
      return '42';
    });

    final result = await platform.stopAdvertising();

    expect(lastMethodCall?.method, 'stopAdvertising');
    expect(result, -1);
  });

  test('initializeLogger subscribes once and parses log payloads', () async {
    final printedMessages = <String>[];

    await runZoned(
      () async {
        platform.initializeLogger();
        platform.initializeLogger();
        await Future<void>.delayed(Duration.zero);
      },
      zoneSpecification: ZoneSpecification(
        print: (_, __, ___, String line) {
          printedMessages.add(line);
        },
      ),
    );

    expect(logListenCount, 1);
    expect(
      printedMessages,
      contains('Native [info]: hello'),
    );
    expect(
      printedMessages,
      contains(
        'Native [error]: Failed to parse log message: {bad: payload}',
      ),
    );
  });
}
