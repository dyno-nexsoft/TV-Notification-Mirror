import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';

import '../providers/tv_nav_provider.dart';
import '../providers/tv_providers.dart';
import '../widgets/app_rail.dart';
import 'history/tv_history_screen.dart';
import 'home/tv_home_screen.dart';
import 'manage_devices/tv_manage_devices_screen.dart';
import 'pair_device/tv_pair_device_screen.dart';
import 'settings/tv_settings_screen.dart';

part 'tv_main_screen_dialogs.dart';

const _navItems = [
  (page: TvNavPage.home, icon: YaruIcons.home, label: 'Home'),
  (page: TvNavPage.history, icon: YaruIcons.history, label: 'History'),
  (
    page: TvNavPage.manageDevices,
    icon: YaruIcons.smartphone,
    label: 'Manage Devices',
  ),
  (page: TvNavPage.pairDevice, icon: Icons.qr_code, label: 'Pair Device'),
  (page: TvNavPage.settings, icon: YaruIcons.settings, label: 'Settings'),
];

/// TV app shell: a nav rail on the left switching between the 5 top-level
/// pages, plus the exit-confirmation dialog since the background mirror
/// server keeps running after the UI closes.
class TvMainScreen extends ConsumerStatefulWidget {
  const TvMainScreen({super.key});

  @override
  ConsumerState<TvMainScreen> createState() => _TvMainScreenState();
}

class _TvMainScreenState extends ConsumerState<TvMainScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(tvPermissionsProvider.notifier).checkPermissions();
    }
  }

  Future<bool> _showExitConfirmDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => const _ExitConfirmDialog(),
    );
    return result ?? false;
  }

  Widget _buildPage(TvNavPage page) {
    return switch (page) {
      TvNavPage.home => const TvHomeScreen(),
      TvNavPage.history => const TvHistoryScreen(),
      TvNavPage.manageDevices => const TvManageDevicesScreen(),
      TvNavPage.pairDevice => const TvPairDeviceScreen(),
      TvNavPage.settings => const TvSettingsScreen(),
    };
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(appToastProvider, (previous, next) {
      if (next == null || next == previous) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(next.message)));
    });

    final selectedPage = ref.watch(tvNavIndexProvider);
    final selectedIndex = _navItems.indexWhere(
      (item) => item.page == selectedPage,
    );
    final isServerRunning = ref.watch(tvServiceStateProvider).isRunning;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await _showExitConfirmDialog();
        if (shouldExit && context.mounted) {
          await SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 250,
              child: YaruNavigationRail(
                length: _navItems.length,
                selectedIndex: selectedIndex,
                onDestinationSelected: (index) => ref
                    .read(tvNavIndexProvider.notifier)
                    .select(_navItems[index].page),
                leading: AppRailHeader(isActive: isServerRunning),
                trailing: RailDeviceFooter(
                  deviceLabel: Platform.operatingSystemVersion,
                ),
                itemBuilder: (context, index, selected) {
                  final item = _navItems[index];
                  return YaruNavigationRailItem(
                    style: YaruNavigationRailStyle.labelledExtended,
                    selected: selected,
                    icon: Icon(item.icon),
                    label: Text(item.label),
                  );
                },
              ),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: _buildPage(selectedPage)),
          ],
        ),
      ),
    );
  }
}
