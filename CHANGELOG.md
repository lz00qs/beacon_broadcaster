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
