import 'package:shared/shared.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Encapsulates all persistence logic for app filters and mirror settings
/// (Single Responsibility).
class FilterService {
  FilterService._();

  // ── Filter persistence ───────────────────────────────────────────────────

  static Future<Map<String, bool>> loadFilters() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('filter_'));
    final filters = <String, bool>{};
    for (final key in keys) {
      final pkg = key.replaceFirst('filter_', '');
      filters[pkg] = prefs.getBool(key) ?? true;
    }
    return filters;
  }

  static Future<void> saveFilter(String packageName, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('filter_$packageName', value);
  }

  // ── Settings persistence ─────────────────────────────────────────────────

  static Future<AppSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return AppSettings(
      alertSoundUri: prefs.getString('alert_sound_uri'),
      themeMode: ThemeMode.values.firstWhere(
        (m) => m.name == prefs.getString('phone_theme_mode'),
        orElse: () => ThemeMode.dark,
      ),
    );
  }

  static Future<void> saveAlertSoundUri(String uri) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('alert_sound_uri', uri);
  }

  static Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('phone_theme_mode', mode.name);
  }
}

/// Phone-side settings — only what the phone needs locally.
class AppSettings {
  const AppSettings({
    this.alertSoundUri,
    this.themeMode = ThemeMode.dark,
  });

  /// URI of the sound played locally when using "Send Test Notification".
  /// Null means the device's default notification sound; `'silent'` means no
  /// sound at all.
  final String? alertSoundUri;

  /// Light / Dark / System theme mode for the phone app.
  final ThemeMode themeMode;

  AppSettings copyWith({
    String? alertSoundUri,
    ThemeMode? themeMode,
  }) {
    return AppSettings(
      alertSoundUri: alertSoundUri ?? this.alertSoundUri,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}
