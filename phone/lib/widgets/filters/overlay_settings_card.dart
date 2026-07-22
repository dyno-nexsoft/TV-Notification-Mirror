import 'package:shared/shared.dart';
import '../../services/filter_service.dart';

/// Card for configuring TV overlay notification popup position and duration using Yaru UI widgets.
class OverlaySettingsCard extends StatelessWidget {
  final AppSettings settings;
  final ValueChanged<AppSettings> onChanged;

  const OverlaySettingsCard({
    super.key,
    required this.settings,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: YaruSection(
        headline: Row(
          children: [
            Icon(YaruIcons.computer),
            const SizedBox(width: 8),
            const Text('TV Overlay Settings'),
          ],
        ),
        child: Column(
          children: [
            YaruListTile(
              title: const Text(
                'Popup Position',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              trailing: DropdownButton<String>(
                value: settings.overlayPosition,
                underline: const SizedBox(),
                onChanged: (val) {
                  if (val != null) {
                    final updated = settings.copyWith(overlayPosition: val);
                    onChanged(updated);
                    FilterService.saveOverlaySettings(
                      position: val,
                      durationSeconds: settings.overlayDurationSeconds,
                    );
                  }
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
            const Divider(color: Colors.white10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text(
                        'Display Duration',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      Text(
                        '${settings.overlayDurationSeconds} seconds',
                        style: const TextStyle(color: Colors.grey),
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
                          overlayDurationSeconds: val.toInt());
                      onChanged(updated);
                      FilterService.saveOverlaySettings(
                        position: settings.overlayPosition,
                        durationSeconds: val.toInt(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
