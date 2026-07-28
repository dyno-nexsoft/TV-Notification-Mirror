import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tv_nav_provider.g.dart';

/// The 5 top-level pages reachable from the TV app's navigation rail.
enum TvNavPage { home, history, manageDevices, pairDevice, settings }

@riverpod
class TvNavIndex extends _$TvNavIndex {
  @override
  TvNavPage build() => TvNavPage.home;

  void select(TvNavPage page) => state = page;
}
