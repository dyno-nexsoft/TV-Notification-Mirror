import '../shared.dart';

/// A bordered, tappable action tile — icon at the top (with an optional
/// trailing widget, e.g. a switch), a title, and an optional subtitle. Used
/// identically by the TV and Phone apps' Home "quick action" cards.
///
/// Wrapped in a [YaruFocusBorder] so it highlights with the theme's primary
/// border (2px, matching the focus border configured on buttons in
/// `YaruAppTheme`) when focused via a TV remote or keyboard. The inner tap
/// [InkWell] is not focusable, leaving [YaruFocusBorder]'s own InkWell as the
/// single D-pad/tab focus target.
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
    return YaruFocusBorder(
      borderRadius: BorderRadius.circular(kYaruContainerRadius),
      child: YaruBorderContainer(
        child: InkWell(
          onTap: onTap,
          canRequestFocus: false,
          borderRadius: BorderRadius.circular(kYaruContainerRadius),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [Icon(icon), ?trailing],
                ),
                Text(title),
                if (subtitle != null) Text(subtitle!),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
