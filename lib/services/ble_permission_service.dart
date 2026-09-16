import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

class BlePermissionService {
  Future<void> ensurePermissions() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return;
    }

    final permissions = <Permission>[
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      if (Platform.isAndroid) Permission.locationWhenInUse,
    ];

    final statuses = await permissions.request();
    final permanentlyDenied = statuses.entries
        .where((entry) => entry.value.isPermanentlyDenied)
        .map((entry) => entry.key.toString())
        .toList();
    if (permanentlyDenied.isNotEmpty) {
      throw StateError(
        'Bluetooth permission is permanently denied. Enable it in system settings.',
      );
    }

    final denied = statuses.entries
        .where((entry) => !entry.value.isGranted)
        .map((entry) => entry.key.toString())
        .toList();
    if (denied.isNotEmpty) {
      throw StateError('Bluetooth permission was not granted: ${denied.join(', ')}');
    }
  }
}
