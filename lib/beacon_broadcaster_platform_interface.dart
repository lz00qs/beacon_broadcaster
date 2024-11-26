import 'package:beacon_broadcaster/beacon_broadcaster.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'beacon_broadcaster_channels.dart';

abstract class BeaconBroadcasterPlatform extends PlatformInterface {
  /// Constructs a BeaconBroadcasterPlatform.
  BeaconBroadcasterPlatform() : super(token: _token);

  static final Object _token = Object();

  static BeaconBroadcasterPlatform _instance = ChannelsBeaconBroadcaster();

  /// The default instance of [BeaconBroadcasterPlatform] to use.
  ///
  /// Defaults to [ChannelsBeaconBroadcaster].
  static BeaconBroadcasterPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [BeaconBroadcasterPlatform] when
  /// they register themselves.
  static set instance(BeaconBroadcasterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Stream<BluetoothState> get bluetoothState {
    throw UnimplementedError('bluetoothState() has not been implemented.');
  }

  Stream<String> get nativeLog {
    throw UnimplementedError('log() has not been implemented.');
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<void> checkBluetoothState() {
    throw UnimplementedError('checkBluetoothState() has not been implemented.');
  }
}
