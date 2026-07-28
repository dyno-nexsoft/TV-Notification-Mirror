// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'phone_nav_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PhoneNavIndex)
final phoneNavIndexProvider = PhoneNavIndexProvider._();

final class PhoneNavIndexProvider
    extends $NotifierProvider<PhoneNavIndex, PhoneNavPage> {
  PhoneNavIndexProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'phoneNavIndexProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$phoneNavIndexHash();

  @$internal
  @override
  PhoneNavIndex create() => PhoneNavIndex();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PhoneNavPage value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PhoneNavPage>(value),
    );
  }
}

String _$phoneNavIndexHash() => r'3969699b308990a79af7a9ea4a6f46cb0e721f15';

abstract class _$PhoneNavIndex extends $Notifier<PhoneNavPage> {
  PhoneNavPage build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<PhoneNavPage, PhoneNavPage>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<PhoneNavPage, PhoneNavPage>,
        PhoneNavPage,
        Object?,
        Object?>;
    return element.handleCreate(ref, build);
  }
}
