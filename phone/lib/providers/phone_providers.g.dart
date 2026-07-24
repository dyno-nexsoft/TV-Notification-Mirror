// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'phone_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(connectorService)
final connectorServiceProvider = ConnectorServiceProvider._();

final class ConnectorServiceProvider extends $FunctionalProvider<
    ConnectorService,
    ConnectorService,
    ConnectorService> with $Provider<ConnectorService> {
  ConnectorServiceProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'connectorServiceProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$connectorServiceHash();

  @$internal
  @override
  $ProviderElement<ConnectorService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ConnectorService create(Ref ref) {
    return connectorService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ConnectorService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ConnectorService>(value),
    );
  }
}

String _$connectorServiceHash() => r'7341e9c8338192e6e7f79b5959a92811793a3b34';

@ProviderFor(notificationService)
final notificationServiceProvider = NotificationServiceProvider._();

final class NotificationServiceProvider extends $FunctionalProvider<
    NotificationService,
    NotificationService,
    NotificationService> with $Provider<NotificationService> {
  NotificationServiceProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'notificationServiceProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$notificationServiceHash();

  @$internal
  @override
  $ProviderElement<NotificationService> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  NotificationService create(Ref ref) {
    return notificationService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NotificationService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NotificationService>(value),
    );
  }
}

String _$notificationServiceHash() =>
    r'58da87941dbfa08925105dcc4d74091ee38c8593';

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

String _$permissionHash() => r'60155c8448c22e6a79c9078e7236722e9cc4030f';

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

String _$connectorHash() => r'6c664d4be941a7e6a19fa60662ae14e95d369ca6';

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

String _$settingsHash() => r'dfac0fc4136d48dc66e974f7de0f7c3f8304cae6';

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

String _$filtersHash() => r'5a2e8259ea0d474a822e10222fdb3d1aa8238417';

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

String _$historyHash() => r'1e7c67fec3ba96a6cf6f09ec2e2486458caa0d51';

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
