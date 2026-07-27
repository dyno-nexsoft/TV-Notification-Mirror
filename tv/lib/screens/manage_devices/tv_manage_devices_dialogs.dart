part of 'tv_manage_devices_screen.dart';

/// Confirmation dialog shown before unpairing a device, to guard against
/// accidental taps on the D-pad remote.
class _RemoveDeviceDialog extends StatelessWidget {
  const _RemoveDeviceDialog({
    required this.deviceName,
    required this.onConfirm,
  });

  final String deviceName;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          YaruDialogTitleBar(
            title: const Text('Remove Device'),
            onClose: (_) => Navigator.pop(context),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 20,
              children: [
                Text('Remove "$deviceName" from paired devices?'),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  spacing: 8,
                  children: [
                    TextButton(
                      autofocus: true,
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: onConfirm,
                      child: const Text('Remove'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Dialog for renaming a paired device.
class _RenameDeviceDialog extends StatefulWidget {
  const _RenameDeviceDialog({
    required this.currentName,
    required this.onConfirm,
  });

  final String currentName;
  final ValueChanged<String> onConfirm;

  @override
  State<_RenameDeviceDialog> createState() => _RenameDeviceDialogState();
}

class _RenameDeviceDialogState extends State<_RenameDeviceDialog> {
  late final _controller = TextEditingController(text: widget.currentName);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          YaruDialogTitleBar(
            title: const Text('Rename Device'),
            onClose: (_) => Navigator.pop(context),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 20,
              children: [
                TextField(
                  controller: _controller,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Device name'),
                  onSubmitted: widget.onConfirm,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  spacing: 8,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => widget.onConfirm(_controller.text),
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
