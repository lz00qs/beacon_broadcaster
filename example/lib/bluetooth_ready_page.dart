import 'package:beacon_broadcaster_example/providers.dart';
import 'package:beacon_broadcaster_example/widgets/beacon_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class _BroadcastDurationOption {
  final String label;
  final int? durationMs;

  const _BroadcastDurationOption(this.label, this.durationMs);
}

const _broadcastDurationOptions = [
  _BroadcastDurationOption('Continuous', null),
  _BroadcastDurationOption('3s', 3000),
  _BroadcastDurationOption('5s', 5000),
  _BroadcastDurationOption('10s', 10000),
];

class BluetoothReadyPage extends ConsumerWidget {
  const BluetoothReadyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final beaconList = ref.watch(beaconListProvider);
    final isToggle = ref.watch(toggleProvider);
    final bluetoothState = ref.watch(bluetoothStateProvider);
    final broadcastDurationMs = ref.watch(broadcastDurationMsProvider);
    return Column(
      children: [
        bluetoothState.when(
          data: (value) => Text('Bluetooth state: $value'),
          loading: () => const SizedBox.shrink(),
          error: (error, stackTrace) =>
              const Text('Bluetooth state: error'),
        ),
        if (isToggle)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Auto stop duration'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final option in _broadcastDurationOptions)
                      ChoiceChip(
                        label: Text(option.label),
                        selected: broadcastDurationMs == option.durationMs,
                        onSelected: (_) {
                          ref
                              .read(broadcastDurationMsProvider.notifier)
                              .set(option.durationMs);
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  broadcastDurationMs == null
                      ? 'Tap a beacon to broadcast continuously until you tap again.'
                      : 'Tap a beacon to broadcast for ${broadcastDurationMs ~/ 1000} seconds, then stop automatically.',
                ),
              ],
            ),
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
