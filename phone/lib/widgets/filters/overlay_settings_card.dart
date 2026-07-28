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
      skipLoadingOnReload: true,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 8,
                  children: [
                    const Text('Popup Position'),
                    AnchorPositionPicker(
                      value: settings.overlayPosition,
                      onChanged: (val) {
                        final updated = settings.copyWith(overlayPosition: val);
                        ref
                            .read(settingsProvider.notifier)
                            .updateSettings(updated);
                      },
                    ),
                  ],
                ),
              ),
              const Divider(),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 8,
                  children: [
                    const Text('Display Duration'),
                    ValueStepper(
                      label: '${settings.overlayDurationSeconds} seconds',
                      value: settings.overlayDurationSeconds.toDouble(),
                      min: 2,
                      max: 15,
                      step: 1,
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
