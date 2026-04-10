# beacon_broadcaster

Broadcast iBeacon packets from Flutter on Android and iOS.

## Features

- Checks Bluetooth state through a stream.
- Starts and stops iBeacon advertising.
- Supports Android advertise mode and transmit power settings.

## Usage

```dart
final broadcaster = BeaconBroadcaster();

await broadcaster.checkBluetoothState();

await broadcaster.startAdvertising(
  uuid: '550e8400-e29b-41d4-a716-446655440000',
  major: 1,
  minor: 2,
  txPower: -59,
);
```

## Notes

- `major` and `minor` support the full `0..65535` iBeacon range.
- The plugin does not request runtime permissions for you.
- Android apps should request `BLUETOOTH_ADVERTISE`, and on Android 12+ also `BLUETOOTH_CONNECT`.

