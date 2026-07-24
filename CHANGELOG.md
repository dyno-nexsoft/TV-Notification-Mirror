# Changelog

All notable changes to this project will be documented in this file.

## [1.0.14] - 2026-07-24

### Fixed
- **TV App**: Addressed the banner cropping issue completely. By explicitly ignoring system DPI scaling during image generation, the 1024x1024 icon is now perfectly centered pixel-for-pixel inside the 16:9 1024x576 banner.

## [1.0.13] - 2026-07-24

### Fixed
- **TV App**: Fixed TV launcher banner image (`tv_banner.png`) cropping issue. Properly scaled and centered the app icon on a 16:9 canvas with the correct background color so the icon isn't cut off on the Android TV home screen.

## [1.0.12] - 2026-07-24

### Fixed
- **TV App**: Fixed critical auto-start issue on TV boot by correcting the `flutter_background_service` package name in `BootReceiver.kt`.
- **TV App**: Eliminated UI flickering in the Recent Notifications feed by applying `gaplessPlayback: true` to `Image.memory`.
- **Both Apps**: Enforced optimistic UI state by utilizing `skipLoadingOnReload: true` across all Riverpod `.when()` UI builders.

### Added
- **TV App**: Implemented smooth fade-in and fade-out animations (`AlphaAnimation`) for the native Android notification popup overlay.
- **TV App**: Added a "Clear All" button to manually clear notification history directly from the TV screen.


## [1.0.11] - 2026-07-24

### Changed
- **Workspace**: Refactored Dart workspace by moving `native_bridge` to the root directory for better monorepo cohesion and standardized package paths.
- **Background Execution**: Re-architected both Phone and TV apps to adhere strictly to Android 14+ `FOREGROUND_SERVICE_CONNECTED_DEVICE` requirements.
- **Background Execution (Phone)**: Decoupled UI state (`phone_providers.dart`) from background tasks; IPC is now exclusively managed via `flutter_background_service`.
- **Background Execution (Phone)**: Ensured `PhoneApplication.onCreate` initializes the `phone_mirror_service_channel` channel before background tasks launch to prevent `CannotPostForegroundServiceNotificationException` crashes on boot.
- **Native Bridge**: Addressed module compilation errors by substituting direct Kotlin class imports with intent string constants.
- **Code Quality**: Performed extensive linting and resolved all 51 `dart analyze` warnings across the repository.

## [1.0.10] - 2026-07-24

### Changed
- **Both Apps**: Enforced `omit_obvious_property_types` linting rule.
- **Both Apps**: Translated all remaining hardcoded Vietnamese UI text strings and error logs to English for full localization consistency.
- **Phone App**: Migrated standard `TextField` widgets to `YaruSearchField` across all dialogs and filter tabs for a consistent UI experience with built-in 'clear' functionality.
- **Phone App**: Replaced the text-based "Add" button in the keyword filter settings with a cleaner `IconButton.filled` utilizing a plus icon.

## [1.0.9] - 2026-07-21

### Fixed
- **TV App**: Fixed immediate crash on app launch due to missing notification channel configuration (`CannotPostForegroundServiceNotificationException`). Added native `TvApplication.onCreate` setup to create the channel before background services run.
- **TV App**: Fixed overlay notification not rendering. Bridged incoming WebSocket notifications from the background isolate to the main UI isolate via the `flutter_background_service` stream API.
- **TV App**: Fixed D-pad remote controller "Delete" action focus. Changed paired device cards layout to independently handle remote select/enter button events (`onKeyEvent`).
- **TV App**: Removed duplicates in paired client list. The server now checks and replaces existing clients with matching name or IP when confirming new pairings.
- **Phone App**: Fixed loading overlay spinner getting permanently stuck during device pairing by renaming dialog builder context and refactoring it into a clean, inline loading state inside the PIN dialog.
- **Phone App**: Gracefully notifies TV before WebSocket disconnection, updating TV status to "Offline" immediately.

### Added
- **TV App**: Added a "Phone Connected" banner on TV home screen when at least one paired client has an active connection.
- **TV App**: Added a confirmation dialog when pressing back/exit button on remote or gamepad to prevent accidental close.
