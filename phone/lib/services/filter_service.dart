import 'package:flutter/material.dart';
import 'package:shared/shared.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Encapsulates all persistence logic for app filters, quiet hours,
/// blocked keywords, and overlay settings (Single Responsibility).
class FilterService {
  FilterService._();

  // ── Filter persistence ───────────────────────────────────────────────────

  static Future<Map<String, bool>> loadFilters() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('filter_'));
    final Map<String, bool> filters = {};
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
    final startHour = prefs.getInt('quiet_hours_start_hour') ?? 22;
    final startMinute = prefs.getInt('quiet_hours_start_minute') ?? 0;
    final endHour = prefs.getInt('quiet_hours_end_hour') ?? 7;
    final endMinute = prefs.getInt('quiet_hours_end_minute') ?? 0;

    return AppSettings(
      quietHoursEnabled: prefs.getBool('quiet_hours_enabled') ?? false,
      quietHoursStart: TimeOfDay(hour: startHour, minute: startMinute),
      quietHoursEnd: TimeOfDay(hour: endHour, minute: endMinute),
      blockedKeywords: prefs.getStringList('blocked_keywords') ?? [],
      overlayPosition: prefs.getString('overlay_position') ?? MirrorProtocol.overlayTopRight,
      overlayDurationSeconds: prefs.getInt('overlay_duration_seconds') ?? 5,
      tvDndEnabled: prefs.getBool('tv_dnd_enabled') ?? false,
    );
  }

  static Future<void> saveQuietHours({
    required bool enabled,
    required TimeOfDay start,
    required TimeOfDay end,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('quiet_hours_enabled', enabled);
    await prefs.setInt('quiet_hours_start_hour', start.hour);
    await prefs.setInt('quiet_hours_start_minute', start.minute);
    await prefs.setInt('quiet_hours_end_hour', end.hour);
    await prefs.setInt('quiet_hours_end_minute', end.minute);
  }

  static Future<void> saveBlockedKeywords(List<String> keywords) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('blocked_keywords', keywords);
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

  // ── Business logic ────────────────────────────────────────────────────────

  static bool isTimeInQuietHours(
    TimeOfDay start,
    TimeOfDay end,
    DateTime now,
  ) {
    return MirrorFilterEvaluator.isTimeInQuietHours(start, end, now);
  }
}

/// Immutable value object holding all user-configurable app settings.
class AppSettings {
  final bool quietHoursEnabled;
  final TimeOfDay quietHoursStart;
  final TimeOfDay quietHoursEnd;
  final List<String> blockedKeywords;
  final String overlayPosition;
  final int overlayDurationSeconds;
  final bool tvDndEnabled;

  const AppSettings({
    required this.quietHoursEnabled,
    required this.quietHoursStart,
    required this.quietHoursEnd,
    required this.blockedKeywords,
    required this.overlayPosition,
    required this.overlayDurationSeconds,
    required this.tvDndEnabled,
  });

  AppSettings copyWith({
    bool? quietHoursEnabled,
    TimeOfDay? quietHoursStart,
    TimeOfDay? quietHoursEnd,
    List<String>? blockedKeywords,
    String? overlayPosition,
    int? overlayDurationSeconds,
    bool? tvDndEnabled,
  }) {
    return AppSettings(
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      blockedKeywords: blockedKeywords ?? this.blockedKeywords,
      overlayPosition: overlayPosition ?? this.overlayPosition,
      overlayDurationSeconds:
          overlayDurationSeconds ?? this.overlayDurationSeconds,
      tvDndEnabled: tvDndEnabled ?? this.tvDndEnabled,
    );
  }
}
