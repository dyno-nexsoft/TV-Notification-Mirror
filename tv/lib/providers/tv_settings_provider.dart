import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared/shared.dart';

import '../services/tv_settings_service.dart';

part 'tv_settings_provider.g.dart';

/// Persisted TV-local settings (theme, overlay behavior, notification
/// filters). Every setter persists first, then notifies the background
/// isolate to reload so `ServerService`/overlay dispatch stay in sync.
@Riverpod(keepAlive: true)
class TvSettingsNotifier extends _$TvSettingsNotifier {
  @override
  TvSettings build() {
    _load();
    return const TvSettings();
  }

  Future<void> _load() async {
    state = await TvSettingsService.load();
  }

  Future<void> _update(TvSettings next) async {
    state = next;
    await TvSettingsService.save(next);
    FlutterBackgroundService().invoke('reloadSettings');
  }

  Future<void> setThemeMode(ThemeMode mode) =>
      _update(state.copyWith(themeMode: mode));

  Future<void> setLaunchOnBoot(bool enabled) =>
      _update(state.copyWith(launchOnBoot: enabled));

  Future<void> setOverlayOpacity(double opacity) =>
      _update(state.copyWith(overlayOpacity: opacity));

  Future<void> setAnchorPosition(String position) =>
      _update(state.copyWith(anchorPosition: position));

  Future<void> setOverlayDurationSeconds(int seconds) =>
      _update(state.copyWith(overlayDurationSeconds: seconds));

  Future<void> setAlertSoundUri(String? uri) => _update(TvSettings(
        themeMode: state.themeMode,
        launchOnBoot: state.launchOnBoot,
        overlayOpacity: state.overlayOpacity,
        anchorPosition: state.anchorPosition,
        overlayDurationSeconds: state.overlayDurationSeconds,
        alertSoundUri: uri,
        callNotificationsEnabled: state.callNotificationsEnabled,
        textNotificationsEnabled: state.textNotificationsEnabled,
        imagePreviewsEnabled: state.imagePreviewsEnabled,
      ));

  Future<void> setCallNotificationsEnabled(bool enabled) =>
      _update(state.copyWith(callNotificationsEnabled: enabled));

  Future<void> setTextNotificationsEnabled(bool enabled) =>
      _update(state.copyWith(textNotificationsEnabled: enabled));

  Future<void> setImagePreviewsEnabled(bool enabled) =>
      _update(state.copyWith(imagePreviewsEnabled: enabled));

  /// Bulk toggle for the NOTIFICATIONS section's master switch.
  Future<void> setAllNotificationTypes(bool enabled) => _update(state.copyWith(
        callNotificationsEnabled: enabled,
        textNotificationsEnabled: enabled,
        imagePreviewsEnabled: enabled,
      ));
}
