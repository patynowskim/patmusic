import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'audio_provider.dart';

void showEqualizerSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const AdvancedEqualizerSheet(),
  );
}

class AdvancedEqualizerSheet extends StatelessWidget {
  const AdvancedEqualizerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labels = ['32', '64', '125', '250', '500', '1K', '2K', '4K', '8K', '16K'];

    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '10-Band Equalizer', 
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
            builder: (context, audio, _) {
              return TextButton.icon(
                onPressed: () => audio.resetEq(),
                icon: const Icon(Icons.refresh),
                label: const Text('Reset All Bands'),
              );
            }
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Consumer<AudioProvider>(
              builder: (context, audio, _) {
                return LayoutBuilder(
                  builder: (context, constraints) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(10, (index) {
                        final val = audio.eqBands[index];
                        return Expanded(
                          child: Column(
                            children: [
                              Text(
                                '${val > 0 ? '+' : ''}${val.toInt()}',
                                style: TextStyle(
                                  fontSize: 12, 
                                  fontWeight: val != 0 ? FontWeight.bold : FontWeight.normal,
                                  color: val != 0 ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                                )
                              ),
                              const SizedBox(height: 16),
                              Expanded(
                                child: RotatedBox(
                                  quarterTurns: 3,
                                  child: SliderTheme(
                                    data: SliderThemeData(
                                      trackShape: const RectangularSliderTrackShape(),
                                      trackHeight: 24,
                                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
                                      activeTrackColor: val != 0 ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
                                      inactiveTrackColor: theme.colorScheme.surfaceContainerHighest,
                                    ),
                                    child: Slider(
                                      value: val,
                                      min: -15.0,
                                      max: 15.0,
                                      divisions: 30, // 1dB steps
                                      onChanged: (v) => audio.setEqBand(index, v),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                labels[index], 
                                style: TextStyle(fontSize:Constraints_responsive(constraints.maxWidth), fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        );
                      }),
                    );
                  }
                );
              }
            ),
          ),
        ],
      ),
    );
  }

  double Constraints_responsive(double maxWidth) {
    if (maxWidth < 360) return 9.0;
    if (maxWidth < 400) return 10.0;
    return 12.0;
  }
}