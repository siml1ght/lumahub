import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../app/app_config.dart';
import '../models/controller_profile.dart';

class ProfileExchangeService {
  Future<ControllerProfile?> importProfile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      return null;
    }

    final file = result.files.single;
    if (file.size > AppConfig.maxProfileFileBytes) {
      throw const FormatException('Profile file exceeds the 512 KiB limit');
    }
    final bytes = file.bytes;
    if (bytes == null) {
      throw const FormatException('Unable to read the selected profile file');
    }

    final value = jsonDecode(utf8.decode(bytes));
    if (value is! Map) {
      throw const FormatException('Profile root must be a JSON object');
    }
    final map = value.map((key, value) => MapEntry(key.toString(), value));
    return ControllerProfile.fromMap(map);
  }

  Future<void> exportProfile(ControllerProfile profile) {
    final json = const JsonEncoder.withIndent('  ').convert(profile.toMap());
    final safeName = profile.name
        .replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^[_\.]+|[_\.]+$'), '');
    final fileName = safeName.isEmpty ? 'lumahub-profile' : safeName;

    return Share.shareXFiles(
      [
        XFile.fromData(
          utf8.encode(json),
          mimeType: 'application/json',
          name: '$fileName.json',
        ),
      ],
      text: 'LumaHub controller profile',
    );
  }
}
