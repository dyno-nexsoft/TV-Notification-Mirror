/// Barrel export file for the shared TV Notification Mirror package.
/// Re-exports Yaru UI system & Flutter foundation so consumers do not need
/// to import package:flutter/material.dart directly.
library;

export 'package:flutter/material.dart';
export 'package:yaru/yaru.dart';

export 'constants/mirror_protocol.dart';
export 'models/app_preset.dart';
export 'models/mirror_device.dart';
export 'models/notification_category.dart';
export 'models/notification_item.dart';
export 'services/mirror_filter_evaluator.dart';
export 'theme/yaru_app_theme.dart';
export 'widgets/anchor_position_picker.dart';
export 'widgets/app_icon_widget.dart';
export 'widgets/notification_category_toggles.dart';
export 'widgets/overlay_position_duration_settings.dart';
export 'widgets/status_dot.dart';
export 'widgets/support_section.dart';
export 'widgets/value_stepper.dart';
export 'widgets/yaru_status_card.dart';
