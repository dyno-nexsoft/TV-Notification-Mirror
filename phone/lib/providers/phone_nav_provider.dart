import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'phone_nav_provider.g.dart';

/// The 4 top-level pages reachable from the Phone app's bottom nav bar.
enum PhoneNavPage {
  home,
  alerts,
  devices,
  settings,
}

@riverpod
class PhoneNavIndex extends _$PhoneNavIndex {
  @override
  PhoneNavPage build() => PhoneNavPage.home;

  void select(PhoneNavPage page) => state = page;
}
