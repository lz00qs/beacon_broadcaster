import 'dart:io';

import 'package:beacon_broadcaster_example/beacon_repository.dart';
import 'package:beacon_broadcaster_example/models/beacon.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory temporaryDirectory;
  late BeaconRepository repository;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'beacon_repository_test.',
    );
    repository = BeaconRepository(
      File('${temporaryDirectory.path}/beacons.json'),
    );
  });

  tearDown(() async {
    await temporaryDirectory.delete(recursive: true);
  });

  test('persists add, update, and delete operations', () async {
    final beacon = Beacon(
      name: 'Test Beacon',
      uuid: '550e8400-e29b-41d4-a716-446655440000',
      major: 1,
      minor: 2,
      txPower: -59,
    );

    final added = await repository.put(beacon);
    expect(added, hasLength(1));
    expect(beacon.id, 1);

    final updatedBeacon = Beacon(
      name: 'Updated Beacon',
      uuid: beacon.uuid,
      major: beacon.major,
      minor: beacon.minor,
      txPower: beacon.txPower,
    )..id = beacon.id;
    await repository.put(updatedBeacon);

    final reloaded = await repository.getAll();
    expect(reloaded, hasLength(1));
    expect(reloaded.single.id, 1);
    expect(reloaded.single.name, 'Updated Beacon');

    expect(await repository.remove(beacon.id), isEmpty);
    expect(await repository.getAll(), isEmpty);
  });
}
