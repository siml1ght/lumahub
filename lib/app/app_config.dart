abstract final class AppConfig {
  static const appName = 'LumaHub';
  static const bleDeviceName = 'LumaHub-ESP32';

  static const bleServiceUuid = '5E7A1001-0000-4C0A-B001-112233445566';
  static const bleCommandCharacteristicUuid =
      '5E7A1002-0000-4C0A-B001-112233445566';
  static const bleStatusCharacteristicUuid =
      '5E7A1003-0000-4C0A-B001-112233445566';

  static const adapterReadyTimeout = Duration(seconds: 8);
  static const scanTimeout = Duration(seconds: 8);
  static const connectionTimeout = Duration(seconds: 10);
  static const minimumWriteSpacing = Duration(milliseconds: 40);
  static const maxBleCommandBytes = 180;
  static const maxProfileFileBytes = 512 * 1024;
}
