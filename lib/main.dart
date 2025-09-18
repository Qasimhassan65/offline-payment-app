// lib/main.dart
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Request runtime permissions before app starts
  await _requestPermissions();

  runApp(const MyApp());
}

Future<void> _requestPermissions() async {
  // Location (required for discovery)
  await Permission.locationWhenInUse.request();

  // Bluetooth permissions (Android 12+)
  await Permission.bluetoothAdvertise.request();
  await Permission.bluetoothConnect.request();
  await Permission.bluetoothScan.request();

  // Nearby WiFi devices (Android 13+)
  await Permission.nearbyWifiDevices.request();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Offline Payments',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomeScreen(),
    );
  }
}
