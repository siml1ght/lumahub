import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../widgets/section_card.dart';

class PatternsScreen extends StatelessWidget {
  const PatternsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Effects & Patterns',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        ...state.patterns.map(
          (pattern) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          pattern.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      Switch(
                        value: state.selectedPatternId == pattern.id,
                        onChanged: (_) => state.activatePattern(pattern.id),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _PatternSlider(
                    label: 'Speed',
                    value: pattern.speed,
                    min: 0.2,
                    max: 2.0,
                    divisions: 18,
                    onChanged: (value) => state.updatePattern(
                      pattern.copyWith(speed: value),
                    ),
                  ),
                  _PatternSlider(
                    label: 'Pause ${pattern.pauseMs} ms',
                    value: pattern.pauseMs.toDouble(),
                    min: 20,
                    max: 500,
                    divisions: 48,
                    onChanged: (value) => state.updatePattern(
                      pattern.copyWith(pauseMs: value.round()),
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('Sync'),
                        selected: pattern.syncEnabled,
                        onSelected: (value) => state.updatePattern(
                          pattern.copyWith(syncEnabled: value),
                        ),
                      ),
                      FilterChip(
                        label: const Text('Alternating'),
                        selected: pattern.alternating,
                        onSelected: (value) => state.updatePattern(
                          pattern.copyWith(alternating: value),
                        ),
                      ),
                      FilterChip(
                        label: const Text('Random'),
                        selected: pattern.randomMode,
                        onSelected: (value) => state.updatePattern(
                          pattern.copyWith(randomMode: value),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PatternSlider extends StatelessWidget {
  const _PatternSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: divisions,
          label: value.round().toString(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
