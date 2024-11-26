import 'package:flutter/material.dart';

class BluetoothUnsupportedPage extends StatelessWidget {
  const BluetoothUnsupportedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Bluetooth is unsupported.'),
    );
  }
}
