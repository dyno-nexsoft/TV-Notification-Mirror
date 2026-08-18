/// Barrel export file for the shared TV Notification Mirror package.
/// Re-exports Yaru UI system & Flutter foundation so consumers do not need
/// to import package:flutter/material.dart directly.
library;

export 'package:flutter/material.dart';
export 'package:yaru/yaru.dart';

export 'constants/mirror_protocol.dart';
export 'models/app_preset.dart';
export 'models/debug_log_entry.dart';
export 'models/mirror_device.dart';
export 'models/notification_category.dart';
export 'models/notification_item.dart';
export 'services/battery_optimization_service.dart';
export 'services/mirror_filter_evaluator.dart';
export 'theme/yaru_app_theme.dart';
export 'widgets/adb_instructions_dialog.dart';
export 'widgets/anchor_position_picker.dart';
export 'widgets/app_icon_widget.dart';
export 'widgets/battery_optimization_section.dart';
export 'widgets/bordered_action_card.dart';
export 'widgets/debug_log_list_tile.dart';
export 'widgets/debug_log_screen.dart';
export 'widgets/notification_category_toggles.dart';
export 'widgets/notification_preferences_card.dart';
export 'widgets/overlay_position_duration_settings.dart';
export 'widgets/status_dot.dart';
export 'widgets/support_section.dart';
export 'widgets/theme_mode_selector.dart';
export 'widgets/tv_overlay_settings_card.dart';
export 'widgets/value_stepper.dart';
export 'widgets/yaru_status_card.dart';
