import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<bool> requestNearbyPermissions() async {
    // For Android 12+ you need Bluetooth permissions, for older Android Location is still required.
    final statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.location, // fallback for Android < 12
    ].request();

    // Return true if all granted
    return statuses.values.every((status) => status.isGranted);
  }
}
