import 'package:shared/shared.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;

/// A D-pad focusable TV button widget with focus highlights and scale animations.
class TvButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Color color;
  final String label;
  final IconData icon;

  const TvButton({
    super.key,
    required this.onPressed,
    required this.color,
    required this.label,
    required this.icon,
  });

  @override
  State<TvButton> createState() => _TvButtonState();
}

class _TvButtonState extends State<TvButton> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (focus) {
        setState(() {
          _isFocused = focus;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        transform: _isFocused
            ? (Matrix4.identity()..scaleByVector3(Vector3(1.04, 1.04, 1.0)))
            : Matrix4.identity(),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: _isFocused
              ? [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.4),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ]
              : [],
        ),
        child: YaruOptionButton(
          onPressed: widget.onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, size: 24, color: widget.color),
                const SizedBox(width: 8),
                Text(
                  widget.label,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
