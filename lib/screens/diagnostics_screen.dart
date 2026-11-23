import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/connection_state_model.dart';
import '../providers/app_state.dart';
import '../widgets/section_card.dart';

class DiagnosticsScreen extends StatelessWidget {
  const DiagnosticsScreen({super.key});

  static const _pinScanCommand =
      'MODE=SEQUENCE;ORDER=FrontLeft,FrontRight,RearLeft,RearRight,SideLeft,SideRight,Beacon,Flood;ON=3000;OFF=500;PAUSE=1000';

  static const _gpioRows = <_GpioRow>[
    _GpioRow('Front Left', 'FrontLeft', 'GPIO16 / D16'),
    _GpioRow('Front Right', 'FrontRight', 'GPIO17 / D17'),
    _GpioRow('Rear Left', 'RearLeft', 'GPIO18 / D18'),
    _GpioRow('Rear Right', 'RearRight', 'GPIO19 / D19'),
    _GpioRow('Side Left', 'SideLeft', 'GPIO21 / D21'),
    _GpioRow('Side Right', 'SideRight', 'GPIO22 / D22'),
    _GpioRow('Beacon', 'Beacon', 'GPIO23 / D23'),
    _GpioRow('Flood', 'Flood', 'GPIO25 / D25'),
  ];

  static const _availableGpios = <int>[
    4,
    5,
    13,
    14,
    16,
    17,
    18,
    19,
    21,
    22,
    23,
    25,
    26,
    27,
    32,
    33,
  ];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnostics'),
        actions: [
          IconButton(
            tooltip: 'Clear logs',
            onPressed: state.clearLogs,
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Inventory',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Text('Devices: ${state.devices.length}'),
                Text('Profiles: ${state.profiles.length}'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Controller Config',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: state.configChannel,
                  decoration: const InputDecoration(
                    labelText: 'Channel',
                    border: OutlineInputBorder(),
                  ),
                  items: _gpioRows
                      .map(
                        (row) => DropdownMenuItem<String>(
                          value: row.command,
                          child: Text('${row.label} (${row.command})'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      state.updateConfigChannel(value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: state.configGpio,
                  decoration: const InputDecoration(
                    labelText: 'GPIO',
                    border: OutlineInputBorder(),
                  ),
                  items: _availableGpios
                      .map(
                        (gpio) => DropdownMenuItem<int>(
                          value: gpio,
                          child: Text('GPIO$gpio'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      state.updateConfigGpio(value);
                    }
                  },
                ),
                const SizedBox(height: 8),
                if (state.gpioWarning(state.configGpio) case final warning?)
                  Text(
                    warning,
                    style: TextStyle(
                      color: state.isBlockedOutputGpio(state.configGpio)
                          ? Colors.redAccent
                          : Colors.orangeAccent,
                    ),
                  )
                else
                  const Text('GPIO is suitable for output on common ESP32 DevKit boards.'),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Invert output'),
                  subtitle: const Text('Use for active-low relay or optocoupler boards.'),
                  value: state.configInverted,
                  onChanged: state.updateConfigInverted,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  initialValue: state.failSafeMs,
                  decoration: const InputDecoration(
                    labelText: 'Fail-safe timeout',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 3000, child: Text('3 seconds')),
                    DropdownMenuItem(value: 5000, child: Text('5 seconds')),
                    DropdownMenuItem(value: 10000, child: Text('10 seconds')),
                    DropdownMenuItem(value: 30000, child: Text('30 seconds')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      state.updateFailSafeMs(value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton(
                      onPressed: state.connection.status ==
                                  ControllerConnectionStatus.connected &&
                              !state.isBlockedOutputGpio(state.configGpio)
                          ? state.applyControllerGpioConfig
                          : null,
                      child: const Text('Apply GPIO'),
                    ),
                    FilledButton.tonal(
                      onPressed: state.connection.status ==
                              ControllerConnectionStatus.connected
                          ? state.applyFailSafeConfig
                          : null,
                      child: const Text('Apply Fail-safe'),
                    ),
                    FilledButton.tonal(
                      onPressed: state.connection.status ==
                              ControllerConnectionStatus.connected
                          ? state.saveControllerConfig
                          : null,
                      child: const Text('Save to ESP32'),
                    ),
                    OutlinedButton(
                      onPressed: state.connection.status ==
                              ControllerConnectionStatus.connected
                          ? state.factoryResetControllerConfig
                          : null,
                      child: const Text('Factory Reset'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Use GET_CONFIG after changes to verify what ESP32 stored.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hardware Test',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.tonal(
                      onPressed: () =>
                          state.sendRawCommand('HELLO', critical: true),
                      child: const Text('HELLO'),
                    ),
                    FilledButton.tonal(
                      onPressed: () =>
                          state.sendRawCommand('HEARTBEAT', critical: true),
                      child: const Text('HEARTBEAT'),
                    ),
                    FilledButton.tonal(
                      onPressed: () =>
                          state.sendRawCommand('GET_CONFIG', critical: true),
                      child: const Text('GET_CONFIG'),
                    ),
                    FilledButton(
                      onPressed: () => state.sendRawCommand(
                        _pinScanCommand,
                        critical: true,
                      ),
                      child: const Text('Pin Scan'),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () =>
                          state.triggerControl('all_off', 'ALL_OFF'),
                      icon: const Icon(Icons.power_settings_new),
                      label: const Text('All Off'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Pin Scan turns each output on for 3 seconds. Keep black probe on GND and move red probe across the listed pins.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GPIO Map',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                ..._gpioRows.map(
                  (row) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(child: Text(row.label)),
                        Text(row.command),
                        const SizedBox(width: 12),
                        Text(
                          row.pin,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recent Logs',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                if (state.logs.isEmpty)
                  const Text('No logs yet.')
                else
                  ...state.logs.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: SelectableText(entry),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GpioRow {
  const _GpioRow(this.label, this.command, this.pin);

  final String label;
  final String command;
  final String pin;
}
