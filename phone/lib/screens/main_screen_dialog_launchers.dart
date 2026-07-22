part of 'main_screen.dart';

/// Thin `showDialog(...)` callers for [_MainScreenState], kept separate so
/// the state class doesn't carry the weight of each dialog's widget tree.
extension _DialogLauncher on _MainScreenState {
  void _showPairingDialog(TVDevice device) async {
    final success = await _connector.startPairing(device);
    if (!success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Failed to connect to TV. Make sure the TV app is open.'),
          ),
        );
      }
      return;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => _PairingDialog(
        device: device,
        connector: _connector,
        onResult: (isPaired) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isPaired
                      ? 'Successfully paired with ${device.name}!'
                      : 'Incorrect PIN. Please try again.',
                ),
              ),
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
          _saveFilter(pkg, true);
          Navigator.pop(dialogCtx);
        },
      ),
    );
  }
}
