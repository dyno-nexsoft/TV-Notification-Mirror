import 'package:json_annotation/json_annotation.dart';

/// Coarse classification of an incoming notification, used to pick the
/// right TV overlay layout/actions (call vs. message vs. everything else).
enum NotificationCategory {
  @JsonValue('voice_call')
  voiceCall,
  @JsonValue('video_call')
  videoCall,
  @JsonValue('message')
  message,
  @JsonValue('generic')
  generic,
}
