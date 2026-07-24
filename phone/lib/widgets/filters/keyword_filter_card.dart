import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';

import '../../providers/phone_providers.dart';

/// Card for managing blocked keywords using Yaru UI widgets.
class KeywordFilterCard extends ConsumerStatefulWidget {
  const KeywordFilterCard({super.key});

  @override
  ConsumerState<KeywordFilterCard> createState() => _KeywordFilterCardState();
}

class _KeywordFilterCardState extends ConsumerState<KeywordFilterCard> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addKeyword(String val) async {
    final settings = ref.read(settingsProvider).value;
    if (settings == null) return;

    final trimmed = val.trim();
    if (trimmed.isEmpty || settings.blockedKeywords.contains(trimmed)) {
      return;
    }
    final updated = List<String>.from(settings.blockedKeywords)..add(trimmed);
    ref
        .read(settingsProvider.notifier)
        .updateSettings(settings.copyWith(blockedKeywords: updated));
    _controller.clear();
  }

  void _removeKeyword(String kw) async {
    final settings = ref.read(settingsProvider).value;
    if (settings == null) return;

    final updated = List<String>.from(settings.blockedKeywords)..remove(kw);
    ref
        .read(settingsProvider.notifier)
        .updateSettings(settings.copyWith(blockedKeywords: updated));
  }

  @override
  Widget build(BuildContext context) {
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
            children: [
              Icon(YaruIcons.pen),
              SizedBox(width: 8),
              Text('Blocked Keywords'),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 16,
              children: [
                const Text(
                  'Notifications containing these keywords will not be sent to TV.',
                ),
                Row(
                  spacing: 8,
                  children: [
                    Expanded(
                        child: YaruSearchField(
                        controller: _controller,
                        hintText: 'e.g., spam, discount, OTP',
                        onChanged: (v) => setState(() {}),
                        onClear: () {
                          _controller.clear();
                          setState(() {});
                        },
                        onSubmitted: (v) {
                          if (v != null) _addKeyword(v);
                        },
                      ),
                    ),
                    IconButton.filled(
                      onPressed: () => _addKeyword(_controller.text),
                      icon: const Icon(YaruIcons.plus),
                    ),
                  ],
                ),
                if (settings.blockedKeywords.isNotEmpty) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: settings.blockedKeywords.map((kw) {
                      return InputChip(
                        label: Text(kw),
                        onDeleted: () => _removeKeyword(kw),
                        deleteIcon: const Icon(YaruIcons.minus),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
