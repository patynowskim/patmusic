import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'audio_provider.dart';

class AudioEffectsSheet extends StatelessWidget {
  const AudioEffectsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Audio Effects', 
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              )
            ],
          ),
          const SizedBox(height: 16),
          Consumer<AudioProvider>(
            builder: (context, provider, child) {
              return SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Magic Autoplay Queue'),
                subtitle: const Text('Play similar songs when queue ends'),
                value: provider.isAutoPlayEnabled,
                onChanged: (val) {
                  provider.toggleAutoPlay(val);
                },
              );
            },
          ),
          const Divider(),
          const SizedBox(height: 16),
          if (kIsWeb)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Advanced audio effects (Pitch, EQ, Speed) are currently not supported computationally in the web browser. Please use the Desktop or Android app.',
                      style: TextStyle(height: 1.4),
                    ),
                  ),
                ],
              ),
            )
          else
            Consumer<AudioProvider>(
              builder: (context, audio, _) => Column(
                children: [
                  _buildEffectSlider(
                    context,
                    title: 'Playback Speed',
                    value: audio.speed,
                    min: 0.5,
                    max: 2.0,
                    divisions: 60,
                    label: '${audio.speed.toStringAsFixed(1)}x',
                    onChanged: (val) => audio.setSpeed(val),
                    onReset: () => audio.setSpeed(1.0),
                    icon: Icons.speed,
                  ),
                  const SizedBox(height: 24),
                  _buildEffectSlider(
                    context,
                    title: 'Pitch Shift',
                    value: audio.pitch,
                    min: 0.5,
                    max: 2.0,
                    divisions: 60,
                    label: audio.pitch.toStringAsFixed(1),
                    onChanged: (val) => audio.setPitch(val),
                    onReset: () => audio.setPitch(1.0),
                    icon: Icons.music_note,
                  ),
                  const SizedBox(height: 24),
                  // Placeholder for future Equalizer button/sliders
                  ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    tileColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    leading: const Icon(Icons.equalizer),
                    title: const Text('Equalizer'),
                    trailing: const Text('Coming Soon', style: TextStyle(color: Colors.grey)),
                    onTap: () {
                      // Future deployment
                    },
                  )
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEffectSlider(
    BuildContext context, {
    required String title,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String label,
    required ValueChanged<double> onChanged,
    required VoidCallback onReset,
    required IconData icon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 28),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(label, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 6,
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                ),
                child: Slider(
                  value: value,
                  min: min,
                  max: max,
                  divisions: divisions,
                  label: label,
                  onChanged: onChanged,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Reset to default',
          onPressed: onReset,
          color: value != 1.0 ? Theme.of(context).colorScheme.primary : Colors.grey,
        ),
      ],
    );
  }
}
