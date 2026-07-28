import '../shared.dart';

/// A bordered, tappable action tile — icon at the top (with an optional
/// trailing widget, e.g. a switch), a title, and an optional subtitle. Used
/// identically by the TV and Phone apps' Home "quick action" cards.
class BorderedActionCard extends StatelessWidget {
  const BorderedActionCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return YaruBorderContainer(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon),
                  if (trailing != null) trailing!,
                ],
              ),
              Text(title),
              if (subtitle != null) Text(subtitle!),
            ],
          ),
        ),
      ),
    );
  }
}
