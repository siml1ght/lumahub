import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/light_device.dart';
import '../providers/app_state.dart';

class DeviceEditScreen extends StatefulWidget {
  const DeviceEditScreen({
    super.key,
    required this.device,
    this.isNew = false,
  });

  final LightDevice device;
  final bool isNew;

  @override
  State<DeviceEditScreen> createState() => _DeviceEditScreenState();
}

class _DeviceEditScreenState extends State<DeviceEditScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _channelController;
  late final TextEditingController _groupController;
  late final TextEditingController _modeController;
  late final TextEditingController _channelCountController;
  late final TextEditingController _primaryOutputController;
  double _brightness = 255;
  bool _enabled = true;
  bool _inverted = false;
  LightDeviceType _type = LightDeviceType.custom;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.device.name);
    _channelController =
        TextEditingController(text: widget.device.channel.toString());
    _groupController = TextEditingController(text: widget.device.group);
    _modeController = TextEditingController(text: widget.device.mode);
    _channelCountController =
        TextEditingController(text: widget.device.channelCount.toString());
    _primaryOutputController =
        TextEditingController(text: widget.device.primaryOutput.toString());
    _brightness = widget.device.brightness.toDouble();
    _enabled = widget.device.enabled;
    _inverted = widget.device.inverted;
    _type = widget.device.type;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _channelController.dispose();
    _groupController.dispose();
    _modeController.dispose();
    _channelCountController.dispose();
    _primaryOutputController.dispose();
    super.dispose();
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isNew ? 'Add Device' : 'Edit Device'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Device Name'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<LightDeviceType>(
            initialValue: _type,
            items: LightDeviceType.values
                .map(
                  (type) => DropdownMenuItem(
                    value: type,
                    child: Text(type.name),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _type = value);
              }
            },
            decoration: const InputDecoration(labelText: 'Device Type'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _channelController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Channel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _channelCountController,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Channel Count'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _primaryOutputController,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Primary Output'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _groupController,
                  decoration: const InputDecoration(labelText: 'Group'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _modeController,
            decoration: const InputDecoration(labelText: 'Mode'),
          ),
          const SizedBox(height: 16),
          Text('Brightness ${_brightness.round()}'),
          Slider(
            value: _brightness,
            min: 0,
            max: 255,
            onChanged: (value) => setState(() => _brightness = value),
          ),
          SwitchListTile(
            value: _enabled,
            onChanged: (value) => setState(() => _enabled = value),
            title: const Text('Enabled'),
          ),
          SwitchListTile(
            value: _inverted,
            onChanged: (value) => setState(() => _inverted = value),
            title: const Text('Invert Signal'),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () {
              final channel = int.tryParse(_channelController.text);
              final channelCount = int.tryParse(_channelCountController.text);
              final primaryOutput = int.tryParse(_primaryOutputController.text);

              if (_nameController.text.trim().isEmpty) {
                _showError(context, 'Device name is required');
                return;
              }
              if (channel == null || channel < 1) {
                _showError(context, 'Channel must be a number greater than 0');
                return;
              }
              if (channelCount == null || channelCount < 1) {
                _showError(context, 'Channel count must be at least 1');
                return;
              }
              if (primaryOutput == null || primaryOutput < 1) {
                _showError(context, 'Primary output must be at least 1');
                return;
              }

              final updated = widget.device.copyWith(
                name: _nameController.text.trim(),
                type: _type,
                channel: channel,
                group: _groupController.text.trim(),
                enabled: _enabled,
                inverted: _inverted,
                brightness: _brightness.round(),
                mode: _modeController.text.trim(),
                channelCount: channelCount,
                primaryOutput: primaryOutput,
              );

              state.upsertDevice(updated);
              Navigator.of(context).pop();
            },
            child: const Text('Save device'),
          ),
        ],
      ),
    );
  }
}
