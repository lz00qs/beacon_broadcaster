import 'package:beacon_broadcaster/beacon_broadcaster.dart';
import 'package:beacon_broadcaster_example/models/beacon.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../objectbox.dart';
import 'beacon_edit_dialog.dart';

class _BeaconItemColors {
  static const Color selected = Colors.blue;
  static const Color unselected = Colors.blueGrey;
  static const Color pressed = Color(0xFF1976D2);
}

class BeaconItem extends StatelessWidget {
  final Beacon beacon;
  final bool isSelected;
  final bool isToggle;

  const BeaconItem(
      {super.key,
      required this.beacon,
      required this.isSelected,
      required this.isToggle});

  @override
  Widget build(BuildContext context) {
    final isPressed = false.obs;
    if (isSelected) {
      isPressed.value = true;
    }
    final selectedBeaconId = Get.find<RxInt>();
    final beaconBroadcaster = Get.find<BeaconBroadcaster>();
    return Obx(() => Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: isPressed.value
                ? _BeaconItemColors.pressed
                : isSelected
                    ? _BeaconItemColors.selected
                    : _BeaconItemColors.unselected,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTapDown: (details) async {
                  await beaconBroadcaster.stopAdvertising();
                  if (!isToggle) {
                    isPressed.value = true;
                    await beaconBroadcaster.startAdvertising(
                        uuid: beacon.uuid,
                        major: beacon.major,
                        minor: beacon.minor,
                        txPower: beacon.txPower,
                        advertiseMode: beacon.advertiseMode,
                        advertiseTxPower: beacon.advertiseTxPower);
                  } else {
                    isPressed.value = !isPressed.value;
                    if (isPressed.value) {
                      await beaconBroadcaster.startAdvertising(
                          uuid: beacon.uuid,
                          major: beacon.major,
                          minor: beacon.minor,
                          txPower: beacon.txPower,
                          advertiseMode: beacon.advertiseMode,
                          advertiseTxPower: beacon.advertiseTxPower);
                    } else {
                      await beaconBroadcaster.stopAdvertising();
                    }
                  }
                  selectedBeaconId.value = beacon.id;
                },
                onTapUp: (details) {
                  if (!isToggle) {
                    isPressed.value = false;
                    beaconBroadcaster.stopAdvertising();
                  }
                },
                child: Center(
                  child: Text(
                    beacon.name,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize:
                          Theme.of(context).textTheme.titleSmall?.fontSize,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: IconButton(
                  icon: const Icon(Icons.more_horiz, color: Colors.white),
                  onPressed: () {
                    Get.dialog(AlertDialog(
                      content: const SizedBox(
                        height: 1,
                      ),
                      actions: [
                        TextButton(
                            child: const Text('Edit',
                                style: TextStyle(color: Colors.blue)),
                            onPressed: () async {
                              await Get.dialog(
                                  BeaconEditDialog(beacon: beacon));
                            }),
                        TextButton(
                            child: const Text('Delete',
                                style: TextStyle(color: Colors.red)),
                            onPressed: () async {
                              await Get.dialog(AlertDialog(
                                title: const Text('Delete'),
                                content: const Text(
                                    'Are you sure you want to delete this beacon?'),
                                actions: [
                                  TextButton(
                                      child: const Text('Delete',
                                          style: TextStyle(color: Colors.red)),
                                      onPressed: () {
                                        final beaconList =
                                            Get.find<RxList<Beacon>>();
                                        final selectedBeaconId =
                                            Get.find<RxInt>();
                                        if (selectedBeaconId.value !=
                                            beacon.id) {
                                          beaconList.removeWhere((element) =>
                                              element.id == beacon.id);
                                        } else {
                                          beaconList.remove(beacon);
                                          selectedBeaconId.value =
                                              beaconList.isNotEmpty
                                                  ? beaconList.first.id
                                                  : 0;
                                        }
                                        final objectbox = Get.find<ObjectBox>();
                                        objectbox.beaconBox.remove(beacon.id);
                                        Get.back();
                                        Get.back();
                                      }),
                                  TextButton(
                                      child: const Text('Cancel',
                                          style: TextStyle(color: Colors.blue)),
                                      onPressed: () => Get.back()),
                                ],
                              ));
                            }),
                        TextButton(
                          child: const Text('Cancel'),
                          onPressed: () => Get.back(),
                        ),
                      ],
                    ));
                  }, // 点击编辑图标弹出窗口
                ),
              ),
            ],
          ),
        ));
  }
}
