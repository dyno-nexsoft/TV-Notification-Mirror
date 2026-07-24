part of 'main_screen.dart';

/// PIN-entry dialog shown while pairing with a TV.
class _PairingDialog extends ConsumerStatefulWidget {
  const _PairingDialog({
    required this.device,
    required this.onResult,
  });

  final TVDevice device;
  final void Function(bool isPaired) onResult;

  @override
  ConsumerState<_PairingDialog> createState() => _PairingDialogState();
}

class _PairingDialogState extends ConsumerState<_PairingDialog> {
  final _pinController = TextEditingController();
  var _isLoading = false;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _confirmPin() async {
    final pin = _pinController.text.trim();
    if (pin.length != 4) return;

    setState(() => _isLoading = true);
    final isPaired = await ref
        .read(connectorProvider.notifier)
        .confirmPairing(widget.device, pin);
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
              spacing: 16,
              children: [
                if (_isLoading) ...[
                  const YaruCircularProgressIndicator(),
                  const Text('Connecting...'),
                ] else ...[
                  const Text(
                    'Enter the 4-digit PIN displayed on your TV screen:',
                  ),
                  YaruSearchField(
                    controller: _pinController,
                    hintText: '0000',
                    onChanged: (v) => setState(() {}),
                    onClear: () {
                      _pinController.clear();
                      setState(() {});
                    },
                  ),
                ],
                if (!_isLoading)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    spacing: 8,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
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

/// Dialog for connecting to a TV by manually entering its IP address and port.
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
              spacing: 12,
              children: [
                StatefulBuilder(
                  builder: (context, setState) => YaruSearchField(
                    controller: _ipController,
                    hintText: 'TV IP Address (e.g. 192.168.1.50)',
                    onChanged: (v) => setState(() {}),
                    onClear: () {
                      _ipController.clear();
                      setState(() {});
                    },
                  ),
                ),
                StatefulBuilder(
                  builder: (context, setState) => YaruSearchField(
                    controller: _portController,
                    hintText: 'Port (e.g. 8080)',
                    onChanged: (v) => setState(() {}),
                    onClear: () {
                      _portController.clear();
                      setState(() {});
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  spacing: 8,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
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

/// Dialog for adding a per-app notification filter by package name.
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
              spacing: 20,
              children: [
                StatefulBuilder(
                  builder: (context, setState) => YaruSearchField(
                    controller: _controller,
                    hintText: 'App package name (e.g. com.spotify.music)',
                    onChanged: (v) => setState(() {}),
                    onClear: () {
                      _controller.clear();
                      setState(() {});
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  spacing: 8,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
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
