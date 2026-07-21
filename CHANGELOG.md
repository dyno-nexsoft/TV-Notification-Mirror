# Changelog

All notable changes to this project will be documented in this file.

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
