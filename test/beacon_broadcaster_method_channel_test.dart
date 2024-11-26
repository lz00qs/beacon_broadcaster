import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:beacon_broadcaster/beacon_broadcaster_channels.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ChannelsBeaconBroadcaster platform = ChannelsBeaconBroadcaster();
  const MethodChannel channel = MethodChannel('beacon_broadcaster');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return '42';
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
