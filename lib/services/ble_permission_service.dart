import 'dart:io';

import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class BlePermissionService {
  static const _platform = MethodChannel('dev.siml1ght.lumahub/android_info');

  /// Returns Android SDK level, or null on non-Android / channel errors.
  Future<int?> get _androidSdkInt async {
    if (!Platform.isAndroid) return null;
    try {
      return await _platform.invokeMethod<int>('getSdkInt');
    } on PlatformException {
      return null;
    }
  }

  Future<void> ensurePermissions() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return;
    }

    final permissions = <Permission>[
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ];

    // ACCESS_FINE_LOCATION is declared with maxSdkVersion=30 in the manifest,
    // so only Android 11 and below actually need it for BLE scanning.
    final sdkInt = await _androidSdkInt;
    final needsLocation = Platform.isAndroid && (sdkInt == null || sdkInt <= 30);

    if (needsLocation) {
      permissions.add(Permission.locationWhenInUse);
    }

    final statuses = await permissions.request();

    final permanentlyDenied = statuses.entries
        .where((entry) => entry.value.isPermanentlyDenied)
        .map((entry) => entry.key)
        .toList();
    if (permanentlyDenied.isNotEmpty) {
      final names = permanentlyDenied.map(_name).join(', ');
      throw StateError(
        'Разрешение не выдано навсегда: $names. Откройте настройки приложения и включите его.',
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
      case Permission.locationWhenInUse:
        return 'геолокация (нужна на Android 11 и ниже для поиска BLE)';
      default:
        return permission.toString();
    }
  }
}
