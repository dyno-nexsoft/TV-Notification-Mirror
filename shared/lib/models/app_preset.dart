import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:yaru/yaru.dart';

part 'app_preset.freezed.dart';
part 'app_preset.g.dart';

/// Represents a pre-configured or installed application preset item.
@freezed
abstract class AppPreset with _$AppPreset {
  const factory AppPreset({
    required String pkg,
    required String name,
    @JsonKey(includeFromJson: false, includeToJson: false)
    @Default(YaruIcons.notification)
    IconData icon,
  }) = _AppPreset;

  factory AppPreset.fromJson(Map<String, dynamic> json) =>
      _$AppPresetFromJson(json);
}
