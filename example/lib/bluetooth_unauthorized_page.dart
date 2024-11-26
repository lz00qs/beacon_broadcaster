import 'package:app_settings/app_settings.dart';
import 'package:beacon_broadcaster/beacon_broadcaster.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothUnauthorizedPage extends StatelessWidget {
  const BluetoothUnauthorizedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Bluetooth is unauthorized.'),
          const SizedBox(height: 50),
          ElevatedButton(
              onPressed: () async {
                final beaconBroadcaster = Get.find<BeaconBroadcaster>();
                final platformVersion =
                    await beaconBroadcaster.getPlatformVersion();
                // platformVersion = 'Android 11' 拆分成 ['Android', '11']
                if (platformVersion == null) {
                  return;
                }
                final platformVersionSplit = platformVersion.split(' ');
                if (platformVersionSplit.length < 2) {
                  return;
                }
                final platform = platformVersionSplit[0];
                final version = int.tryParse(platformVersionSplit[1]);
                if (version == null) {
                  return;
                }
                var permissionStatus = PermissionStatus.denied;
                if (platform == 'Android') {
                  if (version <= 11) {
                    permissionStatus = await Permission.bluetooth.request();
                    while ((permissionStatus != PermissionStatus.granted)) {
                      Fluttertoast.showToast(
                        msg: "Please allow bluetooth permission",
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.CENTER,
                      );
                      permissionStatus = await Permission.bluetooth.request();
                      if (permissionStatus ==
                          PermissionStatus.permanentlyDenied) {
                        Fluttertoast.showToast(
                          msg:
                              "Permission permanently denied, please open settings to allow bluetooth permission",
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.CENTER,
                        );
                        await AppSettings.openAppSettings();
                      }
                    }
                  }
                  permissionStatus =
                      await Permission.bluetoothAdvertise.request();
                  while ((permissionStatus != PermissionStatus.granted)) {
                    Fluttertoast.showToast(
                      msg: "Please allow bluetooth advertise permission",
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.CENTER,
                    );
                    permissionStatus =
                        await Permission.bluetoothAdvertise.request();
                    if (permissionStatus ==
                        PermissionStatus.permanentlyDenied) {
                      Fluttertoast.showToast(
                        msg:
                            "Permission permanently denied, please open settings to allow nearby devices permission",
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.CENTER,
                      );
                      await AppSettings.openAppSettings();
                    }
                  }

                  await beaconBroadcaster.checkBluetoothState();
                }
              },
              child: const Text('Request Bluetooth Permission')),
        ],
      ),
    );
  }
}
