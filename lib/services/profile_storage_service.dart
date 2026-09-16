import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/controller_profile.dart';

class ProfileStorageService {
  static const _profilesKey = 'controller_profiles';

  Future<List<ControllerProfile>> loadProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_profilesKey) ?? const [];
    final profiles = <ControllerProfile>[];

    for (final item in raw) {
      try {
        final decoded = jsonDecode(item);
        if (decoded is! Map) {
          continue;
        }
        final map = decoded.map((key, value) => MapEntry(key.toString(), value));
        profiles.add(ControllerProfile.fromMap(map));
      } on FormatException {
        // One corrupt profile must not prevent the application from starting.
      } on TypeError {
        // Older or malformed data is skipped and can be re-imported manually.
      }
    }

    return profiles;
  }

  Future<void> saveProfiles(List<ControllerProfile> profiles) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = await prefs.setStringList(
      _profilesKey,
      profiles.map((item) => item.toJson()).toList(growable: false),
    );
    if (!saved) {
      throw StateError('Failed to persist controller profiles');
    }
  }
}
