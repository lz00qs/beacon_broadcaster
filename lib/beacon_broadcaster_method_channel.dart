import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'beacon_broadcaster_platform_interface.dart';

/// An implementation of [BeaconBroadcasterPlatform] that uses method channels.
class MethodChannelBeaconBroadcaster extends BeaconBroadcasterPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('beacon_broadcaster');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
