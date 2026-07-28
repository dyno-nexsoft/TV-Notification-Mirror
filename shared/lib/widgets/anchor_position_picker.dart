import '../shared.dart';

/// 2x2 grid to pick which screen corner the overlay toast anchors to.
/// Only 4 positions exist in [MirrorProtocol] (the real anchors the overlay
/// supports) — no fake center/edge cells that wouldn't do anything.
///
/// Each cell draws a small "mini screen" outline with a dot placed at the
/// corresponding corner, so the option is legible on sight — a single
/// generic icon repeated in every cell (the first version of this widget)
/// looked identical everywhere and gave no clue which corner was which.
class AnchorPositionPicker extends StatelessWidget {
  const AnchorPositionPicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  static const _positions = [
    MirrorProtocol.overlayTopLeft,
    MirrorProtocol.overlayTopRight,
    MirrorProtocol.overlayBottomLeft,
    MirrorProtocol.overlayBottomRight,
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [
        for (var row = 0; row < 2; row++)
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 8,
            children: [
              for (final position in _positions.skip(row * 2).take(2))
                SizedBox(
                  width: 72,
                  height: 44,
                  child: YaruSelectableContainer(
                    selected: value == position,
                    onTap: () => onChanged(position),
                    child: _MiniScreen(
                      dotAt: _alignmentFor(position),
                      selected: value == position,
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Alignment _alignmentFor(String position) {
    return switch (position) {
      MirrorProtocol.overlayTopLeft => Alignment.topLeft,
      MirrorProtocol.overlayTopRight => Alignment.topRight,
      MirrorProtocol.overlayBottomLeft => Alignment.bottomLeft,
      MirrorProtocol.overlayBottomRight => Alignment.bottomRight,
      _ => Alignment.center,
    };
  }
}

/// A tiny screen-shaped outline with a dot marking one corner.
class _MiniScreen extends StatelessWidget {
  const _MiniScreen({required this.dotAt, required this.selected});

  final Alignment dotAt;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lineColor =
        selected ? theme.colorScheme.onPrimary : theme.colorScheme.outline;

    return Padding(
      padding: const EdgeInsets.all(6),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: lineColor, width: 1.5),
        ),
        padding: const EdgeInsets.all(4),
        child: Align(
          alignment: dotAt,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: lineColor,
            ),
          ),
        ),
      ),
    );
  }
}
