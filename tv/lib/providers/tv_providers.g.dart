// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tv_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AppToast)
final appToastProvider = AppToastProvider._();

final class AppToastProvider extends $NotifierProvider<AppToast, ToastData?> {
  AppToastProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appToastProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appToastHash();

  @$internal
  @override
  AppToast create() => AppToast();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ToastData? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ToastData?>(value),
    );
  }
}

String _$appToastHash() => r'77643a14decf1f50be32f677ac19d810c39ce727';

abstract class _$AppToast extends $Notifier<ToastData?> {
  ToastData? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ToastData?, ToastData?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ToastData?, ToastData?>,
              ToastData?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(TvPermissions)
final tvPermissionsProvider = TvPermissionsProvider._();

final class TvPermissionsProvider
    extends $AsyncNotifierProvider<TvPermissions, TvPermissionsState> {
  TvPermissionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tvPermissionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tvPermissionsHash();

  @$internal
  @override
  TvPermissions create() => TvPermissions();
}

String _$tvPermissionsHash() => r'106591485fc284f5129c46bd78958a6bfad08d79';

abstract class _$TvPermissions extends $AsyncNotifier<TvPermissionsState> {
  FutureOr<TvPermissionsState> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<TvPermissionsState>, TvPermissionsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<TvPermissionsState>, TvPermissionsState>,
              AsyncValue<TvPermissionsState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(tvIp)
final tvIpProvider = TvIpProvider._();

final class TvIpProvider
    extends $FunctionalProvider<AsyncValue<String>, String, FutureOr<String>>
    with $FutureModifier<String>, $FutureProvider<String> {
  TvIpProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tvIpProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tvIpHash();

  @$internal
  @override
  $FutureProviderElement<String> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String> create(Ref ref) {
    return tvIp(ref);
  }
}

String _$tvIpHash() => r'380b95c85d4b35f0ceb8d2f8536baaf4916e8719';

@ProviderFor(TvServiceState)
final tvServiceStateProvider = TvServiceStateProvider._();

final class TvServiceStateProvider
    extends $NotifierProvider<TvServiceState, TvServiceData> {
  TvServiceStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tvServiceStateProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tvServiceStateHash();

  @$internal
  @override
  TvServiceState create() => TvServiceState();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TvServiceData value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TvServiceData>(value),
    );
  }
}

String _$tvServiceStateHash() => r'f494c87cb5f5f1e83ce9e6f87201e31d0d8bc112';

abstract class _$TvServiceState extends $Notifier<TvServiceData> {
  TvServiceData build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<TvServiceData, TvServiceData>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TvServiceData, TvServiceData>,
              TvServiceData,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
