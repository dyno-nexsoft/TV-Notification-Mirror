import 'package:shared/shared.dart';

/// 2x2 grid to pick which screen corner the overlay toast anchors to.
/// Only 4 positions exist in [MirrorProtocol] (the real anchors the overlay
/// supports) — no fake center/edge cells that wouldn't do anything.
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
                  height: 40,
                  child: YaruSelectableContainer(
                    selected: value == position,
                    onTap: () => onChanged(position),
                    child: Align(
                      alignment: _alignmentFor(position),
                      child: Icon(
                        value == position
                            ? YaruIcons.ok_filled
                            : YaruIcons.window,
                        size: 16,
                      ),
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
