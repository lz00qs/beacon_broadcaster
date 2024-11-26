
import 'beacon_broadcaster_platform_interface.dart';

class BeaconBroadcaster {
  Future<String?> getPlatformVersion() {
    return BeaconBroadcasterPlatform.instance.getPlatformVersion();
  }
}
