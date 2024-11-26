import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'beacon_broadcaster_method_channel.dart';

abstract class BeaconBroadcasterPlatform extends PlatformInterface {
  /// Constructs a BeaconBroadcasterPlatform.
  BeaconBroadcasterPlatform() : super(token: _token);

  static final Object _token = Object();

  static BeaconBroadcasterPlatform _instance = MethodChannelBeaconBroadcaster();

  /// The default instance of [BeaconBroadcasterPlatform] to use.
  ///
  /// Defaults to [MethodChannelBeaconBroadcaster].
  static BeaconBroadcasterPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [BeaconBroadcasterPlatform] when
  /// they register themselves.
  static set instance(BeaconBroadcasterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
