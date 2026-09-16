import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../app/app_config.dart';
import '../models/connection_state_model.dart';
import 'controller_connection_service.dart';

class BleConnectionService implements ControllerConnectionService {
  BleConnectionService({
    Guid? serviceGuid,
    Guid? commandCharacteristicGuid,
    Guid? statusCharacteristicGuid,
  })  : _serviceGuid = serviceGuid ?? Guid(AppConfig.bleServiceUuid),
        _commandCharacteristicGuid = commandCharacteristicGuid ??
            Guid(AppConfig.bleCommandCharacteristicUuid),
        _statusCharacteristicGuid = statusCharacteristicGuid ??
            Guid(AppConfig.bleStatusCharacteristicUuid);

  final Guid _serviceGuid;
  final Guid _commandCharacteristicGuid;
  final Guid _statusCharacteristicGuid;
  final StreamController<String> _incomingController =
      StreamController<String>.broadcast();

  BluetoothDevice? _device;
  BluetoothCharacteristic? _commandCharacteristic;
  BluetoothCharacteristic? _statusCharacteristic;
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<List<int>>? _notificationSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  final Map<String, BluetoothDevice> _scanCache = <String, BluetoothDevice>{};
  Future<void> _writeQueue = Future<void>.value();
  DateTime _lastWriteAt = DateTime.fromMillisecondsSinceEpoch(0);

  static const List<String> _controllerNameHints = <String>[
    'lumahub-esp32',
    'lumahub esp32',
    'lumahub',
  ];

  @override
  Stream<String> get incomingMessages => _incomingController.stream;

  @override
  Future<List<String>> scan() async {
    _scanCache.clear();
    await FlutterBluePlus.stopScan();
    await _scanSubscription?.cancel();

    await FlutterBluePlus.adapterState
        .where((state) => state == BluetoothAdapterState.on)
        .first
        .timeout(
          AppConfig.adapterReadyTimeout,
          onTimeout: () => throw TimeoutException(
            'Bluetooth adapter is off or unavailable',
            AppConfig.adapterReadyTimeout,
          ),
        );

    _scanSubscription = FlutterBluePlus.onScanResults.listen((results) {
      for (final result in results) {
        final name = result.device.platformName.isNotEmpty
            ? result.device.platformName
            : result.advertisementData.advName;
        final advertisesTargetService = result.advertisementData.serviceUuids
            .any((uuid) => uuid.str.toLowerCase() == _serviceGuid.str.toLowerCase());
        final normalizedName = name.trim().toLowerCase();
        final looksLikeController = _controllerNameHints.any(
          (hint) => normalizedName.contains(hint),
        );

        if (!advertisesTargetService && !looksLikeController) {
          continue;
        }

        final displayName = name.trim().isNotEmpty
            ? name.trim()
            : AppConfig.bleDeviceName;
        final displayKey = '$displayName (${result.device.remoteId.str})';
        _scanCache[displayKey] = result.device;
      }
    });

    try {
      await FlutterBluePlus.startScan(timeout: AppConfig.scanTimeout);
      await FlutterBluePlus.isScanning
          .where((value) => value == false)
          .first
          .timeout(AppConfig.scanTimeout + const Duration(seconds: 2));
    } finally {
      await FlutterBluePlus.stopScan();
      await _scanSubscription?.cancel();
      _scanSubscription = null;
    }

    return _scanCache.keys.toList()..sort();
  }

