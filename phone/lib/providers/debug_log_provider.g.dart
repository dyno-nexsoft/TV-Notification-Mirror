// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'debug_log_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Rolling in-memory buffer of debug log entries forwarded from the phone's
/// background isolate via `service.invoke('debugLog', ...)`. Kept alive so
/// the log survives tab switches while the app is running.

@ProviderFor(DebugLog)
final debugLogProvider = DebugLogProvider._();

/// Rolling in-memory buffer of debug log entries forwarded from the phone's
/// background isolate via `service.invoke('debugLog', ...)`. Kept alive so
/// the log survives tab switches while the app is running.
final class DebugLogProvider
    extends $NotifierProvider<DebugLog, List<DebugLogEntry>> {
  /// Rolling in-memory buffer of debug log entries forwarded from the phone's
  /// background isolate via `service.invoke('debugLog', ...)`. Kept alive so
  /// the log survives tab switches while the app is running.
  DebugLogProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'debugLogProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$debugLogHash();

  @$internal
  @override
  DebugLog create() => DebugLog();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<DebugLogEntry> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<DebugLogEntry>>(value),
    );
  }
}

String _$debugLogHash() => r'3512eb63abb02aaba33b8ebd40b94e7289b6e24d';

/// Rolling in-memory buffer of debug log entries forwarded from the phone's
/// background isolate via `service.invoke('debugLog', ...)`. Kept alive so
/// the log survives tab switches while the app is running.

abstract class _$DebugLog extends $Notifier<List<DebugLogEntry>> {
  List<DebugLogEntry> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<List<DebugLogEntry>, List<DebugLogEntry>>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<List<DebugLogEntry>, List<DebugLogEntry>>,
        List<DebugLogEntry>,
        Object?,
        Object?>;
    return element.handleCreate(ref, build);
  }
}
