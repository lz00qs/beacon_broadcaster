import 'dart:async';

import 'package:beacon_broadcaster/beacon_broadcaster.dart';
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
  int _pressSequence = 0;

  Future<void> _startPressBroadcast(BeaconBroadcaster beaconBroadcaster) async {
    final sequence = ++_pressSequence;
    await beaconBroadcaster.stopAdvertising();
    if (!mounted || widget.isToggle) return;

    setState(() {
      _isPressed = true;
    });

    await beaconBroadcaster.startAdvertising(
      uuid: widget.beacon.uuid,
      major: widget.beacon.major,
      minor: widget.beacon.minor,
      txPower: widget.beacon.txPower,
      advertiseMode: widget.beacon.advertiseMode,
      advertiseTxPower: widget.beacon.advertiseTxPower,
    );

    if (!mounted || sequence != _pressSequence || !_isPressed) {
      await beaconBroadcaster.stopAdvertising();
    }
  }

  void _stopPressBroadcast(BeaconBroadcaster beaconBroadcaster) {
    _pressSequence++;
    if (!widget.isToggle && mounted && _isPressed) {
      setState(() {
        _isPressed = false;
      });
    }
    unawaited(beaconBroadcaster.stopAdvertising());
  }

  @override
  Widget build(BuildContext context) {
    final beaconBroadcaster = ref.watch(beaconBroadcasterProvider);
    final bluetoothState = ref.watch(bluetoothStateProvider);
    final broadcastDurationMs = ref.watch(broadcastDurationMsProvider);
    final activeBeaconId = ref.watch(activeBeaconIdProvider);
    final isBeaconing = bluetoothState.when(
      data: (value) => value == BluetoothState.beaconing,
      loading: () => false,
      error: (_, _) => false,
    );
    final isTogglePressed =
        activeBeaconId == widget.beacon.id && isBeaconing;
    final isPressed = widget.isToggle ? isTogglePressed : _isPressed;
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: isPressed
            ? _BeaconItemColors.pressed
            : _BeaconItemColors.selected,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: widget.isToggle
                ? null
                : (_) => _startPressBroadcast(beaconBroadcaster),
            onPointerUp: widget.isToggle
                ? null
                : (_) => _stopPressBroadcast(beaconBroadcaster),
            onPointerCancel: widget.isToggle
                ? null
                : (_) => _stopPressBroadcast(beaconBroadcaster),
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: widget.isToggle
                  ? () async {
                      final activeBeaconNotifier =
                          ref.read(activeBeaconIdProvider.notifier);
                      if (activeBeaconId == widget.beacon.id && isBeaconing) {
                        activeBeaconNotifier.clear();
                        await beaconBroadcaster.stopAdvertising();
                        return;
                      }

                      activeBeaconNotifier.clear();
                      await beaconBroadcaster.stopAdvertising();
                      final result = await beaconBroadcaster.startAdvertising(
                        uuid: widget.beacon.uuid,
                        major: widget.beacon.major,
                        minor: widget.beacon.minor,
                        txPower: widget.beacon.txPower,
                        durationMs: broadcastDurationMs,
                        advertiseMode: widget.beacon.advertiseMode,
                        advertiseTxPower: widget.beacon.advertiseTxPower,
                      );
                      if (!mounted) return;
                      if (result == 0) {
                        activeBeaconNotifier.set(widget.beacon.id);
                      } else {
                        activeBeaconNotifier.clear();
                      }
                    }
                  : null,
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
          ),
          Positioned(
            top: 4,
            right: 4,
            child: IconButton(
              icon: const Icon(Icons.more_horiz, color: Colors.white),
              onPressed: () {
                ref.read(activeBeaconIdProvider.notifier).clear();
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
                                               final confirmDialogNavigator =
                                                   Navigator.of(context);
                                               final menuDialogNavigator =
                                                   Navigator.of(this.context);
                                               await ref
                                                   .read(beaconListProvider
                                                       .notifier)
                                                   .deleteBeacon(
                                                       widget.beacon.id);
                                               if (!mounted) return;
                                               confirmDialogNavigator.pop();
                                               menuDialogNavigator.pop();
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
