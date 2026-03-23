import 'package:beacon_broadcaster/beacon_broadcaster.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/beacon.dart';
import 'objectbox.dart';

final objectBoxProvider = FutureProvider<ObjectBox>((ref) async {
  return ObjectBox.create();
});

class BeaconListNotifier extends AsyncNotifier<List<Beacon>> {
  @override
  Future<List<Beacon>> build() async {
    final objectbox = await ref.watch(objectBoxProvider.future);
    final beacons = objectbox.beaconBox.getAll();
    if (beacons.isEmpty) {
      final beacon = Beacon(
        name: 'Test Beacon',
        uuid: '550e8400-e29b-41d4-a716-446655440000',
        major: 0x66,
        minor: 0x99,
        txPower: 0,
      );
      objectbox.beaconBox.put(beacon);
      return [beacon];
    }
    return beacons;
  }

  Future<void> addBeacon(Beacon beacon) async {
    final objectbox = await ref.read(objectBoxProvider.future);
    objectbox.beaconBox.put(beacon);
    state = AsyncData(objectbox.beaconBox.getAll());
  }

  Future<void> updateBeacon(Beacon beacon) async {
    final objectbox = await ref.read(objectBoxProvider.future);
    objectbox.beaconBox.put(beacon);
    state = AsyncData(objectbox.beaconBox.getAll());
  }

  Future<void> deleteBeacon(int id) async {
    final objectbox = await ref.read(objectBoxProvider.future);
    objectbox.beaconBox.remove(id);
    state = AsyncData(objectbox.beaconBox.getAll());
  }
}

final beaconListProvider =
    AsyncNotifierProvider<BeaconListNotifier, List<Beacon>>(
        BeaconListNotifier.new);

class ToggleNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

final isToggleProvider =
    NotifierProvider<ToggleNotifier, bool>(ToggleNotifier.new);

final beaconBroadcasterProvider =
    Provider<BeaconBroadcaster>((ref) => BeaconBroadcaster());

final bluetoothStateProvider =
    StreamProvider.autoDispose<BluetoothState>((ref) {
  final beaconBroadcaster = ref.watch(beaconBroadcasterProvider);
  return beaconBroadcaster.bluetoothState.asBroadcastStream();
});
