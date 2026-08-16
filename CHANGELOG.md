## 0.2.4

- Make repeated stops and rapid payload replacements idempotent so inactive
  native advertising sessions are not stopped again.
- Isolate Android advertising callbacks and auto-stop timers per session so a
  stale callback or timer cannot overwrite or stop a newer broadcast.
- Report iOS advertising success and failure from the Core Bluetooth delegate
  callback, and ignore stale results from superseded start requests.
- Clear advertising state and timers when Bluetooth turns off, and clean up
  Android advertising and state listeners when the Flutter engine detaches.
- Refresh the setup guide and example permissions for the iOS 15.0 deployment
  target, including the foreground-only iBeacon broadcasting limitation.

## 0.2.3

- Migrate the Android plugin and example app for Built-in Kotlin compatibility.
- Raise the minimum supported SDK versions to Flutter 3.44 and Dart 3.12.

## 0.2.2

- Keep the package, iOS podspec, and example dependency metadata on the same version.
- Add iOS Swift Package Manager support while retaining CocoaPods compatibility.
- Raise the minimum iOS deployment target to 15.0.
- Compile and target Android API 36, using AGP 8.13.1, Gradle 8.14, and Kotlin 2.2.20 to meet the latest Google Play submission requirement.
- Replace the example's ObjectBox storage with a lightweight JSON repository so all of its iOS plugins support Swift Package Manager.

## 0.2.1

- Fix iOS Bluetooth state checks to rely on `CBPeripheralManager` instead of Core Location region monitoring availability.
- Avoid reporting location or region monitoring unavailability as unsupported Bluetooth when broadcasting iBeacon packets.
- Improve public API documentation coverage for pub.dev scoring.

## 0.2.0

- Add optional `durationMs` support to stop advertising automatically after a specified duration on Android and iOS.
- Make repeated advertising starts more robust by stopping any existing session before starting a new one.
- Expand Dart, method-channel, and example test coverage.

## 0.1.1

- Raise Android Java and Kotlin compilation targets from 8 to 17.
- Remove deprecated source/target compatibility warnings during Android builds.

## 0.1.0

- Initial public release.
- Broadcast iBeacon packets on Android and iOS.
- Expose Bluetooth state through a real-time stream.
- Support starting and stopping advertising from Flutter.
- Add Android advertising mode and transmit power options.
- Document all public APIs and Android/iOS permission configuration.
