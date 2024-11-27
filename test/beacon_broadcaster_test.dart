import 'dart:typed_data';

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
  Future<void> checkBluetoothState() => Future.value();

  @override
  void initializeLogger() {}

  @override
  Future<int> startAdvertising(
      {required Uint8List uuid,
      required int major,
      required int minor,
      required int txPower,
      required int advertiseMode,
      required int advertiseTxPower}) {
    // TODO: implement startAdvertising
    return Future.value(0);
  }

  @override
  Future<int> stopAdvertising() {
    return Future.value(0);
  }
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
