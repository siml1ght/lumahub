import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:strobe_controller_mobile/models/controller_profile.dart';
import 'package:strobe_controller_mobile/models/pattern_config.dart';
import 'package:strobe_controller_mobile/services/profile_storage_service.dart';

void main() {
  group('ControllerProfile validation', () {
    test('exports an explicit schema version', () {
      final profile = ControllerProfile(
        name: 'Road setup',
        devices: const [],
        groups: const [],
        patterns: const [],
        lastUpdated: DateTime.utc(2026, 9, 16),
      );

      expect(profile.toMap()['schemaVersion'], ControllerProfile.schemaVersion);
    });

    test('rejects unsupported schema versions', () {
      expect(
        () => ControllerProfile.fromMap(<String, dynamic>{
          'schemaVersion': 999,
          'name': 'Unsupported',
        }),
        throwsFormatException,
      );
    });

    test('rejects empty names and oversized collections', () {
      expect(
        () => ControllerProfile.fromMap(<String, dynamic>{'name': '  '}),
        throwsFormatException,
      );
      expect(
        () => ControllerProfile.fromMap(<String, dynamic>{
          'name': 'Too large',
          'devices': List<Map<String, dynamic>>.filled(
            ControllerProfile.maxDevices + 1,
            const <String, dynamic>{},
          ),
        }),
        throwsFormatException,
      );
    });

    test('validates pattern timing boundaries', () {
      expect(
        () => PatternConfig.fromMap(<String, dynamic>{
          'id': 'pattern',
          'name': 'Invalid',
          'speed': 1,
          'pauseMs': 0,
        }),
        throwsFormatException,
      );
    });
  });

  test('storage skips corrupt entries and loads valid profiles', () async {
    final validProfile = jsonEncode(<String, dynamic>{
      'schemaVersion': ControllerProfile.schemaVersion,
      'name': 'Valid',
      'devices': <Object>[],
      'groups': <Object>[],
      'patterns': <Object>[],
      'lastUpdated': '2026-09-16T12:00:00Z',
    });
    SharedPreferences.setMockInitialValues(<String, Object>{
      'controller_profiles': <String>[
        '{broken-json',
        '[]',
        validProfile,
      ],
    });

    final profiles = await ProfileStorageService().loadProfiles();

    expect(profiles, hasLength(1));
    expect(profiles.single.name, 'Valid');
  });
}
