import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

class BlePermissionService {
  /// Requests the Bluetooth permissions the app controls itself.
  ///
  /// Location is intentionally NOT requested here. The manifest declares
  /// ACCESS_FINE_LOCATION with maxSdkVersion=30, so on Android 12+ the system
  /// cannot grant it. flutter_blue_plus requests ACCESS_FINE_LOCATION itself
  /// during startScan() on Android 11 and below, where it is genuinely needed.
  Future<void> ensurePermissions() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return;
    }

    final permissions = <Permission>[
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ];

    final statuses = await permissions.request();

    final permanentlyDenied = statuses.entries
        .where((entry) => entry.value.isPermanentlyDenied)
        .map((entry) => entry.key)
        .toList();
    if (permanentlyDenied.isNotEmpty) {
      final names = permanentlyDenied.map(_name).join(', ');
      throw StateError(
        'Разрешение не выдано навсегда: $names. '
        'Откройте настройки приложения и включите его.',
      );
    }

    final denied = statuses.entries
        .where((entry) => !entry.value.isGranted)
        .map((entry) => entry.key)
        .toList();
    if (denied.isNotEmpty) {
      final names = denied.map(_name).join(', ');
      throw StateError('Не получено разрешение: $names');
    }
  }

  String _name(Permission permission) {
    switch (permission) {
      case Permission.bluetoothScan:
        return 'сканирование Bluetooth';
      case Permission.bluetoothConnect:
        return 'подключение Bluetooth';
      default:
        return permission.toString();
    }
  }
}
