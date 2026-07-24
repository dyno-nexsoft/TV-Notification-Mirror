import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';

import '../../providers/phone_providers.dart';

/// Card for configuring TV overlay notification popup position and duration using Yaru UI widgets.
class OverlaySettingsCard extends ConsumerWidget {
  const OverlaySettingsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncSettings = ref.watch(settingsProvider);

    return asyncSettings.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, st) => Center(child: Text('Error: $e')),
      data: (settings) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: YaruSection(
          headline: const Row(
            spacing: 8,
            children: [
              Icon(YaruIcons.computer),
              Text('TV Overlay Settings'),
            ],
          ),
          child: Column(
            children: [
              YaruListTile(
                title: const Text('Popup Position'),
                trailing: DropdownButton<String>(
                  value: settings.overlayPosition,
                  underline: const SizedBox(),
                  onChanged: (val) {
                    if (val == null) return;
                    final updated = settings.copyWith(overlayPosition: val);
                    ref.read(settingsProvider.notifier).updateSettings(updated);
                  },
                  items: const [
                    DropdownMenuItem(
                      value: MirrorProtocol.overlayTopRight,
                      child: Text('Top Right'),
                    ),
                    DropdownMenuItem(
                      value: MirrorProtocol.overlayTopLeft,
                      child: Text('Top Left'),
                    ),
                    DropdownMenuItem(
                      value: MirrorProtocol.overlayBottomRight,
                      child: Text('Bottom Right'),
                    ),
                    DropdownMenuItem(
                      value: MirrorProtocol.overlayBottomLeft,
                      child: Text('Bottom Left'),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Text('Display Duration'),
                        const Spacer(),
                        Text(
                          '${settings.overlayDurationSeconds} seconds',
                        ),
                      ],
                    ),
                    Slider(
                      min: 2,
                      max: 15,
                      divisions: 13,
                      label: '${settings.overlayDurationSeconds} s',
                      value: settings.overlayDurationSeconds.toDouble(),
                      onChanged: (val) {
                        final updated = settings.copyWith(
                          overlayDurationSeconds: val.toInt(),
                        );
                        ref
                            .read(settingsProvider.notifier)
                            .updateSettings(updated);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
