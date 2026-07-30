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
    );
  }

  static Future<void> saveAlertSoundUri(String uri) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('alert_sound_uri', uri);
  }
}

/// Phone-side settings — only what the phone needs locally.
class AppSettings {
  const AppSettings({
    this.alertSoundUri,
  });

  /// URI of the sound played locally when using "Send Test Notification".
  /// Null means the device's default notification sound; `'silent'` means no
  /// sound at all.
  final String? alertSoundUri;

  AppSettings copyWith({
    String? alertSoundUri,
  }) {
    return AppSettings(
      alertSoundUri: alertSoundUri ?? this.alertSoundUri,
    );
  }
}
