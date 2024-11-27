import 'package:beacon_broadcaster/beacon_broadcaster.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BluetoothReadyPage extends StatelessWidget {
  final bool isBeaconing;

  const BluetoothReadyPage({super.key, required this.isBeaconing});

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Bluetooth is ready'),
        const SizedBox(height: 50),
        ElevatedButton(
          onPressed: () async {
            if (isBeaconing) {
              await Get.find<BeaconBroadcaster>().stopAdvertising();
            } else {
              await Get.find<BeaconBroadcaster>().startAdvertising(
                  uuid: '550e8400-e29b-41d4-a716-446655440000',
                  major: 0x66,
                  minor: 0x99,
                  txPower: 0,
                  advertiseMode:
                      AndroidBleAdvertiseSettings.advertiseModeLowLatency,
                  advertiseTxPower:
                      AndroidBleAdvertiseSettings.advertiseTxPowerHigh);
            }
          },
          child: isBeaconing
              ? const Text('Stop Broadcasting')
              : const Text('Start Broadcasting'),
        )
      ],
    ));
  }
}
