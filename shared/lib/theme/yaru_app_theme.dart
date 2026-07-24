import 'package:flutter/material.dart';
import 'package:yaru/yaru.dart';

/// Pure default Yaru Design System theme configuration shared between Phone and TV apps.
class YaruAppTheme {
  YaruAppTheme._();

  static const Color primaryColor = YaruColors.adwaitaPurple;

  /// Pure default Yaru Dark theme.
  static final ThemeData darkTheme = _applyCustomTheme(
    createYaruDarkTheme(
      primaryColor: primaryColor,
      elevatedButtonColor: YaruColors.dark.success,
    ),
  );

  /// Pure default Yaru Light theme.
  static final ThemeData lightTheme = _applyCustomTheme(
    createYaruLightTheme(
      primaryColor: primaryColor,
      elevatedButtonColor: YaruColors.light.success,
    ),
  );

  static ThemeData _applyCustomTheme(ThemeData theme) {
    final focusBorder = BorderSide(
      color: theme.colorScheme.primary,
      width: 2.0,
    );

    BorderSide? getSide(Set<WidgetState> states, [BorderSide? defaultSide]) {
      if (states.contains(WidgetState.focused)) {
        return focusBorder;
      }
      return defaultSide;
    }

    final iconSide = WidgetStateProperty.resolveWith<BorderSide?>(
        (states) => getSide(states));
    final elevatedSide = WidgetStateProperty.resolveWith<BorderSide?>(
        (states) => getSide(states));
    final outlinedSide = WidgetStateProperty.resolveWith<BorderSide?>((states) {
      return getSide(states, BorderSide(color: theme.colorScheme.outline));
    });
    final textSide = WidgetStateProperty.resolveWith<BorderSide?>(
        (states) => getSide(states));
    final filledSide = WidgetStateProperty.resolveWith<BorderSide?>(
        (states) => getSide(states));

    return theme.copyWith(
      iconButtonTheme: IconButtonThemeData(
        style: (theme.iconButtonTheme.style ?? const ButtonStyle()).copyWith(
          side: iconSide,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style:
            (theme.elevatedButtonTheme.style ?? const ButtonStyle()).copyWith(
          side: elevatedSide,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style:
            (theme.outlinedButtonTheme.style ?? const ButtonStyle()).copyWith(
          side: outlinedSide,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: (theme.textButtonTheme.style ?? const ButtonStyle()).copyWith(
          side: textSide,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: (theme.filledButtonTheme.style ?? const ButtonStyle()).copyWith(
          side: filledSide,
        ),
      ),
      listTileTheme: ListTileThemeData(
        titleTextStyle: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
        subtitleTextStyle: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
        ),
      ),
    );
  }
}
