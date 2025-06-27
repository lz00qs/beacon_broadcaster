import 'package:beacon_broadcaster_example/models/beacon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../objectbox.dart';
import '../providers.dart';
import 'beacon_edit_dialog.dart';

class _BeaconItemColors {
  static const Color selected = Colors.blue;

  // static const Color unselected = Colors.blueGrey;
  static const Color pressed = Color(0xFF1976D2);
}

class BeaconItem extends HookConsumerWidget {
  final Beacon beacon;

  final bool isToggle;
  final int id;

  const BeaconItem(
      {super.key,
      required this.id,
      required this.beacon,
      required this.isToggle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final beaconBroadcaster = ref.watch(beaconBroadcasterProvider);
    final isPressed = useState(false);
    ref.watch(beaconListProvider);
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: isPressed.value
            ? _BeaconItemColors.pressed
            : _BeaconItemColors.selected,
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
                await beaconBroadcaster.stopAdvertising();
                await beaconBroadcaster.startAdvertising(
                    uuid: beacon.uuid,
                    major: beacon.major,
                    minor: beacon.minor,
                    txPower: beacon.txPower,
                    advertiseMode: beacon.advertiseMode,
                    advertiseTxPower: beacon.advertiseTxPower);
              } else {
                // isPressed.value = !isPressed.value;
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
                  fontSize: Theme.of(context).textTheme.titleSmall?.fontSize,
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
                ref
                    .read(beaconBroadcasterProvider.notifier)
                    .state
                    .stopAdvertising();
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      content: const SizedBox(
                        height: 1,
                      ),
                      actions: [
                        TextButton(
                            child: const Text('Edit',
                                style: TextStyle(color: Colors.blue)),
                            onPressed: () async {
                              final editedBeacon = await showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return BeaconEditDialog(beacon: beacon);
                                  });
                              if (editedBeacon != null) {
                                final objectbox = ObjectBox.instance;
                                objectbox.beaconBox.put(editedBeacon);
                                ref.read(beaconListProvider.notifier).state =
                                    objectbox.beaconBox.getAll();
                              }
                            }),
                        TextButton(
                            child: const Text('Delete',
                                style: TextStyle(color: Colors.red)),
                            onPressed: () async {
                              showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: const Text('Delete'),
                                      content: const Text(
                                          'Are you sure you want to delete this beacon?'),
                                      actions: [
                                        TextButton(
                                            child: const Text('Cancel',
                                                style: TextStyle(
                                                    color: Colors.blue)),
                                            onPressed: () =>
                                                Navigator.of(context).pop()),
                                        TextButton(
                                            child: const Text('Delete',
                                                style: TextStyle(
                                                    color: Colors.red)),
                                            onPressed: () {
                                              final objectbox =
                                                  ObjectBox.instance;
                                              objectbox.beaconBox
                                                  .remove(beacon.id);
                                              ref
                                                      .read(beaconListProvider
                                                          .notifier)
                                                      .state =
                                                  objectbox.beaconBox.getAll();
                                              Navigator.of(context).pop();
                                              Navigator.of(context).pop();
                                            })
                                      ],
                                    );
                                  });
                            }),
                        TextButton(
                          child: const Text('Cancel'),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    );
                  },
                );
              }, // 点击编辑图标弹出窗口
            ),
          ),
        ],
      ),
    );
  }
}
