import 'dart:io';

import 'package:beacon_broadcaster/beacon_broadcaster.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../models/beacon.dart';

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
    final nameProvider = StateProvider<String>((ref) => beacon.name);
    final uuidProvider = StateProvider<String>((ref) => beacon.uuid);
    final majorProvider = StateProvider<int>((ref) => beacon.major);
    final minorProvider = StateProvider<int>((ref) => beacon.minor);
    final txPowerProvider = StateProvider<int>((ref) => beacon.txPower);
    final advertiseModeProvider =
        StateProvider<int>((ref) => beacon.advertiseMode);
    final advertiseTxPowerProvider =
        StateProvider<int>((ref) => beacon.advertiseTxPower);
    return AlertDialog(
      title: const Text('Beacon Info'),
      content: Scrollbar(
          // thumbVisibility: true,
          child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          HookConsumer(builder: (context, ref, child) {
            final nameTextController =
                useTextEditingController(text: beacon.name);
            useEffect(() {
              nameTextController.addListener(() {
                ref.read(nameProvider.notifier).state = nameTextController.text;
              });
              return null;
            }, [nameTextController]);
            return TextField(
              decoration: const InputDecoration(labelText: 'Name'),
              controller: nameTextController,
            );
          }),
          HookConsumer(builder: (context, ref, child) {
            final uuidTextController =
                useTextEditingController(text: beacon.uuid);
            useEffect(() {
              uuidTextController.addListener(() {
                ref.read(uuidProvider.notifier).state = uuidTextController.text;
              });
              return null;
            }, [uuidTextController]);
            return TextField(
              decoration: InputDecoration(
                  labelText: 'UUID',
                  hintText: '550e8400-e29b-41d4-a716-446655440000',
                  errorText: isUuidValid(ref.watch(uuidProvider))
                      ? null
                      : 'Invalid UUID, format: 4-2-2-2-6 hex bytes'),
              controller: uuidTextController,
            );
          }),
          HookConsumer(builder: (context, ref, child) {
            final majorTextController =
                useTextEditingController(text: beacon.major.toString());
            useEffect(() {
              majorTextController.addListener(() {
                ref.read(majorProvider.notifier).state =
                    int.tryParse(majorTextController.text) ?? -1;
              });
              return null;
            }, [majorTextController]);
            return TextField(
              decoration: InputDecoration(
                  labelText: 'Major',
                  errorText: isMajorOrMinorValid(ref.watch(majorProvider))
                      ? null
                      : 'Invalid Major'),
              keyboardType: TextInputType.number,
              // 设置键盘类型为数字
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly, // 只允许输入数字
              ],
              controller: majorTextController,
            );
          }),
          HookConsumer(builder: (context, ref, child) {
            final minorTextController =
                useTextEditingController(text: beacon.minor.toString());
            useEffect(() {
              minorTextController.addListener(() {
                ref.read(minorProvider.notifier).state =
                    int.tryParse(minorTextController.text) ?? -1;
              });
              return null;
            }, [minorTextController]);
            return TextField(
              decoration: InputDecoration(
                  labelText: 'Minor',
                  errorText: isMajorOrMinorValid(ref.watch(minorProvider))
                      ? null
                      : 'Invalid Minor'),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly, // 只允许输入数字
              ],
              controller: minorTextController,
            );
          }),
          HookConsumer(builder: (context, ref, child) {
            final txPowerTextController =
                useTextEditingController(text: beacon.txPower.toString());
            useEffect(() {
              txPowerTextController.addListener(() {
                ref.read(txPowerProvider.notifier).state =
                    int.tryParse(txPowerTextController.text) ?? -1;
              });
              return null;
            }, [txPowerTextController]);
            return TextField(
              decoration: InputDecoration(
                  labelText: 'Tx Power',
                  errorText: isTxPowerValid(ref.watch(txPowerProvider))
                      ? null
                      : 'Invalid Tx Power'),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly, // 只允许输入数字
              ],
              controller: txPowerTextController,
            );
          }),
          Platform.isAndroid
              ? Consumer(builder: (context, ref, child) {
                  final advertiseMode = ref.watch(advertiseModeProvider);
                  return Row(
                    children: [
                      const Text('Advertise Mode: '),
                      const Spacer(),
                      DropdownButton(
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
                            ref.read(advertiseModeProvider.notifier).state =
                                value as int;
                          }),
                    ],
                  );
                })
              : Container(),
          Platform.isAndroid
              ? Consumer(builder: (context, ref, child) {
                  final advertiseTxPower = ref.watch(advertiseTxPowerProvider);
                  return Row(
                    children: [
                      const Text('Advertise Tx Power: '),
                      const Spacer(),
                      DropdownButton(
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
                            ref.read(advertiseTxPowerProvider.notifier).state =
                                value as int;
                          }),
                    ],
                  );
                })
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
        Consumer(builder: (context, ref, child) {
          return TextButton(
            onPressed: () {
              if (_isBeaconParamsValid(
                  ref.watch(uuidProvider),
                  ref.watch(majorProvider),
                  ref.watch(minorProvider),
                  ref.watch(txPowerProvider))) {
                final newBeacon = Beacon(
                  name: ref.watch(nameProvider),
                  uuid: ref.watch(uuidProvider),
                  major: ref.watch(majorProvider),
                  minor: ref.watch(minorProvider),
                  txPower: ref.watch(txPowerProvider),
                  advertiseMode: ref.watch(advertiseModeProvider),
                  advertiseTxPower: ref.watch(advertiseTxPowerProvider),
                );
                newBeacon.id = beacon.id;
                Navigator.of(context).pop(newBeacon);
              }
            },
            child: Text(
              'Save',
              style: TextStyle(
                  color: _isBeaconParamsValid(
                          ref.watch(uuidProvider),
                          ref.watch(majorProvider),
                          ref.watch(minorProvider),
                          ref.watch(txPowerProvider))
                      ? Colors.blue
                      : Colors.grey),
            ),
          );
        }),
      ],
    );
  }
}
