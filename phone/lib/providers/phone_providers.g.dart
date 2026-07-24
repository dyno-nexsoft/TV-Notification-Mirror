// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'phone_providers.dart';

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
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<ToastData?, ToastData?>, ToastData?, Object?, Object?>;
    return element.handleCreate(ref, build);
  }
}

/// Manages Android notification listener permission state.

@ProviderFor(Permission)
final permissionProvider = PermissionProvider._();

/// Manages Android notification listener permission state.
final class PermissionProvider
    extends $AsyncNotifierProvider<Permission, bool> {
  /// Manages Android notification listener permission state.
  PermissionProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'permissionProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$permissionHash();

  @$internal
  @override
  Permission create() => Permission();
}

String _$permissionHash() => r'f8058f00a160160f015f372f9e8f2b4e03b96c84';

/// Manages Android notification listener permission state.

abstract class _$Permission extends $AsyncNotifier<bool> {
  FutureOr<bool> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<bool>, bool>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<bool>, bool>,
        AsyncValue<bool>,
        Object?,
        Object?>;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(Connector)
final connectorProvider = ConnectorProvider._();

final class ConnectorProvider
    extends $NotifierProvider<Connector, PhoneConnectorState> {
  ConnectorProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'connectorProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$connectorHash();

  @$internal
  @override
  Connector create() => Connector();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PhoneConnectorState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PhoneConnectorState>(value),
    );
  }
}

String _$connectorHash() => r'fe1a45b95f41b5047499c615f654a7518d36c17e';

abstract class _$Connector extends $Notifier<PhoneConnectorState> {
  PhoneConnectorState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<PhoneConnectorState, PhoneConnectorState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<PhoneConnectorState, PhoneConnectorState>,
        PhoneConnectorState,
        Object?,
        Object?>;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(Settings)
final settingsProvider = SettingsProvider._();

final class SettingsProvider
    extends $AsyncNotifierProvider<Settings, AppSettings> {
  SettingsProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'settingsProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$settingsHash();

  @$internal
  @override
  Settings create() => Settings();
}

String _$settingsHash() => r'67008c6fba95c8f0a5f60747dd95fd38de4de1ea';

abstract class _$Settings extends $AsyncNotifier<AppSettings> {
  FutureOr<AppSettings> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<AppSettings>, AppSettings>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<AppSettings>, AppSettings>,
        AsyncValue<AppSettings>,
        Object?,
        Object?>;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(Filters)
final filtersProvider = FiltersProvider._();

final class FiltersProvider
    extends $AsyncNotifierProvider<Filters, PhoneFiltersState> {
  FiltersProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'filtersProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$filtersHash();

  @$internal
  @override
  Filters create() => Filters();
}

String _$filtersHash() => r'3569efb7e8798d9e66b997dd8b6341fd42abeda5';

abstract class _$Filters extends $AsyncNotifier<PhoneFiltersState> {
  FutureOr<PhoneFiltersState> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<PhoneFiltersState>, PhoneFiltersState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<PhoneFiltersState>, PhoneFiltersState>,
        AsyncValue<PhoneFiltersState>,
        Object?,
        Object?>;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(History)
final historyProvider = HistoryProvider._();

final class HistoryProvider
    extends $NotifierProvider<History, List<NotificationItem>> {
  HistoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'historyProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$historyHash();

  @$internal
  @override
  History create() => History();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<NotificationItem> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<NotificationItem>>(value),
    );
  }
}

String _$historyHash() => r'd9a751fbaab3917d65b1b57131aa421e78ca0548';

abstract class _$History extends $Notifier<List<NotificationItem>> {
  List<NotificationItem> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<List<NotificationItem>, List<NotificationItem>>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<List<NotificationItem>, List<NotificationItem>>,
        List<NotificationItem>,
        Object?,
        Object?>;
    return element.handleCreate(ref, build);
  }
}
