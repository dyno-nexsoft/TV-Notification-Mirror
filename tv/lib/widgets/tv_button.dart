import 'package:shared/shared.dart';

/// A D-pad focusable TV button widget relying on theme focus border configuration.
class TvButton extends StatelessWidget {
  const TvButton({
    super.key,
    required this.onPressed,
    required this.label,
    required this.icon,
    this.color,
  });

  final VoidCallback onPressed;
  final String label;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(
        label,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}
