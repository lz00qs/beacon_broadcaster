import 'package:flutter_test/flutter_test.dart';
import 'package:beacon_broadcaster/beacon_broadcaster.dart';
import 'package:beacon_broadcaster/beacon_broadcaster_platform_interface.dart';
import 'package:beacon_broadcaster/beacon_broadcaster_channels.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockBeaconBroadcasterPlatform
    with MockPlatformInterfaceMixin
    implements BeaconBroadcasterPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Stream<BluetoothState> get bluetoothState => const Stream.empty();

  @override
  Stream<String> get nativeLog => const Stream.empty();
}

void main() {
  final BeaconBroadcasterPlatform initialPlatform =
      BeaconBroadcasterPlatform.instance;

  test('$ChannelsBeaconBroadcaster is the default instance', () {
    expect(initialPlatform, isInstanceOf<ChannelsBeaconBroadcaster>());
  });

  test('getPlatformVersion', () async {
    BeaconBroadcaster beaconBroadcasterPlugin = BeaconBroadcaster();
    MockBeaconBroadcasterPlatform fakePlatform =
        MockBeaconBroadcasterPlatform();
    BeaconBroadcasterPlatform.instance = fakePlatform;

    expect(await beaconBroadcasterPlugin.getPlatformVersion(), '42');
  });
}
