import 'package:shared/shared.dart';

/// Title + subtitle shown at the top of every full-page screen, with an
/// optional trailing action (e.g. Settings' master switch, History's Clear
/// All button).
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 4,
            children: [
              Text(title, style: theme.textTheme.headlineSmall),
              if (subtitle != null)
                Text(subtitle!, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}
