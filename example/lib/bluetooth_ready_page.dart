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
    final isToggle = ref.watch(toggleProvider);
    final bluetoothState = ref.watch(bluetoothStateProvider);
    return Column(
      children: [
        bluetoothState.when(
          data: (value) => Text('Bluetooth state: $value'),
          loading: () => const SizedBox.shrink(),
          error: (error, stackTrace) =>
              const Text('Bluetooth state: error'),
        ),
        Expanded(
          child: beaconList.when(
            data: (beacons) => GridView.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 140, childAspectRatio: 1.0),
              itemCount: beacons.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: BeaconItem(
                      id: beacons[index].id,
                      beacon: beacons[index],
                      isToggle: isToggle),
                );
              },
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) =>
                const Center(child: Text('Failed to load beacons')),
          ),
        )
      ],
    );
  }
}
