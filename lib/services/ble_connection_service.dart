import 'dart:async';
import 'dart:convert';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../models/connection_state_model.dart';
import 'controller_connection_service.dart';

class BleConnectionService implements ControllerConnectionService {
  BleConnectionService({
    Guid? serviceGuid,
    Guid? commandCharacteristicGuid,
    Guid? statusCharacteristicGuid,
  })  : _serviceGuid = serviceGuid ??
            Guid('5E7A1001-0000-4C0A-B001-112233445566'),
        _commandCharacteristicGuid = commandCharacteristicGuid ??
            Guid('5E7A1002-0000-4C0A-B001-112233445566'),
        _statusCharacteristicGuid = statusCharacteristicGuid ??
            Guid('5E7A1003-0000-4C0A-B001-112233445566');

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
  static const List<String> _controllerNameHints = <String>[
    'lumahub-esp32',
    'lumahub esp32',
    'lumahub',
    'esp32',
    'lighting controller',
  ];

  @override
  Stream<String> get incomingMessages => _incomingController.stream;

  @override
  Future<List<String>> scan() async {
    _scanCache.clear();
    final completer = Completer<List<String>>();

    await FlutterBluePlus.adapterState
        .where((state) => state == BluetoothAdapterState.on)
        .first;
    await FlutterBluePlus.stopScan();
    _scanSubscription?.cancel();
    _scanSubscription = FlutterBluePlus.onScanResults.listen((results) {
      for (final result in results) {
        final name = result.device.platformName.isNotEmpty
            ? result.device.platformName
            : result.advertisementData.advName;
        final advertisesTargetService = result.advertisementData.serviceUuids
            .any((uuid) => uuid.str.toLowerCase() == _serviceGuid.str.toLowerCase());
        final normalizedName = name.toLowerCase();
        final looksLikeController = _controllerNameHints.any(
          (hint) => normalizedName.contains(hint),
        );

        final hasUsableName = name.trim().isNotEmpty;
        if (!advertisesTargetService && !looksLikeController && !hasUsableName) {
          continue;
        }

        final displayName = name.trim().isNotEmpty ? name.trim() : 'BLE Controller';
        final tag = advertisesTargetService || looksLikeController
            ? 'LumaHub candidate'
            : 'BLE device';
        final displayKey = '$displayName  (${result.device.remoteId.str})  - $tag';
        _scanCache[displayKey] = result.device;
      }
    });

    FlutterBluePlus.cancelWhenScanComplete(_scanSubscription!);
    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 8),
      androidUsesFineLocation: true,
    );
    await FlutterBluePlus.isScanning.where((value) => value == false).first;
    if (!completer.isCompleted) {
      completer.complete(_scanCache.keys.toList()..sort());
    }

    return completer.future;
  }

  @override
  Future<ConnectionStateModel> connect(String controllerId) async {
    final device = _scanCache[controllerId];
    if (device == null) {
      throw StateError('Controller not found in BLE scan cache');
    }

    _device = device;
    await device.connect(
      timeout: const Duration(seconds: 8),
      autoConnect: false,
    );
    _connectionSubscription?.cancel();
    _connectionSubscription = device.connectionState.listen((state) {
      if (state == BluetoothConnectionState.disconnected) {
        _incomingController.add('DISCONNECTED');
      }
    });
    await device.requestMtu(247);
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

    if (foundCommandCharacteristic == null) {
      throw StateError('BLE command characteristic was not found');
    }

    _commandCharacteristic = foundCommandCharacteristic;
    _statusCharacteristic = foundStatusCharacteristic;

    final statusCharacteristic = _statusCharacteristic;
    if (statusCharacteristic != null &&
        (statusCharacteristic.properties.notify ||
            statusCharacteristic.properties.indicate)) {
      await statusCharacteristic.setNotifyValue(true);
      _notificationSubscription?.cancel();
      _notificationSubscription = statusCharacteristic.lastValueStream.listen(
        (value) {
          if (value.isNotEmpty) {
            _incomingController.add(utf8.decode(value));
          }
        },
      );
      device.cancelWhenDisconnected(_notificationSubscription!);
    }

    final rssi = await device.readRssi();
    return ConnectionStateModel(
      status: ControllerConnectionStatus.connected,
      controllerName: controllerId,
      signalStrength: _normalizeRssi(rssi),
      message: 'BLE connected',
      mockMode: false,
    );
  }

  @override
  Future<ConnectionStateModel> disconnect() async {
    await _notificationSubscription?.cancel();
    _notificationSubscription = null;
    await _connectionSubscription?.cancel();
    _connectionSubscription = null;
    await _device?.disconnect();
    _device = null;
    _commandCharacteristic = null;
    _statusCharacteristic = null;

    return ConnectionStateModel.initial.copyWith(
      mockMode: false,
      message: 'BLE disconnected',
    );
  }

  @override
  Future<void> sendCommand(String command) async {
    final characteristic = _commandCharacteristic;
    if (characteristic == null) {
      throw StateError('BLE command characteristic is not ready');
    }
    await characteristic.write(utf8.encode(command), withoutResponse: false);
  }

  int _normalizeRssi(int rssi) {
    final normalized = ((rssi + 100) * 2).clamp(0, 100);
    return normalized.toInt();
  }
}
