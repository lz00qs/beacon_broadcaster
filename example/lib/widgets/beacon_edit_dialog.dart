import 'dart:io';

import 'package:beacon_broadcaster/beacon_broadcaster.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/beacon.dart';

bool _isBeaconParamsValid(String uuid, int major, int minor, int txPower) {
  return isUuidValid(uuid) &&
      isMajorOrMinorValid(major) &&
      isMajorOrMinorValid(minor) &&
      isTxPowerValid(txPower);
}

class BeaconEditDialog extends StatefulWidget {
  final Beacon beacon;

  const BeaconEditDialog({super.key, required this.beacon});

  @override
  State<BeaconEditDialog> createState() => _BeaconEditDialogState();
}

class _BeaconEditDialogState extends State<BeaconEditDialog> {
  late final TextEditingController nameController;
  late final TextEditingController uuidController;
  late final TextEditingController majorController;
  late final TextEditingController minorController;
  late final TextEditingController txPowerController;

  late String name;
  late String uuid;
  late int major;
  late int minor;
  late int txPower;
  late int advertiseMode;
  late int advertiseTxPower;

  bool get isValid => _isBeaconParamsValid(uuid, major, minor, txPower);

  @override
  void initState() {
    super.initState();
    name = widget.beacon.name;
    uuid = widget.beacon.uuid;
    major = widget.beacon.major;
    minor = widget.beacon.minor;
    txPower = widget.beacon.txPower;
    advertiseMode = widget.beacon.advertiseMode;
    advertiseTxPower = widget.beacon.advertiseTxPower;

    nameController = TextEditingController(text: name);
    uuidController = TextEditingController(text: uuid);
    majorController = TextEditingController(text: major.toString());
    minorController = TextEditingController(text: minor.toString());
    txPowerController = TextEditingController(text: txPower.toString());
  }

  @override
  void dispose() {
    nameController.dispose();
    uuidController.dispose();
    majorController.dispose();
    minorController.dispose();
    txPowerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Beacon Info'),
      content: Scrollbar(
          child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            decoration: const InputDecoration(labelText: 'Name'),
            controller: nameController,
            onChanged: (value) => setState(() {
              name = value;
            }),
          ),
          TextField(
            decoration: InputDecoration(
                labelText: 'UUID',
                hintText: '550e8400-e29b-41d4-a716-446655440000',
                errorText: isUuidValid(uuid)
                    ? null
                    : 'Invalid UUID, format: 4-2-2-2-6 hex bytes'),
            controller: uuidController,
            onChanged: (value) => setState(() {
              uuid = value;
            }),
          ),
          TextField(
            decoration: InputDecoration(
                labelText: 'Major',
                errorText: isMajorOrMinorValid(major)
                    ? null
                    : 'Invalid Major'),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            controller: majorController,
            onChanged: (value) => setState(() {
              major = int.tryParse(value) ?? -1;
            }),
          ),
          TextField(
            decoration: InputDecoration(
                labelText: 'Minor',
                errorText: isMajorOrMinorValid(minor)
                    ? null
                    : 'Invalid Minor'),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            controller: minorController,
            onChanged: (value) => setState(() {
              minor = int.tryParse(value) ?? -1;
            }),
          ),
          TextField(
            decoration: InputDecoration(
                labelText: 'Tx Power',
                errorText: isTxPowerValid(txPower)
                    ? null
                    : 'Invalid Tx Power'),
            keyboardType: const TextInputType.numberWithOptions(signed: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^-?\d*$')),
            ],
            controller: txPowerController,
            onChanged: (value) => setState(() {
              txPower = int.tryParse(value) ?? -1;
            }),
          ),
          Platform.isAndroid
              ? Row(
                  children: [
                    const Text('Advertise Mode: '),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButton<int>(
                          isExpanded: true,
                          value: advertiseMode,
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
                              setState(() {
                                advertiseMode = value;
                              });
                            }
                          }),
                    ),
                  ],
                )
              : Container(),
          Platform.isAndroid
              ? Row(
                  children: [
                    const Text('Advertise Tx Power: '),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButton<int>(
                          isExpanded: true,
                          value: advertiseTxPower,
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
                              setState(() {
                                advertiseTxPower = value;
                              });
                            }
                          }),
                    ),
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
                name: name,
                uuid: uuid,
                major: major,
                minor: minor,
                txPower: txPower,
                advertiseMode: advertiseMode,
                advertiseTxPower: advertiseTxPower,
              );
              newBeacon.id = widget.beacon.id;
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