  @override
  Future<ConnectionStateModel> connect(String controllerId) async {
    final device = _scanCache[controllerId];
    if (device == null) {
      throw StateError('Selected controller is no longer available. Scan again.');
    }

    await _closeActiveConnection();
    _device = device;

    try {
      await device.connect(
        timeout: AppConfig.connectionTimeout,
        autoConnect: false,
      );
      _connectionSubscription = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _commandCharacteristic = null;
          _statusCharacteristic = null;
          _incomingController.add('DISCONNECTED');
        }
      });

      if (Platform.isAndroid) {
        await device.requestMtu(247);
      }

      final services = await device.discoverServices();
      BluetoothCharacteristic? foundCommandCharacteristic;
      BluetoothCharacteristic? foundStatusCharacteristic;

      for (final service in services) {
        if (service.uuid != _serviceGuid) {
          continue;
        }
        for (final characteristic in service.characteristics) {
          if (characteristic.uuid == _commandCharacteristicGuid) {
            foundCommandCharacteristic = characteristic;
          } else if (characteristic.uuid == _statusCharacteristicGuid) {
            foundStatusCharacteristic = characteristic;
          }
        }
      }

      if (foundCommandCharacteristic == null ||
          foundStatusCharacteristic == null) {
        throw StateError('LumaHub BLE service is incomplete or incompatible');
      }
      if (!foundCommandCharacteristic.properties.write) {
        throw StateError('LumaHub command characteristic is not writable');
      }
      if (!foundStatusCharacteristic.properties.notify &&
          !foundStatusCharacteristic.properties.indicate) {
        throw StateError('LumaHub status characteristic cannot notify');
      }

      _commandCharacteristic = foundCommandCharacteristic;
      _statusCharacteristic = foundStatusCharacteristic;
      await foundStatusCharacteristic.setNotifyValue(true);
      _notificationSubscription = foundStatusCharacteristic.lastValueStream.listen(
        (value) {
          if (value.isNotEmpty) {
            _incomingController.add(utf8.decode(value, allowMalformed: true));
          }
        },
      );
      device.cancelWhenDisconnected(_notificationSubscription!);

      var signalStrength = 0;
      try {
        signalStrength = _normalizeRssi(await device.readRssi());
      } on Exception {
        // RSSI is informative; a read failure must not tear down a valid link.
      }

      return ConnectionStateModel(
        status: ControllerConnectionStatus.connected,
        controllerName: controllerId,
        signalStrength: signalStrength,
        message: 'LumaHub controller connected',
        mockMode: false,
      );
    } catch (_) {
      await _closeActiveConnection();
      rethrow;
    }
  }

  @override
  Future<ConnectionStateModel> disconnect() async {
    await _closeActiveConnection();
    return ConnectionStateModel.initial.copyWith(
      mockMode: false,
      message: 'Controller disconnected',
    );
  }

  @override
  Future<void> sendCommand(String command) {
    final encoded = utf8.encode(command);
    if (encoded.isEmpty) {
      throw ArgumentError.value(command, 'command', 'Command must not be empty');
    }
    if (encoded.length > AppConfig.maxBleCommandBytes) {
      throw ArgumentError.value(
        encoded.length,
        'command',
        'Command exceeds ${AppConfig.maxBleCommandBytes} UTF-8 bytes',
      );
    }

    final operation = _writeQueue.then((_) async {
      final characteristic = _commandCharacteristic;
      if (characteristic == null) {
        throw StateError('BLE command characteristic is not ready');
      }

      final elapsed = DateTime.now().difference(_lastWriteAt);
      final wait = AppConfig.minimumWriteSpacing - elapsed;
      if (wait > Duration.zero) {
        await Future<void>.delayed(wait);
      }

      await characteristic.write(encoded, withoutResponse: false);
      _lastWriteAt = DateTime.now();
    });

    _writeQueue = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {},
    );
    return operation;
  }

  Future<void> _closeActiveConnection() async {
    await _notificationSubscription?.cancel();
    _notificationSubscription = null;
    await _connectionSubscription?.cancel();
    _connectionSubscription = null;
    _commandCharacteristic = null;
    _statusCharacteristic = null;

    final device = _device;
    _device = null;
    if (device != null) {
      try {
        await device.disconnect();
      } on Exception {
        // The device may already be disconnected; cleanup remains idempotent.
      }
    }
  }

  int _normalizeRssi(int rssi) {
    final normalized = ((rssi + 100) * 2).clamp(0, 100);
    return normalized.toInt();
  }
}
