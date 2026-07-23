import 'package:flutter/material.dart';
import 'package:yaru/yaru.dart';

/// Pure default Yaru Design System theme configuration shared between Phone and TV apps.
class YaruAppTheme {
  YaruAppTheme._();

  static final Color primaryColor = YaruColors.adwaitaPurple;

  /// Pure default Yaru Dark theme.
  static final ThemeData darkTheme = createYaruDarkTheme(
    primaryColor: primaryColor,
    elevatedButtonColor: YaruColors.dark.success,
  );

  /// Pure default Yaru Light theme.
  static final ThemeData lightTheme = createYaruLightTheme(
    primaryColor: primaryColor,
    elevatedButtonColor: YaruColors.light.success,
  );
}
