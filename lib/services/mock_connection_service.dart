import 'dart:async';

import '../app/app_config.dart';
import '../models/connection_state_model.dart';
import 'controller_connection_service.dart';

class MockConnectionService implements ControllerConnectionService {
  final StreamController<String> _streamController =
      StreamController<String>.broadcast();

  bool _connected = false;

  @override
  Stream<String> get incomingMessages => _streamController.stream;

  @override
  Future<List<String>> scan() async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return const [AppConfig.bleDeviceName];
  }

  @override
  Future<ConnectionStateModel> connect(String controllerId) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    _connected = true;
    _streamController.add('CONNECTED:$controllerId');
    return ConnectionStateModel(
      status: ControllerConnectionStatus.connected,
      controllerName: controllerId,
      signalStrength: 86,
      message: 'Mock connection established',
      mockMode: true,
    );
  }

  @override
  Future<ConnectionStateModel> disconnect() async {
    _connected = false;
    _streamController.add('DISCONNECTED');
    return ConnectionStateModel.initial.copyWith(mockMode: true);
  }

  @override
  Future<void> sendCommand(String command) async {
    if (!_connected) {
      throw StateError('Controller is not connected');
    }
    await Future<void>.delayed(const Duration(milliseconds: 60));
    _streamController.add('ACK:$command');
  }
}
