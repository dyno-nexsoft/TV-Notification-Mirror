import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:yaru/yaru.dart';

import '../services/battery_optimization_service.dart';
import 'adb_instructions_dialog.dart';

/// Settings section showing whether the app is exempt from battery
/// optimization. Aggressive OEM ROMs (MIUI, ColorOS, EMUI...) kill background
/// services unless the user whitelists the app, so this surfaces the status
/// and opens the system exemption dialog on tap. Identical on Phone & TV.
class BatteryOptimizationSection extends StatefulWidget {
  const BatteryOptimizationSection({super.key});

  @override
  State<BatteryOptimizationSection> createState() =>
      _BatteryOptimizationSectionState();
}

class _BatteryOptimizationSectionState extends State<BatteryOptimizationSection> {
  bool? _isIgnoring;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final ignoring =
        await BatteryOptimizationService.isIgnoringBatteryOptimizations();
    if (mounted) setState(() => _isIgnoring = ignoring);
  }

  Future<void> _requestWhitelist() async {
    final opened =
        await BatteryOptimizationService.requestIgnoreBatteryOptimizations();
    if (!opened && mounted) {
      await _showAdbGuide();
    }
    await _refresh();
  }

  Future<void> _openSettings() async {
    final opened =
        await BatteryOptimizationService.openBatteryOptimizationSettings();
    if (!opened && mounted) {
      await _showAdbGuide();
    }
    await _refresh();
  }

  /// Guides the user through whitelisting over ADB when the device has no
  /// battery-optimization settings screen (e.g. Fire TV).
  Future<void> _showAdbGuide() async {
    final packageName = (await PackageInfo.fromPlatform()).packageName;
    if (!mounted) return;
    await AdbInstructionsDialog.show(
      context,
      title: 'Grant whitelist via ADB',
      message: 'This device has no battery-optimization settings screen. '
          'Enable Developer Options → ADB debugging on the device, then run '
          'these commands from a computer on the same network:',
      steps: [
        'adb connect <DEVICE_IP>:5555',
        'adb shell dumpsys deviceidle whitelist +$packageName',
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isIgnoring = _isIgnoring;
    final statusColor = isIgnoring == true
        ? theme.colorScheme.primary
        : theme.colorScheme.error;

    return YaruSection(
      headline: const Text('BACKGROUND ACTIVITY'),
      child: Column(
        children: [
          YaruListTile(
            leading: const Icon(YaruIcons.shield),
            title: const Text('Battery Optimization'),
            subtitle: Text(
              isIgnoring == true
                  ? 'Exempt — the OS won\'t stop the background service for power saving.'
                  : 'Optimized — the OS may stop the background service. Tap to allow.',
            ),
            trailing: Icon(
              isIgnoring == true ? YaruIcons.ok_simple : YaruIcons.warning,
              color: statusColor,
            ),
            onTap: _requestWhitelist,
          ),
          if (isIgnoring != true)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                spacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _openSettings,
                    icon: const Icon(YaruIcons.settings),
                    label: const Text('Open Settings'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
