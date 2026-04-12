# beacon_broadcaster

Broadcast iBeacon packets from Flutter on Android and iOS.

## Features

- Broadcasts iBeacon packets on Android and iOS.
- Exposes Bluetooth state as a real-time stream.
- Starts and stops advertising from Dart.
- Supports Android advertising mode and transmit power settings.
- Includes native debug logging hooks.

## Installation

Add the dependency to your `pubspec.yaml`:

```yaml
dependencies:
  beacon_broadcaster: ^0.0.1
```

Then run:

```bash
flutter pub get
```

## Quick Start

```dart
import 'dart:async';

import 'package:beacon_broadcaster/beacon_broadcaster.dart';

final broadcaster = BeaconBroadcaster();

Future<void> startBeacon() async {
  broadcaster.setLogLevel(LogLevels.debug);

  final subscription = broadcaster.bluetoothState.listen((state) {
    print('Bluetooth state: $state');
  });

  await broadcaster.checkBluetoothState();

  await broadcaster.startAdvertising(
    uuid: '550e8400-e29b-41d4-a716-446655440000',
    major: 1,
    minor: 2,
    txPower: -59,
  );

  await Future<void>.delayed(const Duration(seconds: 5));
  await broadcaster.stopAdvertising();

  await subscription.cancel();
}
```

## Public API

### `BeaconBroadcaster`

#### `BeaconBroadcaster()`

Creates the plugin instance and initializes the native log listener once.

#### `void setLogLevel(LogLevels level)`

Controls which native log messages are printed in Flutter debug mode.

Available values:

- `LogLevels.debug`
- `LogLevels.info`
- `LogLevels.warning`
- `LogLevels.error`

#### `Future<String?> getPlatformVersion()`

Returns the native platform version string.

Examples:

- Android: `Android 14`
- iOS: `iOS 17.5`

#### `Future<void> checkBluetoothState()`

Triggers an immediate Bluetooth state check on the native side.

Use this when you want the current state pushed to the `bluetoothState` stream immediately. The plugin is stream-based; this is not a polling getter.

#### `Stream<BluetoothState> get bluetoothState`

Returns a real-time stream of Bluetooth and advertising state updates.

Possible values:

- `BluetoothState.unknown`
- `BluetoothState.unsupported`
- `BluetoothState.unauthorized`
- `BluetoothState.ready`
- `BluetoothState.beaconing`
- `BluetoothState.off`
- `BluetoothState.error`

Typical meanings:

- `unknown`: Native state is not yet resolved.
- `unsupported`: Device does not support the required BLE/iBeacon features.
- `unauthorized`: Required platform permission is missing.
- `ready`: Bluetooth is available and the plugin is ready to advertise.
- `beaconing`: Advertising has started successfully.
- `off`: Bluetooth is powered off.
- `error`: Advertising failed to start.

#### `Future<int> startAdvertising({...})`

Starts iBeacon advertising.

Parameters:

- `uuid`: Required. Standard 128-bit UUID string, for example `550e8400-e29b-41d4-a716-446655440000`.
- `major`: Required. Range `0..65535`.
- `minor`: Required. Range `0..65535`.
- `txPower`: Required. Range `-127..127`.
- `advertiseMode`: Optional Android-only setting.
- `advertiseTxPower`: Optional Android-only setting.

Return value:

- `0`: Request accepted.
- `-1`: Native-side validation or startup failed.

Defaults:

```dart
advertiseMode: AndroidBleAdvertiseSettings.advertiseModeBalanced
advertiseTxPower: AndroidBleAdvertiseSettings.advertiseTxPowerMedium
```

Android advertising constants:

- `AndroidBleAdvertiseSettings.advertiseModeLowPower`
- `AndroidBleAdvertiseSettings.advertiseModeBalanced`
- `AndroidBleAdvertiseSettings.advertiseModeLowLatency`
- `AndroidBleAdvertiseSettings.advertiseTxPowerUltraLow`
- `AndroidBleAdvertiseSettings.advertiseTxPowerLow`
- `AndroidBleAdvertiseSettings.advertiseTxPowerMedium`
- `AndroidBleAdvertiseSettings.advertiseTxPowerHigh`

Notes:

- `advertiseMode` and `advertiseTxPower` are ignored on iOS.
- On Android, `BluetoothState.beaconing` is emitted from the native advertise callback after startup succeeds.
- On iOS, `BluetoothState.beaconing` is emitted immediately after `startAdvertising()`.

#### `Future<int> stopAdvertising()`

Stops iBeacon advertising.

Return value:

- `0`: Stop request accepted.
- `-1`: Native-side validation failed.

### Validation helpers

These top-level helpers are also publicly exported:

#### `bool isUuidValid(String uuid)`

Returns `true` when the UUID matches the canonical iBeacon UUID format.

#### `bool isMajorOrMinorValid(int value)`

Returns `true` when the value is in the `0..65535` range.

#### `bool isTxPowerValid(int value)`

Returns `true` when the value is in the `-127..127` range.

#### `Uint8List uuidStringToBytes(String uuid)`

Converts a UUID string into a 16-byte array. Throws `ArgumentError` when the UUID is invalid.

## Usage Patterns

### Listen for state changes

```dart
final broadcaster = BeaconBroadcaster();

final subscription = broadcaster.bluetoothState.listen((state) {
  switch (state) {
    case BluetoothState.ready:
      print('Ready to advertise');
      break;
    case BluetoothState.beaconing:
      print('Advertising');
      break;
    case BluetoothState.off:
      print('Bluetooth is off');
      break;
    case BluetoothState.unauthorized:
      print('Missing permission');
      break;
    default:
      print('State: $state');
  }
});

await broadcaster.checkBluetoothState();
```

