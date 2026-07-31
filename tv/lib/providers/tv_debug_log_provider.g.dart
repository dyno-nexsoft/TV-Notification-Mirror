// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tv_debug_log_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Rolling in-memory buffer of debug log entries forwarded from the TV's
/// background isolate via `service.invoke('debugLog', ...)`. Kept alive so
/// the log survives page switches while the app is running.

@ProviderFor(TvDebugLog)
final tvDebugLogProvider = TvDebugLogProvider._();

/// Rolling in-memory buffer of debug log entries forwarded from the TV's
/// background isolate via `service.invoke('debugLog', ...)`. Kept alive so
/// the log survives page switches while the app is running.
final class TvDebugLogProvider
    extends $NotifierProvider<TvDebugLog, List<DebugLogEntry>> {
  /// Rolling in-memory buffer of debug log entries forwarded from the TV's
  /// background isolate via `service.invoke('debugLog', ...)`. Kept alive so
  /// the log survives page switches while the app is running.
  TvDebugLogProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tvDebugLogProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tvDebugLogHash();

  @$internal
  @override
  TvDebugLog create() => TvDebugLog();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<DebugLogEntry> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<DebugLogEntry>>(value),
    );
  }
}

String _$tvDebugLogHash() => r'6c9acdd25fab5ae3f05a7d342548da1d6643baf2';

/// Rolling in-memory buffer of debug log entries forwarded from the TV's
/// background isolate via `service.invoke('debugLog', ...)`. Kept alive so
/// the log survives page switches while the app is running.

abstract class _$TvDebugLog extends $Notifier<List<DebugLogEntry>> {
  List<DebugLogEntry> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<List<DebugLogEntry>, List<DebugLogEntry>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<DebugLogEntry>, List<DebugLogEntry>>,
              List<DebugLogEntry>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
