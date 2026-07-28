import 'package:shared/shared.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Immutable value object holding all user-configurable TV settings.
class TvSettings {
  const TvSettings({
    this.themeMode = ThemeMode.dark,
    this.launchOnBoot = true,
    this.overlayOpacity = 0.95,
    this.anchorPosition = MirrorProtocol.overlayTopRight,
    this.overlayDurationSeconds = 5,
    this.alertSoundUri,
    this.callNotificationsEnabled = true,
    this.textNotificationsEnabled = true,
    this.imagePreviewsEnabled = true,
  });

  final ThemeMode themeMode;
  final bool launchOnBoot;
  final double overlayOpacity;
  final String anchorPosition;
  final int overlayDurationSeconds;

  /// Null = system default notification sound. `'silent'` = no sound.
  final String? alertSoundUri;
  final bool callNotificationsEnabled;
  final bool textNotificationsEnabled;
  final bool imagePreviewsEnabled;

  TvSettings copyWith({
    ThemeMode? themeMode,
    bool? launchOnBoot,
    double? overlayOpacity,
    String? anchorPosition,
    int? overlayDurationSeconds,
    String? alertSoundUri,
    bool? callNotificationsEnabled,
    bool? textNotificationsEnabled,
    bool? imagePreviewsEnabled,
  }) {
    return TvSettings(
      themeMode: themeMode ?? this.themeMode,
      launchOnBoot: launchOnBoot ?? this.launchOnBoot,
      overlayOpacity: overlayOpacity ?? this.overlayOpacity,
      anchorPosition: anchorPosition ?? this.anchorPosition,
      overlayDurationSeconds:
          overlayDurationSeconds ?? this.overlayDurationSeconds,
      alertSoundUri: alertSoundUri ?? this.alertSoundUri,
      callNotificationsEnabled:
          callNotificationsEnabled ?? this.callNotificationsEnabled,
      textNotificationsEnabled:
          textNotificationsEnabled ?? this.textNotificationsEnabled,
      imagePreviewsEnabled: imagePreviewsEnabled ?? this.imagePreviewsEnabled,
    );
  }
}

/// Encapsulates persistence of [TvSettings] via `shared_preferences`, read
/// both from the UI isolate (settings screen) and the background isolate
/// (to decide overlay behavior without a Riverpod ProviderScope available).
class TvSettingsService {
  TvSettingsService._();

  static const _keyThemeMode = 'tv_theme_mode';
  static const _keyLaunchOnBoot = 'tv_launch_on_boot';
  static const _keyOverlayOpacity = 'tv_overlay_opacity';
  static const _keyAnchorPosition = 'tv_anchor_position';
  static const _keyOverlayDurationSeconds = 'tv_overlay_duration_seconds';
  static const _keyAlertSoundUri = 'tv_alert_sound_uri';
  static const _keyCallNotificationsEnabled = 'tv_call_notifications_enabled';
  static const _keyTextNotificationsEnabled = 'tv_text_notifications_enabled';
  static const _keyImagePreviewsEnabled = 'tv_image_previews_enabled';

  static Future<TvSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return TvSettings(
      themeMode: ThemeMode.values.firstWhere(
        (m) => m.name == prefs.getString(_keyThemeMode),
        orElse: () => ThemeMode.dark,
      ),
      launchOnBoot: prefs.getBool(_keyLaunchOnBoot) ?? true,
      overlayOpacity: prefs.getDouble(_keyOverlayOpacity) ?? 0.95,
      anchorPosition:
          prefs.getString(_keyAnchorPosition) ?? MirrorProtocol.overlayTopRight,
      overlayDurationSeconds: prefs.getInt(_keyOverlayDurationSeconds) ?? 5,
      alertSoundUri: prefs.getString(_keyAlertSoundUri),
      callNotificationsEnabled:
          prefs.getBool(_keyCallNotificationsEnabled) ?? true,
      textNotificationsEnabled:
          prefs.getBool(_keyTextNotificationsEnabled) ?? true,
      imagePreviewsEnabled: prefs.getBool(_keyImagePreviewsEnabled) ?? true,
    );
  }

  static Future<void> save(TvSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyThemeMode, settings.themeMode.name);
    await prefs.setBool(_keyLaunchOnBoot, settings.launchOnBoot);
    await prefs.setDouble(_keyOverlayOpacity, settings.overlayOpacity);
    await prefs.setString(_keyAnchorPosition, settings.anchorPosition);
    await prefs.setInt(
      _keyOverlayDurationSeconds,
      settings.overlayDurationSeconds,
    );
    if (settings.alertSoundUri != null) {
      await prefs.setString(_keyAlertSoundUri, settings.alertSoundUri!);
    } else {
      await prefs.remove(_keyAlertSoundUri);
    }
    await prefs.setBool(
      _keyCallNotificationsEnabled,
      settings.callNotificationsEnabled,
    );
    await prefs.setBool(
      _keyTextNotificationsEnabled,
      settings.textNotificationsEnabled,
    );
    await prefs.setBool(
      _keyImagePreviewsEnabled,
      settings.imagePreviewsEnabled,
    );
  }
}
