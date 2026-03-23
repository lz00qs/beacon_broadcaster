import 'dart:async';

import 'package:beacon_broadcaster/beacon_broadcaster.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'models/beacon.dart';
import 'objectbox.dart';

part 'providers.g.dart';

@riverpod
Future<ObjectBox> objectBox(Ref ref) async {
  return ObjectBox.create();
}

@riverpod
class BeaconList extends _$BeaconList {
  @override
  FutureOr<List<Beacon>> build() async {
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

@riverpod
class Toggle extends _$Toggle {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

@riverpod
BeaconBroadcaster beaconBroadcaster(Ref ref) {
  return BeaconBroadcaster();
}

@riverpod
Stream<BluetoothState> bluetoothState(Ref ref) {
  final beaconBroadcaster = ref.watch(beaconBroadcasterProvider);
  return beaconBroadcaster.bluetoothState.asBroadcastStream();
}
