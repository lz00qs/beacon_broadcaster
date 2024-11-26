import 'package:flutter_test/flutter_test.dart';
import 'package:beacon_broadcaster/beacon_broadcaster.dart';
import 'package:beacon_broadcaster/beacon_broadcaster_platform_interface.dart';
import 'package:beacon_broadcaster/beacon_broadcaster_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockBeaconBroadcasterPlatform
    with MockPlatformInterfaceMixin
    implements BeaconBroadcasterPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final BeaconBroadcasterPlatform initialPlatform = BeaconBroadcasterPlatform.instance;

  test('$MethodChannelBeaconBroadcaster is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelBeaconBroadcaster>());
  });

  test('getPlatformVersion', () async {
    BeaconBroadcaster beaconBroadcasterPlugin = BeaconBroadcaster();
    MockBeaconBroadcasterPlatform fakePlatform = MockBeaconBroadcasterPlatform();
    BeaconBroadcasterPlatform.instance = fakePlatform;

    expect(await beaconBroadcasterPlugin.getPlatformVersion(), '42');
  });
}
