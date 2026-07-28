/// Pure evaluation logic for notification filtering rules (App Filter).
class MirrorFilterEvaluator {
  MirrorFilterEvaluator._();

  /// Returns true if notifications from [packageName] are enabled.
  static bool isAppEnabled(String packageName, Map<String, bool> appFilters) {
    return appFilters[packageName] ?? true;
  }
}
