part of 'main_screen.dart';

/// Extension methods on [_MainScreenState] for launching dialogs.
extension _DialogLauncher on _MainScreenState {
  void _showPairingDialog(TVDevice device) async {
    final connectorNotifier = ref.read(connectorProvider.notifier);
    final success = await connectorNotifier.startPairing(device);
    if (!success) {
      ref
          .read(appToastProvider.notifier)
          .show('Invalid PIN or error occurred.');
      return;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => _PairingDialog(
        device: device,
        onResult: (isPaired) {
          if (mounted) {
            ref.read(appToastProvider.notifier).show(
                  isPaired
                      ? 'Successfully paired with ${device.name}!'
                      : 'Incorrect PIN. Please try again.',
                );
          }
        },
      ),
    );
  }

  void _showManualConnectDialog() {
    showDialog(
      context: context,
      builder: (dialogCtx) => _ManualConnectDialog(
        onConnect: (ip, port) {
          Navigator.pop(dialogCtx);
          _showPairingDialog(TVDevice(name: 'Manual TV', ip: ip, port: port));
        },
      ),
    );
  }

  void _showAddCustomAppDialog() {
    showDialog(
      context: context,
      builder: (dialogCtx) => _AddCustomAppDialog(
        onAdd: (pkg) {
          ref.read(filtersProvider.notifier).addCustomAppPreset(pkg, pkg);
          Navigator.pop(dialogCtx);
        },
      ),
    );
  }
}
