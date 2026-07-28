import '../shared.dart';

/// The "NOTIFICATION PREFERENCES" card — an optional [leading] widget (e.g.
/// the Phone app's master mirror switch, which has no TV equivalent) above
/// the shared Call/Text/Image-preview toggles + Alert Sound row. Used
/// identically by the TV and Phone apps' settings screens.
class NotificationPreferencesCard extends StatelessWidget {
  const NotificationPreferencesCard({
    super.key,
    this.leading,
    required this.callEnabled,
    required this.onCallChanged,
    required this.textEnabled,
    required this.onTextChanged,
    required this.imagePreviewsEnabled,
    required this.onImagePreviewsChanged,
    required this.alertSoundLabel,
    required this.onPickAlertSound,
  });

  final Widget? leading;
  final bool callEnabled;
  final ValueChanged<bool> onCallChanged;
  final bool textEnabled;
  final ValueChanged<bool> onTextChanged;
  final bool imagePreviewsEnabled;
  final ValueChanged<bool> onImagePreviewsChanged;
  final String alertSoundLabel;
  final VoidCallback onPickAlertSound;

  @override
  Widget build(BuildContext context) {
    return YaruSection(
      headline: const Text('NOTIFICATION PREFERENCES'),
      child: Column(
        children: [
          if (leading != null) ...[leading!, const Divider()],
          NotificationCategoryToggles(
            callEnabled: callEnabled,
            onCallChanged: onCallChanged,
            textEnabled: textEnabled,
            onTextChanged: onTextChanged,
            imagePreviewsEnabled: imagePreviewsEnabled,
            onImagePreviewsChanged: onImagePreviewsChanged,
            alertSoundLabel: alertSoundLabel,
            onPickAlertSound: onPickAlertSound,
          ),
        ],
      ),
    );
  }
}
