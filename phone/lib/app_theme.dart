import 'package:shared/shared.dart';

/// Phone application theme using pure default Yaru UI design system.
class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme => YaruAppTheme.darkTheme;
  static ThemeData get lightTheme => YaruAppTheme.lightTheme;

  /// Returns YaruTheme builder widget for wrapping MaterialApp.
  static Widget buildYaruThemeApp({
    required Widget Function(BuildContext, YaruThemeData, Widget?) builder,
    required Widget child,
  }) {
    return YaruTheme(
      builder: builder,
      child: child,
    );
  }
}
