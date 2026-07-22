import 'package:flutter/material.dart';

/// Pure evaluation logic for notification filtering rules (Quiet Hours, Keywords, App Filter).
class MirrorFilterEvaluator {
  MirrorFilterEvaluator._();

  /// Returns true if [now] falls within [start] and [end] quiet hours range.
  static bool isTimeInQuietHours(
    TimeOfDay start,
    TimeOfDay end,
    DateTime now,
  ) {
    final nowMinutes = now.hour * 60 + now.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;

    if (startMinutes <= endMinutes) {
      return nowMinutes >= startMinutes && nowMinutes <= endMinutes;
    } else {
      // Overnight quiet hours, e.g. 22:00 to 07:00
      return nowMinutes >= startMinutes || nowMinutes <= endMinutes;
    }
  }

  /// Returns the matching blocked keyword if [title] or [text] contains any keyword from [blockedKeywords].
  static String? findMatchingBlockedKeyword(
    String title,
    String text,
    List<String> blockedKeywords,
  ) {
    final titleLower = title.toLowerCase();
    final textLower = text.toLowerCase();

    for (final kw in blockedKeywords) {
      final kwLower = kw.toLowerCase();
      if (titleLower.contains(kwLower) || textLower.contains(kwLower)) {
        return kw;
      }
    }
    return null;
  }

  /// Returns true if notifications from [packageName] are enabled.
  static bool isAppEnabled(
    String packageName,
    Map<String, bool> appFilters,
  ) {
    return appFilters[packageName] ?? true;
  }
}
