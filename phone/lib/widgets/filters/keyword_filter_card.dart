import 'package:shared/shared.dart';
import '../../services/filter_service.dart';

/// Card for managing blocked keywords using Yaru UI widgets.
class KeywordFilterCard extends StatefulWidget {
  final AppSettings settings;
  final ValueChanged<AppSettings> onChanged;

  const KeywordFilterCard({
    super.key,
    required this.settings,
    required this.onChanged,
  });

  @override
  State<KeywordFilterCard> createState() => _KeywordFilterCardState();
}

class _KeywordFilterCardState extends State<KeywordFilterCard> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addKeyword(String val) {
    final trimmed = val.trim();
    if (trimmed.isEmpty || widget.settings.blockedKeywords.contains(trimmed)) {
      return;
    }
    final updated = List<String>.from(widget.settings.blockedKeywords)
      ..add(trimmed);
    widget.onChanged(widget.settings.copyWith(blockedKeywords: updated));
    FilterService.saveBlockedKeywords(updated);
    _controller.clear();
  }

  void _removeKeyword(String kw) {
    final updated = List<String>.from(widget.settings.blockedKeywords)
      ..remove(kw);
    widget.onChanged(widget.settings.copyWith(blockedKeywords: updated));
    FilterService.saveBlockedKeywords(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: YaruSection(
        headline: Row(
          children: [
            Icon(YaruIcons.pen, color: Colors.orange),
            const SizedBox(width: 8),
            const Text('Blocked Keywords'),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Notifications containing these keywords will not be sent to TV.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'e.g., spam, discount, OTP',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      onSubmitted: _addKeyword,
                    ),
                  ),
                  const SizedBox(width: 8),
                  YaruOptionButton(
                    onPressed: () => _addKeyword(_controller.text),
                    child: const Text('Add'),
                  ),
                ],
              ),
              if (widget.settings.blockedKeywords.isNotEmpty) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.settings.blockedKeywords.map((kw) {
                    return YaruOptionButton(
                      onPressed: () => _removeKeyword(kw),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(kw),
                          const SizedBox(width: 4),
                          Icon(YaruIcons.minus, size: 14),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
