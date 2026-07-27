import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared/shared.dart';

import '../../providers/tv_providers.dart';
import '../../widgets/page_header.dart';

/// Pair Device page: a QR code (scanned by the phone app) and, as a manual
/// fallback, the same PIN shown broken into per-character boxes.
///
/// The QR code currently just encodes the PIN as plain text — the phone app
/// does not yet have a QR scanner, so this is a visual placeholder ahead of
/// a real deep-link pairing protocol (out of scope for this refactor).
class TvPairDeviceScreen extends ConsumerWidget {
  const TvPairDeviceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pairingPin = ref.watch(tvServiceStateProvider).pairingPin;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 20,
        children: [
          const PageHeader(
            title: 'Pair Device',
            subtitle: 'Connect your mobile device to receive notifications '
                'directly on your television screen while you watch.',
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 20,
              children: [
                Expanded(child: _QrCard(pin: pairingPin)),
                Expanded(child: _ManualPinCard(pin: pairingPin)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QrCard extends StatelessWidget {
  const _QrCard({required this.pin});

  final String? pin;

  @override
  Widget build(BuildContext context) {
    return YaruSection(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          spacing: 16,
          children: [
            const Text('Scan to Pair Device'),
            if (pin != null)
              QrImageView(
                data: pin!,
                size: 200,
              )
            else
              const SizedBox(
                width: 200,
                height: 200,
                child: Center(child: YaruCircularProgressIndicator()),
              ),
            const Text('Scan this code with your phone'),
            const Text(
              "Open your phone's camera or the NotifyMirror mobile app to "
              'pair it with this television instantly.',
            ),
          ],
        ),
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
                'Open the NotifyMirror mobile app and choose "Enter code '
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
