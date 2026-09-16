import 'dart:convert';

class PatternConfig {
  const PatternConfig({
    required this.id,
    required this.name,
    required this.speed,
    required this.pauseMs,
    required this.syncEnabled,
    required this.alternating,
    required this.randomMode,
  });

  final String id;
  final String name;
  final double speed;
  final int pauseMs;
  final bool syncEnabled;
  final bool alternating;
  final bool randomMode;

  PatternConfig copyWith({
    String? id,
    String? name,
    double? speed,
    int? pauseMs,
    bool? syncEnabled,
    bool? alternating,
    bool? randomMode,
  }) {
    return PatternConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      speed: speed ?? this.speed,
      pauseMs: pauseMs ?? this.pauseMs,
      syncEnabled: syncEnabled ?? this.syncEnabled,
      alternating: alternating ?? this.alternating,
      randomMode: randomMode ?? this.randomMode,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'speed': speed,
      'pauseMs': pauseMs,
      'syncEnabled': syncEnabled,
      'alternating': alternating,
      'randomMode': randomMode,
    };
  }

  factory PatternConfig.fromMap(Map<String, dynamic> map) {
    final id = map['id'];
    final name = map['name'];
    if (id is! String || id.trim().isEmpty) {
      throw const FormatException('Pattern id must be a non-empty string');
    }
    if (name is! String || name.trim().isEmpty) {
      throw const FormatException('Pattern name must be a non-empty string');
    }

    final speed = (map['speed'] as num?)?.toDouble() ?? 1;
    final pauseMs = (map['pauseMs'] as num?)?.toInt() ?? 100;
    if (!speed.isFinite || speed < 0.1 || speed > 10) {
      throw const FormatException('Pattern speed must be between 0.1 and 10');
    }
    if (pauseMs < 20 || pauseMs > 60000) {
      throw const FormatException('Pattern pause must be between 20 and 60000 ms');
    }

    return PatternConfig(
      id: id.trim(),
      name: name.trim(),
      speed: speed,
      pauseMs: pauseMs,
      syncEnabled: map['syncEnabled'] as bool? ?? true,
      alternating: map['alternating'] as bool? ?? false,
      randomMode: map['randomMode'] as bool? ?? false,
    );
  }

  String toJson() => jsonEncode(toMap());
}
