import 'package:beacon_broadcaster/beacon_broadcaster.dart';
import 'package:beacon_broadcaster_example/widgets/beacon_item.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'models/beacon.dart';

class BluetoothReadyPage extends StatelessWidget {
  const BluetoothReadyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final bluetoothState = Get.find<Rx<BluetoothState>>();
    final beaconList = Get.find<RxList<Beacon>>();
    final selectedBeaconId = Get.find<RxInt>();
    final isToggle = Get.find<RxBool>();
    return Column(
      children: [
        Obx(() => Text('Bluetooth state: ${bluetoothState.value}')),
        Expanded(
            child: Obx(() => GridView.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 140, childAspectRatio: 1.0),
                  itemCount: beaconList.length,
                  itemBuilder: (context, index) {
                    return Obx(() => Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: BeaconItem(
                              beacon: beaconList[index],
                              isSelected: (beaconList[index].id ==
                                  selectedBeaconId.value),
                              isToggle: isToggle.value),
                        ));
                  },
                )))
      ],
    );
  }
}
