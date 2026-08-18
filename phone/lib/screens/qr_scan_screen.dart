import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared/shared.dart';

import '../providers/phone_providers.dart';

/// Full-screen camera QR scanner for pairing with a TV — scans the code
/// shown on the TV's Pair Device screen and pairs immediately, skipping the
/// manual PIN-entry step entirely.
class QrScanScreen extends ConsumerStatefulWidget {
  const QrScanScreen({super.key});

  @override
  ConsumerState<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends ConsumerState<QrScanScreen> {
  final _controller = MobileScannerController();
  var _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final rawValue = capture.barcodes.firstOrNull?.rawValue;
    if (rawValue == null) return;

    setState(() => _isProcessing = true);
    await _controller.stop();

    final outcome =
        await ref.read(connectorProvider.notifier).pairViaQr(rawValue);
    if (!mounted) return;

    ref.read(appToastProvider.notifier).show(
          outcome.success
              ? 'Successfully paired via QR code!'
              : (outcome.message ?? 'Invalid or expired QR code. Please try again.'),
        );

    if (outcome.success) {
      Navigator.pop(context);
    } else {
      setState(() => _isProcessing = false);
      await _controller.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR Code')),
      body: Stack(
        alignment: Alignment.center,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _handleDetect,
          ),
          if (_isProcessing) const YaruCircularProgressIndicator(),
        ],
      ),
    );
  }
}
