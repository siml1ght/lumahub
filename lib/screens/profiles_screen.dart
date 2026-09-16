import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/controller_profile.dart';
import '../providers/app_state.dart';
import '../widgets/section_card.dart';

class ProfilesScreen extends StatelessWidget {
  const ProfilesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Profiles')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () => _showSaveDialog(context),
                  child: const Text('Save Current Profile'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _importProfile(context),
                  child: const Text('Import JSON'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (state.profiles.isEmpty)
            const SectionCard(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    Icon(Icons.folder_off_outlined, size: 36),
                    SizedBox(height: 12),
                    Text('No saved profiles'),
                    SizedBox(height: 4),
                    Text('Save the current setup or import a LumaHub JSON profile.'),
                  ],
                ),
              ),
            )
          else
            ...state.profiles.map(
              (profile) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${profile.devices.length} devices · Updated ${_formatDate(profile.lastUpdated)}',
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton(
                            onPressed: () => state.loadProfile(profile.name),
                            child: const Text('Load'),
                          ),
                          FilledButton.tonal(
                            onPressed: () => _confirmDelete(context, profile),
                            child: const Text('Delete'),
                          ),
                          IconButton(
                            tooltip: 'Export JSON',
                            onPressed: () => _exportProfile(context, profile),
                            icon: const Icon(Icons.ios_share_outlined),
                          ),
                          IconButton(
                            tooltip: 'View JSON',
                            onPressed: () => _showJson(context, profile),
                            icon: const Icon(Icons.code_outlined),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _importProfile(BuildContext context) async {
    final state = context.read<AppState>();
    try {
      await state.importProfile();
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile import completed')),
      );
    } on Object catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import failed: $error')),
      );
    }
  }

  Future<void> _exportProfile(
    BuildContext context,
    ControllerProfile profile,
  ) async {
    try {
      await context.read<AppState>().exportProfile(profile);
    } on Object catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $error')),
      );
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    ControllerProfile profile,
  ) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Delete profile?'),
            content: Text('“${profile.name}” will be removed from this device.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !context.mounted) {
      return;
    }

    try {
      await context.read<AppState>().deleteProfile(profile.name);
    } on Object catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $error')),
      );
    }
  }

  void _showJson(BuildContext context, ControllerProfile profile) {
    final json = const JsonEncoder.withIndent('  ').convert(profile.toMap());
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Profile JSON'),
        content: SingleChildScrollView(child: SelectableText(json)),
      ),
    );
  }

  Future<void> _showSaveDialog(BuildContext context) async {
    final controller = TextEditingController();
    final state = context.read<AppState>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Save Profile'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 80,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(labelText: 'Profile name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) {
                return;
              }
              try {
                await state.saveCurrentProfile(name);
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              } on Object catch (error) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Save failed: $error')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
  }

  static String _formatDate(DateTime value) {
    final local = value.toLocal();
    String twoDigits(int number) => number.toString().padLeft(2, '0');
    return '${local.year}-${twoDigits(local.month)}-${twoDigits(local.day)} '
        '${twoDigits(local.hour)}:${twoDigits(local.minute)}';
  }
}
