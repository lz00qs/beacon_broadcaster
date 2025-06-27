import 'package:beacon_broadcaster/beacon_broadcaster.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/beacon.dart';

final beaconListProvider = StateProvider<List<Beacon>>((ref) => []);
final beaconBroadcasterProvider =
    StateProvider.autoDispose<BeaconBroadcaster>((ref) => BeaconBroadcaster());
final isToggleProvider = StateProvider.autoDispose<bool>((ref) => false);
final bluetoothStateProvider = StreamProvider.autoDispose<BluetoothState>((ref) async* {
  final beaconBroadcaster = ref.watch(beaconBroadcasterProvider);
  yield* beaconBroadcaster.bluetoothState.asBroadcastStream();
});
