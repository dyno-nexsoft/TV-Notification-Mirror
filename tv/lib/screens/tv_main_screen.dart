import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';

import '../providers/tv_providers.dart';
import '../widgets/paired_device_card.dart';
import '../widgets/status_info_boxes.dart';
import '../widgets/tv_button.dart';

part 'tv_main_screen_dialogs.dart';
part 'tv_main_screen_panels.dart';
part 'tv_main_screen_notifications.dart';

/// TV main dashboard screen — uses Riverpod to monitor permissions and background
/// service state with D-pad friendly UI.
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await _showExitConfirmDialog();
        if (shouldExit && context.mounted) {
          await SystemNavigator.pop();
        }
      },
      child: const Scaffold(
        body: Row(
          children: [
            Expanded(
              child: _LeftControlPanel(),
            ),
            Expanded(
              flex: 2,
              child: _RightInfoPanel(),
            ),
          ],
        ),
      ),
    );
  }
}
