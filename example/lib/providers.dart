import 'dart:async';

import 'package:beacon_broadcaster/beacon_broadcaster.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'beacon_repository.dart';
import 'models/beacon.dart';

part 'providers.g.dart';

@riverpod
Future<BeaconRepository> beaconRepository(Ref ref) async {
  return BeaconRepository.create();
}

@riverpod
class BeaconList extends _$BeaconList {
  @override
  FutureOr<List<Beacon>> build() async {
    final repository = await ref.watch(beaconRepositoryProvider.future);
    final beacons = await repository.getAll();
    if (beacons.isEmpty) {
      final beacon = Beacon(
        name: 'Test Beacon',
        uuid: '550e8400-e29b-41d4-a716-446655440000',
        major: 0x66,
        minor: 0x99,
        txPower: 0,
      );
      return repository.put(beacon);
    }
    return beacons;
  }

  Future<void> addBeacon(Beacon beacon) async {
    final repository = await ref.read(beaconRepositoryProvider.future);
    state = AsyncData(await repository.put(beacon));
  }

  Future<void> updateBeacon(Beacon beacon) async {
    final repository = await ref.read(beaconRepositoryProvider.future);
    state = AsyncData(await repository.put(beacon));
  }

  Future<void> deleteBeacon(int id) async {
    final repository = await ref.read(beaconRepositoryProvider.future);
    state = AsyncData(await repository.remove(id));
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

class BroadcastDurationNotifier extends Notifier<int?> {
  @override
  int? build() => 5000;

  void set(int? durationMs) {
    state = durationMs;
  }
}

final broadcastDurationMsProvider =
    NotifierProvider<BroadcastDurationNotifier, int?>(
  BroadcastDurationNotifier.new,
);

class ActiveBeaconIdNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  void set(int? beaconId) {
    state = beaconId;
  }

  void clear() {
    state = null;
  }
}

final activeBeaconIdProvider = NotifierProvider<ActiveBeaconIdNotifier, int?>(
  ActiveBeaconIdNotifier.new,
);
