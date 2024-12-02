import 'dart:io';

import 'package:beacon_broadcaster/beacon_broadcaster.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../models/beacon.dart';
import '../objectbox.dart';

bool _isBeaconParamsValid(String uuid, int major, int minor, int txPower) {
  return isUuidValid(uuid) &&
      isMajorOrMinorValid(major) &&
      isMajorOrMinorValid(minor) &&
      isTxPowerValid(txPower);
}

class BeaconEditDialog extends StatelessWidget {
  final Beacon beacon;

  const BeaconEditDialog({super.key, required this.beacon});

  @override
  Widget build(BuildContext context) {
    final name = beacon.name.obs;
    final uuid = beacon.uuid.obs;
    final uuidTextController = TextEditingController(text: uuid.value);
    final major = beacon.major.obs;
    final majorTextController =
        TextEditingController(text: major.value.toString());
    final minor = beacon.minor.obs;
    final minorTextController =
        TextEditingController(text: minor.value.toString());
    final txPower = beacon.txPower.obs;
    final txPowerTextController =
        TextEditingController(text: txPower.value.toString());
    final advertiseMode = beacon.advertiseMode.obs;
    final advertiseTxPower = beacon.advertiseTxPower.obs;

    return AlertDialog(
      title: const Text('Beacon Info'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            decoration: const InputDecoration(labelText: 'Name'),
            controller: TextEditingController(text: name.value),
            onChanged: (value) => name.value = value,
          ),
          Obx(
            () => TextField(
              decoration: InputDecoration(
                  labelText: 'UUID',
                  hintText: '550e8400-e29b-41d4-a716-446655440000',
                  errorText: isUuidValid(uuid.value)
                      ? null
                      : 'Invalid UUID, format: 4-2-2-2-6 hex bytes'),
              controller: uuidTextController,
              onChanged: (value) {
                uuid.value = value;
              },
            ),
          ),
          Obx(
            () => TextField(
              decoration: InputDecoration(
                  labelText: 'Major',
                  errorText: isMajorOrMinorValid(major.value)
                      ? null
                      : 'Invalid Major'),
              keyboardType: TextInputType.number,
              // 设置键盘类型为数字
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly, // 只允许输入数字
              ],
              controller: majorTextController,
              onChanged: (value) {
                if (value == '') {
                  major.value = -1;
                } else {
                  major.value = int.parse(value);
                }
              },
            ),
          ),
          Obx(
            () => TextField(
              decoration: InputDecoration(
                  labelText: 'Minor',
                  errorText: isMajorOrMinorValid(minor.value)
                      ? null
                      : 'Invalid Minor'),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly, // 只允许输入数字
              ],
              controller: minorTextController,
              onChanged: (value) {
                if (value == '') {
                  minor.value = -1;
                } else {
                  minor.value = int.parse(value);
                }
              },
            ),
          ),
          Obx(
            () => TextField(
              decoration: InputDecoration(
                  labelText: 'Tx Power',
                  errorText: isTxPowerValid(txPower.value)
                      ? null
                      : 'Invalid Tx Power'),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly, // 只允许输入数字
              ],
              controller: txPowerTextController,
              onChanged: (value) {
                if (value == '') {
                  txPower.value = -1;
                } else {
                  txPower.value = int.parse(value);
                }
              },
            ),
          ),
          Platform.isAndroid
              ? Row(
                  children: [
                    const Text('Advertise Mode: '),
                    const Spacer(),
                    Obx(
                      () => DropdownButton(
                          value: advertiseMode.value,
                          items: const [
                            DropdownMenuItem(
                              value: AndroidBleAdvertiseSettings
                                  .advertiseModeLowLatency,
                              child: Text('Low Latency'),
                            ),
                            DropdownMenuItem(
                              value: AndroidBleAdvertiseSettings
                                  .advertiseModeBalanced,
                              child: Text('Balanced'),
                            ),
                            DropdownMenuItem(
                              value: AndroidBleAdvertiseSettings
                                  .advertiseModeLowPower,
                              child: Text('Low Power'),
                            ),
                          ],
                          onChanged: (value) {
                            advertiseMode.value = value as int;
                          }),
                    )
                  ],
                )
              : Container(),
          Platform.isAndroid
              ? Row(
                  children: [
                    const Text('Advertise Tx Power: '),
                    const Spacer(),
                    Obx(
                      () => DropdownButton(
                          value: advertiseTxPower.value,
                          items: const [
                            DropdownMenuItem(
                              value: AndroidBleAdvertiseSettings
                                  .advertiseTxPowerLow,
                              child: Text('Low Power'),
                            ),
                            DropdownMenuItem(
                              value: AndroidBleAdvertiseSettings
                                  .advertiseTxPowerMedium,
                              child: Text('Medium Power'),
                            ),
                            DropdownMenuItem(
                              value: AndroidBleAdvertiseSettings
                                  .advertiseTxPowerHigh,
                              child: Text('High Power'),
                            ),
                          ],
                          onChanged: (value) {
                            advertiseTxPower.value = value as int;
                          }),
                    )
                  ],
                )
              : Container()
        ],
      ),
      actions: [
        TextButton(
          child: const Text(
            'Cancel',
            style: TextStyle(color: Colors.red),
          ),
          onPressed: () {
            Get.back();
          },
        ),
        TextButton(
          child: Obx(
            () => Text(
              'Save',
              style: TextStyle(
                  color: _isBeaconParamsValid(
                          uuid.value, major.value, minor.value, txPower.value)
                      ? Colors.blue
                      : Colors.grey),
            ),
          ),
          onPressed: () {
            if (_isBeaconParamsValid(
                uuid.value, major.value, minor.value, txPower.value)) {
              final newBeacon = Beacon(
                name: name.value,
                uuid: uuid.value,
                major: major.value,
                minor: minor.value,
                txPower: txPower.value,
                advertiseMode: advertiseMode.value,
                advertiseTxPower: advertiseTxPower.value,
              );
              newBeacon.id = beacon.id;
              final objectbox = Get.find<ObjectBox>();
              objectbox.beaconBox.put(newBeacon);
              final beaconList = Get.find<RxList<Beacon>>();
              if (beaconList.contains(beacon)) {
                final index = beaconList.indexOf(beacon);
                beaconList[index] = newBeacon;
              } else {
                beaconList.add(newBeacon);
              }
              Get.back(result: newBeacon);
              Get.back(result: newBeacon);
            }
          },
        ),
      ],
    );
  }
}
