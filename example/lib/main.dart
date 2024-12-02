import 'package:beacon_broadcaster_example/bluetooth_disabled_page.dart';
import 'package:beacon_broadcaster_example/bluetooth_unknown_page.dart';
import 'package:beacon_broadcaster_example/widgets/beacon_edit_dialog.dart';
import 'package:flutter/material.dart';

import 'package:beacon_broadcaster/beacon_broadcaster.dart';
import 'package:get/get.dart';

import 'bluetooth_ready_page.dart';
import 'bluetooth_unauthorized_page.dart';
import 'bluetooth_unsupported_page.dart';
import 'models/beacon.dart';
import 'objectbox.dart';

late ObjectBox objectbox;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  objectbox = await ObjectBox.create();
  final beaconList = (objectbox.beaconBox.getAll()).obs;
  if (beaconList.isEmpty) {
    final beacon = Beacon(
        name: 'Test Beacon',
        uuid: '550e8400-e29b-41d4-a716-446655440000',
        major: 0x66,
        minor: 0x99,
        txPower: 0);
    beaconList.add(beacon);
    objectbox.beaconBox.put(beacon);
  }
  final selectedBeaconId = beaconList.first.id.obs;
  Get.put(selectedBeaconId);
  Get.put(beaconList);
  Get.put(objectbox);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Beacon Tools'),
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
    final isToggle = Get.put(false.obs);
    beaconBroadcaster.bluetoothState.asBroadcastStream().listen((state) {
      bluetoothState.value = state;
    });
    Get.put(bluetoothState);
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
              onPressed: () {
                Get.dialog(BeaconEditDialog(
                    beacon: Beacon(
                        name: 'New Beacon',
                        uuid: '550e8400-e29b-41d4-a716-446655440000',
                        major: 0x66,
                        minor: 0x99,
                        txPower: 0)));
              },
              icon: const Icon(Icons.add)),
          const SizedBox(
            width: 8,
          ),
          const Text('Toggle:'),
          Obx(
            () => Switch(
              value: isToggle.value,
              onChanged: (value) => isToggle.value = value,
            ),
          ),
        ],
      ),
      body: Obx(() {
        switch (bluetoothState.value) {
          case BluetoothState.unknown:
            return const BluetoothUnknownPage();
          case BluetoothState.off:
            return const BluetoothDisabledPage();
          case BluetoothState.unsupported:
            return const BluetoothUnsupportedPage();
          case BluetoothState.unauthorized:
            return const BluetoothUnauthorizedPage();
          default:
            return const BluetoothReadyPage();
          // return const BluetoothUnsupportedPage();
        }
      }),
    );
  }
}
