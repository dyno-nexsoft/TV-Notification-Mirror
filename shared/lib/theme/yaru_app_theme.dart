import 'package:flutter/material.dart';
import 'package:yaru/yaru.dart';

/// Pure default Yaru Design System theme configuration shared between Phone and TV apps.
class YaruAppTheme {
  YaruAppTheme._();

  /// Pure default Yaru Dark theme.
  static ThemeData get darkTheme => yaruDark;

  /// Pure default Yaru Light theme.
  static ThemeData get lightTheme => yaruLight;
}
