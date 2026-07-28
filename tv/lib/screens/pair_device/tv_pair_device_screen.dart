import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared/shared.dart';

import '../../providers/tv_providers.dart';
import '../../widgets/page_header.dart';

/// Pair Device page: a QR code (scanned by the phone app's QR scanner) and,
/// as a manual fallback, the 4-digit PIN shown broken into per-character
/// boxes.
///
/// The two paths are independent: the PIN only exists once a phone calls
/// `POST /api/pair` first, while the QR token is generated proactively (see
/// `ServerService._qrToken`) so it's scannable from a cold start, and is
/// single-use — regenerated after every pairing attempt.
class TvPairDeviceScreen extends ConsumerWidget {
  const TvPairDeviceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serviceState = ref.watch(tvServiceStateProvider);
    final tvIp = ref.watch(tvIpProvider).value;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 20,
        children: [
          const PageHeader(
            title: 'Pair Device',
            subtitle:
                'Connect your mobile device to receive notifications '
                'directly on your television screen while you watch.',
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 20,
              children: [
                Expanded(
                  child: _QrCard(tvIp: tvIp, qrToken: serviceState.qrToken),
                ),
                Expanded(child: _ManualPinCard(pin: serviceState.pairingPin)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QrCard extends ConsumerStatefulWidget {
  const _QrCard({required this.tvIp, required this.qrToken});

  final String? tvIp;
  final String? qrToken;

  @override
  ConsumerState<_QrCard> createState() => _QrCardState();
}

class _QrCardState extends ConsumerState<_QrCard> {
  Timer? _ipTimer;

  static const _validIps = {'Disconnected', 'Error fetching IP'};

  @override
  void initState() {
    super.initState();
    _ipTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => ref.invalidate(tvIpProvider),
    );
  }

  @override
  void dispose() {
    _ipTimer?.cancel();
    super.dispose();
  }

  bool get _canBuildQr {
    final ip = widget.tvIp;
    final token = widget.qrToken;
    if (ip == null || token == null) return false;
    if (_validIps.contains(ip)) return false;
    return InternetAddress.tryParse(ip)?.type == InternetAddressType.IPv4;
  }

  @override
  Widget build(BuildContext context) {
    final qrData = _canBuildQr
        ? jsonEncode({
            'ip': widget.tvIp,
            'port': MirrorProtocol.defaultPort,
            'token': widget.qrToken,
          })
        : null;

    final isRunning = ref.watch(tvServiceStateProvider).isRunning;

    return YaruSection(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          spacing: 16,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Scan to Pair Device'),
                const Spacer(),
                IconButton(
                  tooltip: 'Generate new code',
                  icon: const Icon(YaruIcons.refresh),
                  onPressed: () => ref
                      .read(tvServiceStateProvider.notifier)
                      .regenerateQrCode(),
                ),
              ],
            ),
            if (qrData != null)
              QrImageView(
                data: qrData,
                size: 200,
                backgroundColor: const Color(0xFFFFFFFF),
                errorStateBuilder: (ctx, error) => const Center(
                  child: Text('Could not generate QR code'),
                ),
              )
            else if (!isRunning)
              const _QrPlaceholder(
                icon: YaruIcons.warning,
                message: 'Service unavailable',
              )
            else if (widget.tvIp == null || widget.qrToken == null)
              const SizedBox(
                width: 200,
                height: 200,
                child: Center(child: YaruCircularProgressIndicator()),
              )
            else
              const _QrPlaceholder(
                icon: YaruIcons.warning,
                message: 'No network connection',
              ),
            const Text('Scan this code with your phone'),
            const Text(
              "Open the ${MirrorProtocol.appName} mobile app's QR scanner to pair it "
              'with this television instantly.',
            ),
          ],
        ),
      ),
    );
  }
}

class _QrPlaceholder extends StatelessWidget {
  const _QrPlaceholder({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 200,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 8,
        children: [
          Icon(icon, size: 32),
          Text(message),
        ],
      ),
    );
  }
}

class _ManualPinCard extends StatelessWidget {
  const _ManualPinCard({required this.pin});

  final String? pin;

  @override
  Widget build(BuildContext context) {
    return YaruSection(
      headline: const Text('MANUAL OPTION'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 16,
          children: [
            const Text('Pairing Code'),
            const Text(
              "Having trouble with the QR code? Enter this code manually "
              'in your mobile app.',
            ),
            _PinDisplay(pin: pin),
            const YaruListTile(
              leading: Icon(YaruIcons.information),
              title: Text('Need help?'),
              subtitle: Text(
                'Open the ${MirrorProtocol.appName} mobile app and choose "Enter code '
                'manually" from the pairing screen.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Renders the pairing PIN as a row of per-character boxes.
class _PinDisplay extends StatelessWidget {
  const _PinDisplay({required this.pin});

  final String? pin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final characters = (pin ?? '----').split('');

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 8,
      children: [
        for (final char in characters)
          Container(
            width: 40,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(char, style: theme.textTheme.headlineSmall),
          ),
      ],
    );
  }
}
