import 'dart:io';

import 'package:beacon_broadcaster/beacon_broadcaster.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../models/beacon.dart';

bool _isBeaconParamsValid(String uuid, int major, int minor, int txPower) {
  return isUuidValid(uuid) &&
      isMajorOrMinorValid(major) &&
      isMajorOrMinorValid(minor) &&
      isTxPowerValid(txPower);
}

class BeaconEditDialog extends HookWidget {
  final Beacon beacon;

  const BeaconEditDialog({super.key, required this.beacon});

  @override
  Widget build(BuildContext context) {
    final nameController = useTextEditingController(text: beacon.name);
    final uuidController = useTextEditingController(text: beacon.uuid);
    final majorController =
        useTextEditingController(text: beacon.major.toString());
    final minorController =
        useTextEditingController(text: beacon.minor.toString());
    final txPowerController =
        useTextEditingController(text: beacon.txPower.toString());

    final name = useState(beacon.name);
    final uuid = useState(beacon.uuid);
    final major = useState(beacon.major);
    final minor = useState(beacon.minor);
    final txPower = useState(beacon.txPower);
    final advertiseMode = useState(beacon.advertiseMode);
    final advertiseTxPower = useState(beacon.advertiseTxPower);
    final isValid =
        _isBeaconParamsValid(uuid.value, major.value, minor.value, txPower.value);
    return AlertDialog(
      title: const Text('Beacon Info'),
      content: Scrollbar(
          // thumbVisibility: true,
          child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            decoration: const InputDecoration(labelText: 'Name'),
            controller: nameController,
            onChanged: (value) => name.value = value,
          ),
          TextField(
            decoration: InputDecoration(
                labelText: 'UUID',
                hintText: '550e8400-e29b-41d4-a716-446655440000',
                errorText: isUuidValid(uuid.value)
                    ? null
                    : 'Invalid UUID, format: 4-2-2-2-6 hex bytes'),
            controller: uuidController,
            onChanged: (value) => uuid.value = value,
          ),
          TextField(
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
            controller: majorController,
            onChanged: (value) => major.value = int.tryParse(value) ?? -1,
          ),
          TextField(
            decoration: InputDecoration(
                labelText: 'Minor',
                errorText: isMajorOrMinorValid(minor.value)
                    ? null
                    : 'Invalid Minor'),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly, // 只允许输入数字
            ],
            controller: minorController,
            onChanged: (value) => minor.value = int.tryParse(value) ?? -1,
          ),
          TextField(
            decoration: InputDecoration(
                labelText: 'Tx Power',
                errorText: isTxPowerValid(txPower.value)
                    ? null
                    : 'Invalid Tx Power'),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly, // 只允许输入数字
            ],
            controller: txPowerController,
            onChanged: (value) => txPower.value = int.tryParse(value) ?? -1,
          ),
          Platform.isAndroid
              ? Row(
                  children: [
                    const Text('Advertise Mode: '),
                    const Spacer(),
                    DropdownButton<int>(
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
                          if (value != null) {
                            advertiseMode.value = value;
                          }
                        }),
                  ],
                )
              : Container(),
          Platform.isAndroid
              ? Row(
                  children: [
                    const Text('Advertise Tx Power: '),
                    const Spacer(),
                    DropdownButton<int>(
                        value: advertiseTxPower.value,
                        items: const [
                          DropdownMenuItem(
                            value: AndroidBleAdvertiseSettings
                                .advertiseTxPowerUltraLow,
                            child: Text('Ultra Low Power'),
                          ),
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
                          if (value != null) {
                            advertiseTxPower.value = value;
                          }
                        }),
                  ],
                )
              : Container(),
        ]),
      )),
      actions: [
        TextButton(
          child: const Text(
            'Cancel',
            style: TextStyle(color: Colors.red),
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          onPressed: () {
            if (isValid) {
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
              Navigator.of(context).pop(newBeacon);
            }
          },
          child: Text(
            'Save',
            style: TextStyle(color: isValid ? Colors.blue : Colors.grey),
          ),
        ),
      ],
    );
  }
}
