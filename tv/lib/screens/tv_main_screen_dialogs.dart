part of 'tv_main_screen.dart';

/// Confirmation dialog shown when the user tries to leave the app, clarifying
/// that the background mirror server keeps running rather than exiting entirely.
class _ExitConfirmDialog extends StatelessWidget {
  const _ExitConfirmDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          YaruDialogTitleBar(
            title: const Text('Exit TV Mirror?'),
            onClose: (_) => Navigator.pop(context, false),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 20,
              children: [
                const Text(
                  'Do you want to exit the app?\n'
                  'The WebSocket server will continue running in the background to mirror notifications.',
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  spacing: 8,
                  children: [
                    TextButton(
                      autofocus: true,
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Exit'),
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
