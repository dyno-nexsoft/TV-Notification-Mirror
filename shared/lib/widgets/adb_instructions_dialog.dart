import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yaru/yaru.dart';

/// Modal that walks the user through granting a permission over ADB when the
/// device has no UI for it — e.g. Fire TV lacks a "Display over other apps"
/// screen and some OEM ROMs lack a battery-optimization settings page. Each
/// command renders as a copyable monospace block.
class AdbInstructionsDialog extends StatelessWidget {
  const AdbInstructionsDialog({
    super.key,
    required this.title,
    required this.message,
    required this.steps,
  });

  final String title;
  final String message;
  final List<String> steps;

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    required List<String> steps,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => AdbInstructionsDialog(
        title: title,
        message: message,
        steps: steps,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            YaruDialogTitleBar(
              title: Text(title),
              onClose: (_) => Navigator.pop(context),
            ),
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 16,
                  children: [
                    Text(message),
                    for (final step in steps) _CommandBlock(command: step),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        FilledButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommandBlock extends StatelessWidget {
  const _CommandBlock({required this.command});

  final String command;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SelectableText(
            command,
            style: const TextStyle(fontFamily: 'monospace'),
          ),
        ),
        IconButton(
          tooltip: 'Copy',
          onPressed: () => Clipboard.setData(ClipboardData(text: command)),
          icon: const Icon(YaruIcons.copy),
        ),
      ],
    );
  }
}