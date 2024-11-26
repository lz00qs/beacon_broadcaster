import 'beacon_broadcaster_platform_interface.dart';

enum BluetoothState {
  unknown,
  unsupported,
  unauthorized,
  ready,
  beaconing,
  on,
  off,
}

class BeaconBroadcaster {
  Future<String?> getPlatformVersion() {
    return BeaconBroadcasterPlatform.instance.getPlatformVersion();
  }

  Stream<BluetoothState> get bluetoothState {
    return BeaconBroadcasterPlatform.instance.bluetoothState;
  }

  Stream<String> get nativeLog {
    return BeaconBroadcasterPlatform.instance.nativeLog;
  }
}
