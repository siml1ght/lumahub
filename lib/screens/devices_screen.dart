import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/light_device.dart';
import '../providers/app_state.dart';
import '../widgets/device_card.dart';
import 'device_edit_screen.dart';

class DevicesScreen extends StatelessWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Light Devices'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final draft = state.buildDraftDevice();
          await Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => DeviceEditScreen(device: draft, isNew: true),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Device'),
      ),
      body: state.devices.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lightbulb_outline, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'No devices yet',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Add a device to map its channel and GPIO output.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: state.devices.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final device = state.devices[index];
                return DeviceCard(
                  device: device,
                  onEdit: () => _openEditor(context, device),
                  onDelete: () => state.deleteDevice(device.id),
                  onToggle: () => state.toggleDevice(device.id),
                );
              },
            ),
    );
  }

  Future<void> _openEditor(BuildContext context, LightDevice device) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DeviceEditScreen(device: device),
      ),
    );
  }
}
