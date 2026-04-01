import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'audio_provider.dart';
import 'equalizer_sheet.dart';

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
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  Consumer<AudioProvider>(
                    builder: (context, audio, _) => Column(
                      children: [
                _buildEffectSlider(
                  context,
                  title: 'Volume',
                  value: audio.volume,
                  min: 0.0,
                  max: 100.0,
                  divisions: 100,
                  label: '${audio.volume.toInt()}%',
                  onChanged: (val) => audio.setVolume(val),
                  onReset: () => audio.setVolume(100.0),
                  icon: Icons.volume_up,
                  defaultValue: 100.0,
                ),
                const SizedBox(height: 24),
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
                  defaultValue: 1.0,
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
                  defaultValue: 1.0,
                ),
                const SizedBox(height: 24),
                _buildEffectSlider(
                  context,
                  title: 'Bass Boost',
                  value: audio.bass,
                  min: 0.0,
                  max: 15.0,
                  divisions: 30,
                  label: '+${audio.bass.toStringAsFixed(1)}dB',
                  onChanged: (val) => audio.setBass(val),
                  onReset: () => audio.setBass(0.0),
                  icon: Icons.speaker,
                  defaultValue: 0.0,
                ),
                const SizedBox(height: 24),
                _buildEffectSlider(
                  context,
                  title: 'Treble Boost',
                  value: audio.treble,
                  min: 0.0,
                  max: 15.0,
                  divisions: 30,
                  label: '+${audio.treble.toStringAsFixed(1)}dB',
                  onChanged: (val) => audio.setTreble(val),
                  onReset: () => audio.setTreble(0.0),
                  icon: Icons.graphic_eq,
                  defaultValue: 0.0,
                ),
                const SizedBox(height: 24),
                _buildEffectSlider(
                  context,
                  title: 'Echo/Reverb',
                  value: audio.echo,
                  min: 0.0,
                  max: 1.0,
                  divisions: 10,
                  label: '${(audio.echo * 100).toInt()}%',
                  onChanged: (val) => audio.setEcho(val),
                  onReset: () => audio.setEcho(0.0),
                  icon: Icons.surround_sound,
                  defaultValue: 0.0,
                ),
                const SizedBox(height: 24),
                _buildEffectSlider(
                  context,
                  title: '3D Stereo Widen',
                  value: audio.stereoWiden,
                  min: 1.0,
                  max: 5.0,
                  divisions: 40,
                  label: '${((audio.stereoWiden - 1.0) / 4.0 * 100).toInt()}%',
                  onChanged: (val) => audio.setStereoWiden(val),
                  onReset: () => audio.setStereoWiden(1.0),
                  icon: Icons.headphones,
                  defaultValue: 1.0,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.mic_off),
                  title: const Text('Karaoke (Vocal Remover)'),
                  subtitle: const Text('Inverts center stereo channel'),
                  value: audio.karaoke,
                  onChanged: (val) => audio.toggleKaraoke(val),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.bolt),
                  title: const Text('Nightcore Preset'),
                  subtitle: const Text('Quick 1.25x Speed + Pitch boost'),
                  value: audio.nightcore,
                  onChanged: (val) => audio.toggleNightcore(val),
                ),
                
                if (kIsWeb) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 20, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Unsupported effects safely fallback to nearest browser capabilities.',
                            style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  )
                ],

                const SizedBox(height: 24),
                // Placeholder for future Equalizer button/sliders
                ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  tileColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  leading: const Icon(Icons.equalizer),
                  title: const Text('Advanced Equalizer'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(context);
                    showEqualizerSheet(context);
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
                ],
              ),
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
    required double defaultValue,
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
          color: value != defaultValue ? Theme.of(context).colorScheme.primary : Colors.grey,
        ),
      ],
    );
  }
}
