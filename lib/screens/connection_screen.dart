import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/connection_state_model.dart';
import '../providers/app_state.dart';
import '../widgets/section_card.dart';
import '../widgets/status_badge.dart';

class ConnectionScreen extends StatelessWidget {
  const ConnectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final statusColor = switch (state.connection.status) {
      ControllerConnectionStatus.connected => Colors.greenAccent,
      ControllerConnectionStatus.error => Colors.redAccent,
      ControllerConnectionStatus.scanning ||
      ControllerConnectionStatus.connecting => Colors.orangeAccent,
      ControllerConnectionStatus.disconnected => Colors.blueGrey,
    };

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'LumaHub Connection',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      state.connection.controllerName,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  StatusBadge(
                    label: state.connection.status.name,
                    color: statusColor,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(state.connection.message),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: state.isBusy ? null : state.scanControllers,
                      child: const Text('Scan Controllers'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: state.connection.status ==
                              ControllerConnectionStatus.connected
                          ? state.disconnect
                          : null,
                      child: const Text('Disconnect'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text('Signal: ${state.connection.signalStrength}%'),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: state.connection.signalStrength / 100,
                minHeight: 8,
                borderRadius: BorderRadius.circular(999),
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
                'Available Controllers',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Text(
                'Expected device: LumaHub-ESP32. If Android shows it in Bluetooth settings, do not pair there: connect from this screen.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              if (state.discoveredControllers.isEmpty)
                const Text('No controllers discovered yet.')
              else
                ...state.discoveredControllers.map(
                  (controller) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const CircleAvatar(
                                child: Icon(Icons.memory_outlined),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      controller,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      state.useMockMode
                                          ? 'Mock BLE transport'
                                          : 'BLE transport',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.tonal(
                              onPressed: () => state.connect(controller),
                              child: const Text('Connect'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
