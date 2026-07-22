import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yaru/yaru.dart';

/// A TV-optimised paired device card using Yaru UI widgets.
/// Info area and delete button are SEPARATE focus nodes for independent D-pad navigation.
class PairedDeviceCard extends StatefulWidget {
  final String deviceName;
  final String ip;
  final bool isOnline;
  final VoidCallback onRemove;

  const PairedDeviceCard({
    super.key,
    required this.deviceName,
    required this.ip,
    required this.isOnline,
    required this.onRemove,
  });

  @override
  State<PairedDeviceCard> createState() => _PairedDeviceCardState();
}

class _PairedDeviceCardState extends State<PairedDeviceCard> {
  bool _cardFocused = false;
  bool _deleteFocused = false;

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _cardFocused ? primaryColor : Colors.white10,
            width: _cardFocused ? 2 : 1,
          ),
          boxShadow: _cardFocused
              ? [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        child: YaruListTile(
          leading: Focus(
            onFocusChange: (f) => setState(() => _cardFocused = f),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(YaruIcons.phone, color: primaryColor, size: 24),
            ),
          ),
          title: Row(
            children: [
              Flexible(
                child: Text(
                  widget.deviceName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    overflow: TextOverflow.ellipsis,
                  ),
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.isOnline ? Colors.greenAccent : Colors.grey,
                ),
              ),
            ],
          ),
          subtitle: Text(
            widget.isOnline ? widget.ip : 'Offline',
            style: TextStyle(
              color: widget.isOnline ? Colors.grey : Colors.grey.shade600,
              fontSize: 13,
            ),
          ),
          trailing: Focus(
            onFocusChange: (f) => setState(() => _deleteFocused = f),
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent &&
                  (event.logicalKey == LogicalKeyboardKey.select ||
                      event.logicalKey == LogicalKeyboardKey.enter ||
                      event.logicalKey == LogicalKeyboardKey.gameButtonA)) {
                widget.onRemove();
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: GestureDetector(
              onTap: widget.onRemove,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _deleteFocused
                      ? Colors.redAccent.withValues(alpha: 0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: _deleteFocused
                      ? Border.all(color: Colors.white, width: 2)
                      : Border.all(color: Colors.white12),
                ),
                child: Icon(
                  YaruIcons.trash,
                  color: _deleteFocused ? Colors.white : Colors.redAccent,
                  size: 22,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
