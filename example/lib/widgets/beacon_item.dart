import 'package:beacon_broadcaster_example/models/beacon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';
import 'beacon_edit_dialog.dart';

class _BeaconItemColors {
  static const Color selected = Colors.blue;

  // static const Color unselected = Colors.blueGrey;
  static const Color pressed = Color(0xFF1976D2);
}

class BeaconItem extends ConsumerStatefulWidget {
  final Beacon beacon;

  final bool isToggle;
  final int id;

  const BeaconItem(
      {super.key,
      required this.id,
      required this.beacon,
      required this.isToggle});

  @override
  ConsumerState<BeaconItem> createState() => _BeaconItemState();
}

class _BeaconItemState extends ConsumerState<BeaconItem> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final beaconBroadcaster = ref.watch(beaconBroadcasterProvider);
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: _isPressed
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
              if (!widget.isToggle) {
                setState(() {
                  _isPressed = true;
                });
                await beaconBroadcaster.stopAdvertising();
                await beaconBroadcaster.startAdvertising(
                    uuid: widget.beacon.uuid,
                    major: widget.beacon.major,
                    minor: widget.beacon.minor,
                    txPower: widget.beacon.txPower,
                    advertiseMode: widget.beacon.advertiseMode,
                    advertiseTxPower: widget.beacon.advertiseTxPower);
              } else {
                setState(() {
                  _isPressed = !_isPressed;
                });
                if (_isPressed) {
                  await beaconBroadcaster.startAdvertising(
                      uuid: widget.beacon.uuid,
                      major: widget.beacon.major,
                      minor: widget.beacon.minor,
                      txPower: widget.beacon.txPower,
                      advertiseMode: widget.beacon.advertiseMode,
                      advertiseTxPower: widget.beacon.advertiseTxPower);
                } else {
                  await beaconBroadcaster.stopAdvertising();
                }
              }
            },
            onTapUp: (details) {
              if (!widget.isToggle) {
                setState(() {
                  _isPressed = false;
                });
                beaconBroadcaster.stopAdvertising();
              }
            },
            child: Center(
              child: Text(
                widget.beacon.name,
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
                ref.read(beaconBroadcasterProvider).stopAdvertising();
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
                                    return BeaconEditDialog(
                                        beacon: widget.beacon);
                                  });
                              if (editedBeacon != null) {
                                await ref
                                    .read(beaconListProvider.notifier)
                                    .updateBeacon(editedBeacon);
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
                                            onPressed: () async {
                                              await ref
                                                  .read(beaconListProvider
                                                      .notifier)
                                                  .deleteBeacon(
                                                      widget.beacon.id);
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
