import 'dart:typed_data';

import 'package:beacon_broadcaster/beacon_broadcaster.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'beacon_broadcaster_channels.dart';

/// Platform interface for beacon broadcaster implementations.
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

  /// The minimum native log level printed by the default method-channel layer.
  static var logLevel = LogLevels.debug;

  /// Streams Bluetooth and advertising state changes.
  Stream<BluetoothState> get bluetoothState {
    throw UnimplementedError('bluetoothState() has not been implemented.');
  }

  /// Returns a platform-specific version string.
  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  /// Requests that the platform emits its current Bluetooth state.
  Future<void> checkBluetoothState() {
    throw UnimplementedError('checkBluetoothState() has not been implemented.');
  }

  /// Initializes platform log forwarding.
  void initializeLogger() {
    throw UnimplementedError('initializeLogger() has not been implemented.');
  }

  /// Starts or replaces a platform-specific iBeacon advertising session.
  Future<int> startAdvertising(
      {required Uint8List uuid,
      required int major,
      required int minor,
      required int txPower,
      required int? durationMs,
      required int advertiseMode,
      required int advertiseTxPower}) {
    throw UnimplementedError('startAdvertising() has not been implemented.');
  }

  /// Idempotently stops the active platform-specific advertising session.
  Future<int> stopAdvertising() {
    throw UnimplementedError('stopAdvertising() has not been implemented.');
  }
}
