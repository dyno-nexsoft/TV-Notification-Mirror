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
      overlayPosition:
          prefs.getString('overlay_position') ?? MirrorProtocol.overlayTopRight,
      overlayDurationSeconds: prefs.getInt('overlay_duration_seconds') ?? 5,
      tvDndEnabled: prefs.getBool('tv_dnd_enabled') ?? false,
      masterMirrorEnabled: prefs.getBool('master_mirror_enabled') ?? true,
      callNotificationsEnabled:
          prefs.getBool('call_notifications_enabled') ?? true,
      textNotificationsEnabled:
          prefs.getBool('text_notifications_enabled') ?? true,
      otherNotificationsEnabled:
          prefs.getBool('other_notifications_enabled') ?? true,
    );
  }

  static Future<void> saveMasterMirrorEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('master_mirror_enabled', enabled);
  }

  static Future<void> saveCallNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('call_notifications_enabled', enabled);
  }

  static Future<void> saveTextNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('text_notifications_enabled', enabled);
  }

  static Future<void> saveOtherNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('other_notifications_enabled', enabled);
  }

  static Future<void> saveOverlaySettings({
    required String position,
    required int durationSeconds,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('overlay_position', position);
    await prefs.setInt('overlay_duration_seconds', durationSeconds);
  }

  static Future<void> saveTvDnd(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tv_dnd_enabled', enabled);
  }
}

/// Immutable value object holding all user-configurable app settings.
class AppSettings {
  const AppSettings({
    required this.overlayPosition,
    required this.overlayDurationSeconds,
    required this.tvDndEnabled,
    this.masterMirrorEnabled = true,
    this.callNotificationsEnabled = true,
    this.textNotificationsEnabled = true,
    this.otherNotificationsEnabled = true,
  });
  final String overlayPosition;
  final int overlayDurationSeconds;
  final bool tvDndEnabled;

  /// Master switch for mirroring notifications to the TV at all. When
  /// false, incoming notifications are never forwarded, regardless of any
  /// per-app filter or per-category setting.
  final bool masterMirrorEnabled;

  /// Whether to mirror notifications classified as a voice or video call.
  final bool callNotificationsEnabled;

  /// Whether to mirror notifications classified as a text message.
  final bool textNotificationsEnabled;

  /// Whether to mirror notifications that don't fall into either category
  /// above (everything else — most apps).
  final bool otherNotificationsEnabled;

  AppSettings copyWith({
    String? overlayPosition,
    int? overlayDurationSeconds,
    bool? tvDndEnabled,
    bool? masterMirrorEnabled,
    bool? callNotificationsEnabled,
    bool? textNotificationsEnabled,
    bool? otherNotificationsEnabled,
  }) {
    return AppSettings(
      overlayPosition: overlayPosition ?? this.overlayPosition,
      overlayDurationSeconds:
          overlayDurationSeconds ?? this.overlayDurationSeconds,
      tvDndEnabled: tvDndEnabled ?? this.tvDndEnabled,
      masterMirrorEnabled: masterMirrorEnabled ?? this.masterMirrorEnabled,
      callNotificationsEnabled:
          callNotificationsEnabled ?? this.callNotificationsEnabled,
      textNotificationsEnabled:
          textNotificationsEnabled ?? this.textNotificationsEnabled,
      otherNotificationsEnabled:
          otherNotificationsEnabled ?? this.otherNotificationsEnabled,
    );
  }
}
