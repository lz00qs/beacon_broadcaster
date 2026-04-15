# beacon_broadcaster_example

Demonstrates how to use the beacon_broadcaster plugin.

## Auto Stop Demo

When the example app is in toggle mode, the ready page shows an `Auto stop duration`
selector. Pick `3s`, `5s`, `10s`, or `Continuous`, then tap a beacon tile.

The example forwards the selected value to:

```dart
await beaconBroadcaster.startAdvertising(
  uuid: beacon.uuid,
  major: beacon.major,
  minor: beacon.minor,
  txPower: beacon.txPower,
  durationMs: selectedDurationMs,
  advertiseMode: beacon.advertiseMode,
  advertiseTxPower: beacon.advertiseTxPower,
);
```

If a duration is selected, the plugin stops advertising automatically when the
timer expires.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
