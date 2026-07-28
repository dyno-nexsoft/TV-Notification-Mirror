import '../shared.dart';

/// The Call/Text/Image-preview category toggles + Alert Sound picker row,
/// shared verbatim between the TV and Phone apps' notification settings —
/// each app wires the values/callbacks to its own settings provider and
/// enforces the resulting choice at its own layer (TV server-side on
/// receipt, Phone client-side before sending).
class NotificationCategoryToggles extends StatelessWidget {
  const NotificationCategoryToggles({
    super.key,
    required this.callEnabled,
    required this.onCallChanged,
    required this.textEnabled,
    required this.onTextChanged,
    required this.imagePreviewsEnabled,
    required this.onImagePreviewsChanged,
    required this.alertSoundLabel,
    required this.onPickAlertSound,
  });

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
    return Column(
      children: [
        YaruSwitchListTile(
          secondary: const Icon(YaruIcons.headset),
          title: const Text('Call Notifications'),
          value: callEnabled,
          onChanged: onCallChanged,
        ),
        YaruSwitchListTile(
          secondary: const Icon(YaruIcons.chat_bubble),
          title: const Text('Text Messages'),
          value: textEnabled,
          onChanged: onTextChanged,
        ),
        YaruSwitchListTile(
          secondary: const Icon(YaruIcons.image),
          title: const Text('Image Previews'),
          value: imagePreviewsEnabled,
          onChanged: onImagePreviewsChanged,
        ),
        YaruListTile(
          leading: const Icon(YaruIcons.notification),
          title: const Text('Alert Sound'),
          trailing: Text(alertSoundLabel),
          onTap: onPickAlertSound,
        ),
      ],
    );
  }
}
