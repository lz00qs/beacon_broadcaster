import 'package:beacon_broadcaster/beacon_broadcaster.dart';

class Beacon {
  final String name;
  final String uuid;
  final int major;
  final int minor;
  final int txPower;
  final int advertiseMode;
  final int advertiseTxPower;

  int id = 0;

  Beacon({
    required this.name,
    required this.uuid,
    required this.major,
    required this.minor,
    required this.txPower,
    this.advertiseMode = AndroidBleAdvertiseSettings.advertiseModeLowLatency,
    this.advertiseTxPower = AndroidBleAdvertiseSettings.advertiseTxPowerHigh,
  });

  factory Beacon.fromJson(Map<String, dynamic> json) {
    return Beacon(
      name: json['name'] as String,
      uuid: json['uuid'] as String,
      major: json['major'] as int,
      minor: json['minor'] as int,
      txPower: json['txPower'] as int,
      advertiseMode: json['advertiseMode'] as int,
      advertiseTxPower: json['advertiseTxPower'] as int,
    )..id = json['id'] as int;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'uuid': uuid,
      'major': major,
      'minor': minor,
      'txPower': txPower,
      'advertiseMode': advertiseMode,
      'advertiseTxPower': advertiseTxPower,
    };
  }
}
