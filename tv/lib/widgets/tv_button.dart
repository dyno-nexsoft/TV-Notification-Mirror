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
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.color,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: _isFocused
                  ? const BorderSide(color: Colors.white, width: 2)
                  : BorderSide.none,
            ),
            elevation: _isFocused ? 12 : 4,
          ),
          onPressed: widget.onPressed,
          icon: Icon(widget.icon, size: 24),
          label: Text(
            widget.label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
