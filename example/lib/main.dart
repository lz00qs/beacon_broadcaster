import 'package:beacon_broadcaster_example/bluetooth_disabled_page.dart';
import 'package:beacon_broadcaster_example/bluetooth_unknown_page.dart';
import 'package:flutter/material.dart';

import 'package:beacon_broadcaster/beacon_broadcaster.dart';
import 'package:get/get.dart';

import 'bluetooth_unauthorized_page.dart';
import 'bluetooth_unsupported_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Beacon Broadcaster Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Beacon Broadcaster Example'),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final beaconBroadcaster = Get.put(BeaconBroadcaster());
    final bluetoothState = BluetoothState.unknown.obs;
    bluetoothState.bindStream(beaconBroadcaster.bluetoothState);
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(child: Obx(
        () {
          switch (bluetoothState.value) {
            case BluetoothState.unknown:
              return const BluetoothUnknownPage();
            case BluetoothState.unsupported:
              return const BluetoothUnsupportedPage();
            case BluetoothState.unauthorized:
              return const BluetoothUnauthorizedPage();
            case BluetoothState.off:
              return const BluetoothDisabledPage();
            case BluetoothState.ready:
              return const Center(
                child: Text('Bluetooth is ready'),
              );
            default:
              return const BluetoothUnknownPage();
          }
        },
      )),
    );
  }
}
