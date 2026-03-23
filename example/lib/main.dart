import 'package:beacon_broadcaster_example/bluetooth_disabled_page.dart';
import 'package:beacon_broadcaster_example/bluetooth_unknown_page.dart';
import 'package:beacon_broadcaster_example/providers.dart';
import 'package:beacon_broadcaster_example/widgets/beacon_edit_dialog.dart';
import 'package:flutter/material.dart';

import 'package:beacon_broadcaster/beacon_broadcaster.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'bluetooth_ready_page.dart';
import 'bluetooth_unauthorized_page.dart';
import 'bluetooth_unsupported_page.dart';
import 'models/beacon.dart';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(
    child: MaterialApp(
      home: MyApp(),
    ),
  ));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bluetoothState = ref.watch(bluetoothStateProvider);
    final isToggle = ref.watch(isToggleProvider);
    return Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(
                onPressed: () async {
                  ref.read(beaconBroadcasterProvider).stopAdvertising();
                  final newBeacon = await showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return BeaconEditDialog(
                            beacon: Beacon(
                                name: 'New Beacon',
                                uuid: '550e8400-e29b-41d4-a716-446655440000',
                                major: 0x66,
                                minor: 0x99,
                                txPower: 0));
                      });
                  if (newBeacon != null) {
                    await ref
                        .read(beaconListProvider.notifier)
                        .addBeacon(newBeacon);
                  }
                },
                icon: const Icon(Icons.add)),
            const SizedBox(
              width: 8,
            ),
            const Text('Toggle:'),
            Switch(
              value: isToggle,
              onChanged: (value) =>
                  ref.read(isToggleProvider.notifier).set(value),
            ),
          ],
        ),
        body: bluetoothState.when(
          data: (value) => switch (value) {
            BluetoothState.unknown => const BluetoothUnknownPage(),
            BluetoothState.off => const BluetoothDisabledPage(),
            BluetoothState.unsupported => const BluetoothUnsupportedPage(),
            BluetoothState.unauthorized => const BluetoothUnauthorizedPage(),
            _ => const BluetoothReadyPage(),
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) =>
              const Center(child: Text('Failed to read bluetooth state')),
        ));
  }
}
