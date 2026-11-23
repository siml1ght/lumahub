import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/connection_state_model.dart';
import '../providers/app_state.dart';

class ManualControlScreen extends StatelessWidget {
  const ManualControlScreen({super.key});

  static const List<_ZoneControl> _controls = <_ZoneControl>[
    _ZoneControl(
      keyName: 'front_left',
      label: 'Front left',
      icon: Icons.lightbulb_outline,
      channelName: 'FrontLeft',
      gpioLabel: 'GPIO16',
    ),
    _ZoneControl(
      keyName: 'front_right',
      label: 'Front right',
      icon: Icons.lightbulb_outline,
      channelName: 'FrontRight',
      gpioLabel: 'GPIO17',
    ),
    _ZoneControl(
      keyName: 'rear_left',
      label: 'Rear left',
      icon: Icons.lightbulb_outline,
      channelName: 'RearLeft',
      gpioLabel: 'GPIO18',
    ),
    _ZoneControl(
      keyName: 'rear_right',
      label: 'Rear right',
      icon: Icons.lightbulb_outline,
      channelName: 'RearRight',
      gpioLabel: 'GPIO19',
    ),
    _ZoneControl(
      keyName: 'side_left',
      label: 'Side left',
      icon: Icons.linear_scale,
      channelName: 'SideLeft',
      gpioLabel: 'GPIO21',
    ),
    _ZoneControl(
      keyName: 'side_right',
      label: 'Side right',
      icon: Icons.linear_scale,
      channelName: 'SideRight',
      gpioLabel: 'GPIO22',
    ),
    _ZoneControl(
      keyName: 'beacon',
      label: 'Beacon',
      icon: Icons.wb_incandescent_outlined,
      channelName: 'Beacon',
      gpioLabel: 'GPIO23',
    ),
    _ZoneControl(
      keyName: 'flood',
      label: 'Flood',
      icon: Icons.sunny,
      channelName: 'Flood',
      gpioLabel: 'GPIO25',
    ),
  ];

  static const List<_GroupControl> _groupControls = <_GroupControl>[
    _GroupControl(
      keyName: 'group_front',
      label: 'Front group',
      groupName: 'FRONT',
      icon: Icons.flip_to_front,
    ),
    _GroupControl(
      keyName: 'group_rear',
      label: 'Rear group',
      groupName: 'REAR',
      icon: Icons.flip_to_back,
    ),
    _GroupControl(
      keyName: 'group_side',
      label: 'Side group',
      groupName: 'SIDE',
      icon: Icons.view_sidebar_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live control'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Icon(
                    state.connection.status == ControllerConnectionStatus.connected
                        ? Icons.bluetooth_connected
                        : Icons.bluetooth_disabled,
                    color: state.connection.status ==
                            ControllerConnectionStatus.connected
                        ? Colors.greenAccent
                        : colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      state.connection.status == ControllerConnectionStatus.connected
                          ? 'Connected to ${state.connection.controllerName}'
                          : 'Not connected. Controls will queue offline.',
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
              children: [
                Text(
                  'Channels',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _controls.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 2.0,
                  ),
                  itemBuilder: (context, index) {
                    final control = _controls[index];
                    final active = state.activeControlKeys.contains(control.keyName);
                    final command = '${control.channelName}=${active ? 'OFF' : 'ON'}';
                    return _ZoneTile(
                      label: control.label,
                      subtitle: '${control.channelName} · ${control.gpioLabel}',
                      icon: control.icon,
                      active: active,
                      onTap: () => state.triggerControl(control.keyName, command),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  'Groups',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                ..._groupControls.map(
                  (group) {
                    final active = state.activeControlKeys.contains(group.keyName);
                    final command =
                        'MODE=${active ? 'OFF' : 'ON'};GROUP=${group.groupName}';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _GroupButton(
                        label: group.label,
                        icon: group.icon,
                        active: active,
                        onTap: () => state.triggerControl(group.keyName, command),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: state.connection.status ==
                          ControllerConnectionStatus.connected
                      ? () => _confirmPinScan(context, state)
                      : null,
                  icon: const Icon(Icons.troubleshoot),
                  label: const Text('Pin scan'),
                ),
                const SizedBox(height: 8),
                Text(
                  'Energizes GPIO16, 17, 18, 19, 21, 22, 23 and 25 one by one. Set your multimeter to DC V 20.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => state.triggerControl('all_off', 'ALL_OFF'),
        icon: const Icon(Icons.power_settings_new),
        label: const Text('All off'),
      ),
    );
  }

  Future<void> _confirmPinScan(
    BuildContext context,
    AppState state,
  ) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Start pin scan?'),
            content: const Text(
              'Energizes each output for 3 seconds, from GPIO16 through GPIO25. '
              'Disconnect any loads before continuing.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Start scan'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !context.mounted) {
      return;
    }
    await state.sendRawCommand(
      'MODE=SEQUENCE;ORDER=FrontLeft,FrontRight,RearLeft,RearRight,SideLeft,SideRight,Beacon,Flood;ON=3000;OFF=500;PAUSE=1000',
      critical: true,
    );
  }
}

class _ZoneTile extends StatelessWidget {
  const _ZoneTile({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = colorScheme.primary;

    return Material(
      color: active
          ? accent.withValues(alpha: 0.25)
          : colorScheme.surfaceContainerHighest.withValues(alpha: 0.22),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: active ? accent : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              Text(
                active ? 'On' : 'Off',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: active ? accent : colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GroupButton extends StatelessWidget {
  const _GroupButton({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: onTap,
      icon: Icon(icon),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        backgroundColor: active
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.25)
            : null,
      ),
      label: Text(active ? '$label (ON)' : label),
    );
  }
}

class _ZoneControl {
  const _ZoneControl({
    required this.keyName,
    required this.label,
    required this.icon,
    required this.channelName,
    required this.gpioLabel,
  });

  final String keyName;
  final String label;
  final IconData icon;
  final String channelName;
  final String gpioLabel;
}

class _GroupControl {
  const _GroupControl({
    required this.keyName,
    required this.label,
    required this.groupName,
    required this.icon,
  });

  final String keyName;
  final String label;
  final String groupName;
  final IconData icon;
}
