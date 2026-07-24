part of 'main_screen.dart';

/// PIN-entry dialog shown while pairing with a TV. Owns its own loading
/// state and text controller since the pairing round-trip is asynchronous.
class _PairingDialog extends StatefulWidget {
  const _PairingDialog({
    required this.device,
    required this.connector,
    required this.onResult,
  });

  final TVDevice device;
  final ConnectorService connector;

  /// Called after the dialog has popped itself, so the caller can show
  /// feedback (e.g. a SnackBar) using its own, longer-lived BuildContext.
  final void Function(bool isPaired) onResult;

  @override
  State<_PairingDialog> createState() => _PairingDialogState();
}

class _PairingDialogState extends State<_PairingDialog> {
  final _pinController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _confirmPin() async {
    final pin = _pinController.text.trim();
    if (pin.length != 4) return;

    setState(() => _isLoading = true);
    final isPaired = await widget.connector.confirmPairing(widget.device, pin);
    if (!mounted) return;
    Navigator.pop(context);
    widget.onResult(isPaired);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          YaruDialogTitleBar(
            title: Text('Pair with ${widget.device.name}'),
            isClosable: !_isLoading,
            onClose: (_) => Navigator.pop(context),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isLoading) ...[
                  const YaruCircularProgressIndicator(),
                  const SizedBox(height: 16),
                  const Text(
                    'Connecting...',
                    style: TextStyle(color: Colors.grey),
                  ),
                ] else ...[
                  const Text(
                    'Enter the 4-digit PIN displayed on your TV screen:',
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _pinController,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      letterSpacing: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: const InputDecoration(
                      counterText: '',
                      border: OutlineInputBorder(),
                      hintText: '0000',
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                if (!_isLoading)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _confirmPin,
                        child: const Text('Pair'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Dialog for connecting to a TV by manually entering its IP address and
/// port, used when mDNS discovery doesn't find it (e.g. emulator testing).
class _ManualConnectDialog extends StatelessWidget {
  _ManualConnectDialog({required this.onConnect});

  final void Function(String ip, int port) onConnect;

  final _ipController = TextEditingController(text: '10.0.2.2');
  final _portController = TextEditingController(text: '8080');

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          YaruDialogTitleBar(
            title: const Text('Connect with IP'),
            onClose: (_) => Navigator.pop(context),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                YaruSearchField(
                  controller: _ipController,
                  hintText: 'TV IP Address (e.g. 192.168.1.50)',
                ),
                const SizedBox(height: 12),
                YaruSearchField(
                  controller: _portController,
                  hintText: 'Port (e.g. 8080)',
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        final ip = _ipController.text.trim();
                        final port =
                            int.tryParse(_portController.text.trim()) ?? 8080;
                        if (ip.isNotEmpty) onConnect(ip, port);
                      },
                      child: const Text('Connect'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Dialog for adding a per-app notification filter by package name, for apps
/// not yet in the installed-apps preset list.
class _AddCustomAppDialog extends StatelessWidget {
  _AddCustomAppDialog({required this.onAdd});

  final void Function(String packageName) onAdd;

  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          YaruDialogTitleBar(
            title: const Text('Add Custom App Filter'),
            onClose: (_) => Navigator.pop(context),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                YaruSearchField(
                  controller: _controller,
                  hintText: 'App package name (e.g. com.spotify.music)',
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        final pkg = _controller.text.trim();
                        if (pkg.isNotEmpty) onAdd(pkg);
                      },
                      child: const Text('Add'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
