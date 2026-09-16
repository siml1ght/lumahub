import 'dart:convert';

import 'light_device.dart';
import 'light_group.dart';
import 'pattern_config.dart';

class ControllerProfile {
  const ControllerProfile({
    required this.name,
    required this.devices,
    required this.groups,
    required this.patterns,
    required this.lastUpdated,
  });

  static const schemaVersion = 1;
  static const maxDevices = 64;
  static const maxGroups = 32;
  static const maxPatterns = 64;

  final String name;
  final List<LightDevice> devices;
  final List<LightGroup> groups;
  final List<PatternConfig> patterns;
  final DateTime lastUpdated;

  Map<String, dynamic> toMap() {
    return {
      'schemaVersion': schemaVersion,
      'name': name,
      'devices': devices.map((item) => item.toMap()).toList(),
      'groups': groups.map((item) => item.toMap()).toList(),
      'patterns': patterns.map((item) => item.toMap()).toList(),
      'lastUpdated': lastUpdated.toUtc().toIso8601String(),
    };
  }

  factory ControllerProfile.fromMap(Map<String, dynamic> map) {
    final version = (map['schemaVersion'] as num?)?.toInt() ?? schemaVersion;
    if (version != schemaVersion) {
      throw FormatException('Unsupported profile schema version: $version');
    }

    final rawName = map['name'];
    if (rawName is! String || rawName.trim().isEmpty) {
      throw const FormatException('Profile name must be a non-empty string');
    }
    final name = rawName.trim();
    if (name.length > 80) {
      throw const FormatException('Profile name must not exceed 80 characters');
    }

    final deviceMaps = _mapList(map['devices'], 'devices', maxDevices);
    final groupMaps = _mapList(map['groups'], 'groups', maxGroups);
    final patternMaps = _mapList(map['patterns'], 'patterns', maxPatterns);

    return ControllerProfile(
      name: name,
      devices: deviceMaps.map(LightDevice.fromMap).toList(growable: false),
      groups: groupMaps.map(LightGroup.fromMap).toList(growable: false),
      patterns: patternMaps.map(PatternConfig.fromMap).toList(growable: false),
      lastUpdated: DateTime.tryParse(map['lastUpdated'] as String? ?? '')?.toUtc() ??
          DateTime.now().toUtc(),
    );
  }

  static List<Map<String, dynamic>> _mapList(
    Object? value,
    String field,
    int maxItems,
  ) {
    if (value == null) {
      return const [];
    }
    if (value is! List) {
      throw FormatException('$field must be a JSON array');
    }
    if (value.length > maxItems) {
      throw FormatException('$field exceeds the limit of $maxItems items');
    }

    return value.map((item) {
      if (item is! Map) {
        throw FormatException('$field contains a non-object value');
      }
      return item.map((key, value) => MapEntry(key.toString(), value));
    }).toList(growable: false);
  }

  String toJson() => jsonEncode(toMap());
}
