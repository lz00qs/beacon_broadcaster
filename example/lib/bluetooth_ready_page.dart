import 'package:beacon_broadcaster/beacon_broadcaster.dart';
import 'package:beacon_broadcaster_example/providers.dart';
import 'package:beacon_broadcaster_example/widgets/beacon_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BluetoothReadyPage extends ConsumerWidget {
  const BluetoothReadyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final beaconList = ref.watch(beaconListProvider);
    final isToggle = ref.watch(isToggleProvider);
    final bluetoothState = ref.watch(bluetoothStateProvider);
    return Column(
      children: [
        switch (bluetoothState) {
          AsyncValue<BluetoothState>(:final value) =>
            Text('Bluetooth state: $value'),
        },
        Expanded(
            child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 140, childAspectRatio: 1.0),
          itemCount: beaconList.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: BeaconItem(
                  id: beaconList[index].id,
                  beacon: beaconList[index],
                  isToggle: isToggle),
            );
          },
        ))
      ],
    );
  }
}