### Start and stop advertising

```dart
final broadcaster = BeaconBroadcaster();

await broadcaster.startAdvertising(
  uuid: '550e8400-e29b-41d4-a716-446655440000',
  major: 100,
  minor: 200,
  txPower: -59,
  advertiseMode: AndroidBleAdvertiseSettings.advertiseModeLowLatency,
  advertiseTxPower: AndroidBleAdvertiseSettings.advertiseTxPowerHigh,
);

await broadcaster.stopAdvertising();
```

### Validate beacon parameters before calling native code

```dart
const uuid = '550e8400-e29b-41d4-a716-446655440000';

if (!isUuidValid(uuid)) {
  throw Exception('Invalid UUID');
}

if (!isMajorOrMinorValid(1) || !isMajorOrMinorValid(2)) {
  throw Exception('Invalid major/minor');
}

if (!isTxPowerValid(-59)) {
  throw Exception('Invalid txPower');
}
```

## Android Configuration

The plugin declares these permissions in the plugin manifest:

- `android.permission.BLUETOOTH` with `maxSdkVersion="30"`
- `android.permission.BLUETOOTH_ADMIN` with `maxSdkVersion="30"`
- `android.permission.BLUETOOTH_ADVERTISE`

Your app should still declare the permissions it needs in its own `AndroidManifest.xml`.

### Required manifest entries

Add the following to `android/app/src/main/AndroidManifest.xml` in the host app:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission
        android:name="android.permission.BLUETOOTH"
        android:maxSdkVersion="30" />
    <uses-permission
        android:name="android.permission.BLUETOOTH_ADMIN"
        android:maxSdkVersion="30" />
    <uses-permission android:name="android.permission.BLUETOOTH_ADVERTISE" />
    <uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />

    <application
        android:label="your_app"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        ...
    </application>
</manifest>
```

### Android runtime permissions

This plugin does not request runtime permissions for you.

You must request the required permissions in your app before advertising:

- Android 12 and above:
  - `BLUETOOTH_ADVERTISE`
  - `BLUETOOTH_CONNECT`
- Android 11 and below:
  - Legacy Bluetooth permissions are checked through the manifest declarations above.

Important platform behavior:

- If `BLUETOOTH_ADVERTISE` is missing, the plugin emits `BluetoothState.unauthorized`.
- On Android 12 and above, if `BLUETOOTH_CONNECT` is missing, `checkBluetoothState()` may still report `BluetoothState.ready`, but adapter state change broadcasts can still depend on connect permission.
- If Bluetooth is off on Android 11 and below, advertising fails and the plugin emits `BluetoothState.off`.

## iOS Configuration

### Required `Info.plist` entries

Add the following keys to `ios/Runner/Info.plist` in the host app:

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Bluetooth is required to broadcast iBeacon signals.</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>Bluetooth is required to broadcast iBeacon signals.</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>Used to broadcast iBeacon signals while the app is in use.</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Used to broadcast and monitor iBeacon signals.</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>Used to broadcast iBeacon signals in the background.</string>
```

Adjust the strings to match your app's real behavior.

### iOS permission notes

- This plugin does not request Bluetooth or location permission dialogs for you.
- You are responsible for requesting any required permissions in the host app.
- The plugin uses `CBPeripheralManager` for Bluetooth state and `CLBeaconRegion` to build iBeacon payload data.

### iOS simulator behavior

On the iOS simulator:

- `checkBluetoothState()` reports `ready`
- `startAdvertising()` returns success
- `stopAdvertising()` returns success

The simulator does not perform real BLE beacon broadcasting.

## Platform Notes

### Android

- Uses `BluetoothAdapter` and BLE advertising APIs.
- Emits Bluetooth state updates through a native `EventChannel`.
- Listens for adapter power changes and pushes updates in real time.

### iOS

- Uses `CBPeripheralManager` to monitor Bluetooth state.
- Uses `CLBeaconRegion.peripheralData(...)` to generate iBeacon payload data.
- Emits Bluetooth state updates through a native `EventChannel`.

## Error Handling

`startAdvertising()` returns a failed future for invalid Dart-side arguments such as:

- Invalid UUID format
- Invalid `major`
- Invalid `minor`
- Invalid `txPower`
- Invalid Android advertising constants

Native failures usually return `-1` or emit a new Bluetooth state such as:

- `BluetoothState.unauthorized`
- `BluetoothState.off`
- `BluetoothState.unsupported`
- `BluetoothState.error`

## Complete Example

```dart
import 'dart:async';

import 'package:beacon_broadcaster/beacon_broadcaster.dart';

class BeaconService {
  BeaconService() {
    _broadcaster.setLogLevel(LogLevels.debug);
    _subscription = _broadcaster.bluetoothState.listen((state) {
      print('Bluetooth state changed: $state');
    });
  }

  final BeaconBroadcaster _broadcaster = BeaconBroadcaster();
  StreamSubscription<BluetoothState>? _subscription;

  Future<void> init() async {
    await _broadcaster.checkBluetoothState();
  }

  Future<void> start() async {
    await _broadcaster.startAdvertising(
      uuid: '550e8400-e29b-41d4-a716-446655440000',
      major: 1,
      minor: 2,
      txPower: -59,
      advertiseMode: AndroidBleAdvertiseSettings.advertiseModeBalanced,
      advertiseTxPower: AndroidBleAdvertiseSettings.advertiseTxPowerMedium,
    );
  }

  Future<void> stop() async {
    await _broadcaster.stopAdvertising();
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
  }
}
```

## Limitations

- The plugin does not request permissions automatically.
- Android advertising parameters are Android-only.
- Real broadcasting cannot be validated on the iOS simulator.
