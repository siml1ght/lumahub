import 'package:flutter_test/flutter_test.dart';
import 'package:strobe_controller_mobile/models/connection_state_model.dart';
import 'package:strobe_controller_mobile/models/controller_profile.dart';
import 'package:strobe_controller_mobile/models/light_device.dart';
import 'package:strobe_controller_mobile/models/light_group.dart';
import 'package:strobe_controller_mobile/models/pattern_config.dart';
import 'package:strobe_controller_mobile/providers/app_state.dart';

import '../support/fakes.dart';

void main() {
  group('AppState', () {
    late FakeConnectionService connection;
    late FakeProfileStorageService storage;
    late FakeProfileExchangeService exchange;
    late AppState state;

    setUp(() {
      connection = FakeConnectionService();
      storage = FakeProfileStorageService();
      exchange = FakeProfileExchangeService();
      state = AppState(
        connectionService: connection,
        profileStorageService: storage,
        profileExchangeService: exchange,
        enableHeartbeat: false,
      );
    });

    test('bootstrap initializes live mode without mock devices', () async {
      await state.bootstrap();

      expect(state.useMockMode, isFalse);
      expect(state.devices, isEmpty);
      expect(state.patterns, isNotEmpty);
      expect(state.connection.message, contains('Ready for Bluetooth'));
    });

    test('scan and connect updates state and requests config', () async {
      await state.bootstrap();
      await state.scanControllers();
      await state.connect('ESP32-StrobeCtrl (AA:BB)');

      // BLE permissions are requested by flutter_blue_plus during startScan(),
      // not by the app, so the fake permission service is no longer called.
      expect(state.connection.status, ControllerConnectionStatus.connected);
      expect(connection.sentCommands, containsAll(['HELLO', 'GET_CONFIG']));
    });

    test('incoming disconnect resets connection and active controls', () async {
      await state.bootstrap();
      await state.connect('ESP32-StrobeCtrl');

      state.activeControlKeys.add('front_left');
      connection.emit('DISCONNECTED');
      await Future<void>.delayed(const Duration(milliseconds: 1));

      expect(state.connection.status, ControllerConnectionStatus.disconnected);
      expect(state.activeControlKeys, isEmpty);
    });

    test('incoming firmware status reconciles active control keys', () async {
      await state.bootstrap();
      await state.connect('ESP32-StrobeCtrl');

      connection.emit('STATE=CONNECTED;MODE=ON;ACTIVE=FrontLeft,Beacon;SAFE=0');
      await Future<void>.delayed(const Duration(milliseconds: 1));

      expect(state.activeControlKeys, containsAll(['front_left', 'beacon']));
      expect(state.connection.status, ControllerConnectionStatus.connected);

      connection.emit('STATE=CONNECTED;MODE=IDLE;ACTIVE=NONE;SAFE=1');
      await Future<void>.delayed(const Duration(milliseconds: 1));

      expect(state.activeControlKeys, isEmpty);
    });

    test('triggerControl ignores tap when live mode is disconnected', () async {
      await state.bootstrap();
      await state.triggerControl('front_left', 'FrontLeft=ON');

      expect(state.activeControlKeys, isEmpty);
      expect(connection.sentCommands, isEmpty);
    });

    test('sendRawCommand is throttled under burst load', () async {
      await state.bootstrap();
      await state.connect('ESP32-StrobeCtrl');
      connection.sentCommands.clear(); // keep only burst results.

      final futures = <Future<void>>[];
      for (var i = 0; i < 200; i++) {
        futures.add(state.sendRawCommand('FrontLeft=ON'));
      }
      await Future.wait(futures);

      expect(connection.sentCommands.length, lessThan(30));
      expect(connection.sentCommands, everyElement('FrontLeft=ON'));
    });

    test('save/load profile persists local config without BLE side effects', () async {
      await state.bootstrap();
      state.upsertDevice(
        LightDevice(
          id: 'dev-1',
          name: 'Beacon',
          type: LightDeviceType.beacon,
          channel: 1,
          group: 'Top',
          enabled: true,
          inverted: false,
          brightness: 255,
          mode: 'steady',
          channelCount: 1,
          primaryOutput: 13,
        ),
      );
      state.groups = const [
        LightGroup(
          id: 'grp-top',
          name: 'Top',
          colorHex: '#ffaa00',
          deviceIds: ['dev-1'],
        ),
      ];
      state.patterns = const [
        PatternConfig(
          id: 'pat-1',
          name: 'Burst',
          speed: 1.1,
          pauseMs: 100,
          syncEnabled: true,
          alternating: false,
          randomMode: false,
        ),
      ];

      await state.saveCurrentProfile('garage');
      expect(storage.stored.length, 1);
      expect(storage.stored.single.name, 'garage');

      state.devices = <LightDevice>[];
      await state.loadProfile('garage');
      expect(state.devices.length, 1);
      expect(connection.sentCommands, isEmpty);
    });

    test('import/export profile uses exchange service', () async {
      await state.bootstrap();
      exchange.importedProfile = ControllerProfile(
        name: 'imported',
        devices: const [],
        groups: const [],
        patterns: const [],
        lastUpdated: DateTime.now(),
      );

      await state.importProfile();
      expect(state.profiles.any((p) => p.name == 'imported'), isTrue);

      await state.exportProfile(state.profiles.first);
      expect(exchange.exportedProfile?.name, state.profiles.first.name);
    });
  });
}
