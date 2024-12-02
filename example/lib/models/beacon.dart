import 'package:beacon_broadcaster/beacon_broadcaster.dart';
import 'package:objectbox/objectbox.dart';

@Entity()
class Beacon {
  final String name;
  final String uuid;
  final int major;
  final int minor;
  final int txPower;
  final int advertiseMode;
  final int advertiseTxPower;

  @Id()
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
}
