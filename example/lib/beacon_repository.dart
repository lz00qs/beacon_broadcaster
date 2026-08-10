import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'models/beacon.dart';

class BeaconRepository {
  BeaconRepository(this._file);

  final File _file;

  static Future<BeaconRepository> create() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    return BeaconRepository(
      File(p.join(documentsDirectory.path, 'beacons.json')),
    );
  }

  Future<List<Beacon>> getAll() async {
    if (!await _file.exists()) {
      return [];
    }

    final decoded = jsonDecode(await _file.readAsString());
    if (decoded is! List<dynamic>) {
      throw const FormatException('Beacon storage must contain a JSON list.');
    }

    return decoded
        .map((item) => Beacon.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<List<Beacon>> put(Beacon beacon) async {
    final beacons = await getAll();
    if (beacon.id == 0) {
      final highestId = beacons.fold<int>(
        0,
        (highest, item) => item.id > highest ? item.id : highest,
      );
      beacon.id = highestId + 1;
    }

    final index = beacons.indexWhere((item) => item.id == beacon.id);
    if (index == -1) {
      beacons.add(beacon);
    } else {
      beacons[index] = beacon;
    }

    await _write(beacons);
    return beacons;
  }

  Future<List<Beacon>> remove(int id) async {
    final beacons = await getAll();
    beacons.removeWhere((item) => item.id == id);
    await _write(beacons);
    return beacons;
  }

  Future<void> _write(List<Beacon> beacons) async {
    await _file.parent.create(recursive: true);
    await _file.writeAsString(
      jsonEncode(beacons.map((beacon) => beacon.toJson()).toList()),
      flush: true,
    );
  }
}
