// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tv_settings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Persisted TV-local settings (theme, overlay behavior, notification
/// filters). Every setter persists first, then notifies the background
/// isolate to reload so `ServerService`/overlay dispatch stay in sync.

@ProviderFor(TvSettingsNotifier)
final tvSettingsProvider = TvSettingsNotifierProvider._();

/// Persisted TV-local settings (theme, overlay behavior, notification
/// filters). Every setter persists first, then notifies the background
/// isolate to reload so `ServerService`/overlay dispatch stay in sync.
final class TvSettingsNotifierProvider
    extends $NotifierProvider<TvSettingsNotifier, TvSettings> {
  /// Persisted TV-local settings (theme, overlay behavior, notification
  /// filters). Every setter persists first, then notifies the background
  /// isolate to reload so `ServerService`/overlay dispatch stay in sync.
  TvSettingsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tvSettingsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tvSettingsNotifierHash();

  @$internal
  @override
  TvSettingsNotifier create() => TvSettingsNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TvSettings value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TvSettings>(value),
    );
  }
}

String _$tvSettingsNotifierHash() =>
    r'd275c074fda3e41450b742cb7a81dda04be8407d';

/// Persisted TV-local settings (theme, overlay behavior, notification
/// filters). Every setter persists first, then notifies the background
/// isolate to reload so `ServerService`/overlay dispatch stay in sync.

abstract class _$TvSettingsNotifier extends $Notifier<TvSettings> {
  TvSettings build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<TvSettings, TvSettings>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TvSettings, TvSettings>,
              TvSettings,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
