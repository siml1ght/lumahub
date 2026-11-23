import 'dart:async';

import 'package:strobe_controller_mobile/models/connection_state_model.dart';
import 'package:strobe_controller_mobile/models/controller_profile.dart';
import 'package:strobe_controller_mobile/services/controller_connection_service.dart';
import 'package:strobe_controller_mobile/services/profile_exchange_service.dart';
import 'package:strobe_controller_mobile/services/profile_storage_service.dart';

class FakeConnectionService implements ControllerConnectionService {
  final StreamController<String> _messages = StreamController<String>.broadcast();

  List<String> scanResults = const ['ESP32-StrobeCtrl (AA:BB:CC:DD:EE:FF)'];
  final List<String> sentCommands = <String>[];
  bool connected = false;

  @override
  Stream<String> get incomingMessages => _messages.stream;

  @override
  Future<List<String>> scan() async => scanResults;

  @override
  Future<ConnectionStateModel> connect(String controllerId) async {
    connected = true;
    _messages.add('CONNECTED:$controllerId');
    return ConnectionStateModel(
      status: ControllerConnectionStatus.connected,
      controllerName: controllerId,
      signalStrength: 88,
      message: 'Connected',
      mockMode: false,
    );
  }

  @override
  Future<ConnectionStateModel> disconnect() async {
    connected = false;
    _messages.add('DISCONNECTED');
    return ConnectionStateModel.initial.copyWith(
      mockMode: false,
      message: 'Disconnected',
    );
  }

  @override
  Future<void> sendCommand(String command) async {
    if (!connected) {
      throw StateError('not connected');
    }
    sentCommands.add(command);
    _messages.add('ACK:$command');
  }

  void emit(String message) => _messages.add(message);
}

class FakeProfileStorageService extends ProfileStorageService {
  List<ControllerProfile> stored = <ControllerProfile>[];

  @override
  Future<List<ControllerProfile>> loadProfiles() async => List<ControllerProfile>.from(stored);

  @override
  Future<void> saveProfiles(List<ControllerProfile> profiles) async {
    stored = List<ControllerProfile>.from(profiles);
  }
}

class FakeProfileExchangeService extends ProfileExchangeService {
  ControllerProfile? importedProfile;
  ControllerProfile? exportedProfile;

  @override
  Future<ControllerProfile?> importProfile() async => importedProfile;

  @override
  Future<void> exportProfile(ControllerProfile profile) async {
    exportedProfile = profile;
  }
}
