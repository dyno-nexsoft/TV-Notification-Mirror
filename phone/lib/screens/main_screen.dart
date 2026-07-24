import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';

import '../providers/phone_providers.dart';
import '../services/connector_service.dart';
import '../widgets/connect/connect_tab.dart';
import '../widgets/filters/filters_tab.dart';
import '../widgets/history/history_tab.dart';
import '../widgets/permission_banner.dart';

part 'main_screen_body.dart';
part 'main_screen_dialog_launchers.dart';
part 'main_screen_dialogs.dart';

/// The root screen of the phone app. Listens to lifecycle changes to re-check
/// permissions, and hosts the tab navigation body.
class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen>
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
      ref.read(permissionProvider.notifier).checkPermission();
    }
  }

  @override
  Widget build(BuildContext context) {
    return _MainScreenBody(
      onManualConnect: _showManualConnectDialog,
      onPairDevice: _showPairingDialog,
      onAddCustomApp: _showAddCustomAppDialog,
    );
  }
}
