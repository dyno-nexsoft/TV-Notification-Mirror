// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tv_nav_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TvNavIndex)
final tvNavIndexProvider = TvNavIndexProvider._();

final class TvNavIndexProvider
    extends $NotifierProvider<TvNavIndex, TvNavPage> {
  TvNavIndexProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tvNavIndexProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tvNavIndexHash();

  @$internal
  @override
  TvNavIndex create() => TvNavIndex();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TvNavPage value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TvNavPage>(value),
    );
  }
}

String _$tvNavIndexHash() => r'cd444f2430c282574cf5e9228fb6c4d542bbd527';

abstract class _$TvNavIndex extends $Notifier<TvNavPage> {
  TvNavPage build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<TvNavPage, TvNavPage>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TvNavPage, TvNavPage>,
              TvNavPage,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
