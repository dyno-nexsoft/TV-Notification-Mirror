part of 'tv_main_screen.dart';

/// Left panel of the TV dashboard: branding, permission warnings / server
/// status, and the primary DND + test-overlay controls.
class _LeftControlPanel extends ConsumerWidget {
  const _LeftControlPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionsAsync = ref.watch(tvPermissionsProvider);
    final tvIpAsync = ref.watch(tvIpProvider);
    final tvState = ref.watch(tvServiceStateProvider);

    return permissionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
      data: (permissions) {
        final hasOverlay = permissions.hasOverlayPermission;
        final hasNotification = permissions.hasNotificationPermission;
        final hasAllPermissions = permissions.isFullyGranted;
        final isDnd = tvState.isDnd;
        final isRunning = tvState.isRunning;
        final tvIp = tvIpAsync.value ?? 'Loading IP...';

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 8,
            children: [
              const Text('TV MIRROR'),
              const Text('Mirror phone notifications to TV'),
              const Spacer(),
              if (!hasOverlay) ...[
                const OverlayWarningCard(),
              ] else if (!hasNotification) ...[
                const NotificationWarningCard(),
              ] else ...[
                ServerInfoCard(
                  isRunning: isRunning,
                  isDnd: isDnd,
                  tvIp: tvIp,
                ),
              ],
              const Spacer(),
              TvButton(
                onPressed: () {
                  if (hasAllPermissions) {
                    ref.read(tvServiceStateProvider.notifier).toggleDnd();
                  } else {
                    ref.read(tvPermissionsProvider.notifier).checkPermissions();
                  }
                },
                label: hasAllPermissions
                    ? (isDnd ? 'Turn DND OFF' : 'Turn DND ON')
                    : 'Check Permission Again',
                icon:
                    isDnd ? Icons.do_not_disturb_on : Icons.do_not_disturb_off,
              ),
              if (hasAllPermissions) ...[
                TvButton(
                  onPressed: () {
                    ref.read(tvServiceStateProvider.notifier).testOverlay();
                  },
                  label: 'Test Overlay Notification',
                  icon: Icons.play_arrow,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Right panel of the TV dashboard: pairing/connection status header plus
/// the paired-devices and recent-notifications sub-columns.
class _RightInfoPanel extends ConsumerWidget {
  const _RightInfoPanel();

  void _confirmRemoveClient(
    BuildContext context,
    WidgetRef ref,
    String token,
    String deviceName,
  ) {
    showDialog(
      context: context,
      builder: (dialogCtx) => _RemoveDeviceDialog(
        deviceName: deviceName,
        onConfirm: () {
          Navigator.pop(dialogCtx);
          ref.read(tvServiceStateProvider.notifier).removeClient(token);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tvState = ref.watch(tvServiceStateProvider);
    final pairingPin = tvState.pairingPin;
    final pairedClients = tvState.pairedClients;
    final activeTokens = tvState.activeTokens;
    final notificationHistory = tvState.notificationHistory;
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 24,
        children: [
          if (pairingPin != null)
            PairingBox(pin: pairingPin)
          else if (activeTokens.isNotEmpty)
            ConnectedBox(
              pairedClients: pairedClients,
              activeTokens: activeTokens,
            )
          else
            const WaitingBox(),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 20,
              children: [
                // Left sub-column: Paired Devices
                Expanded(
                  child: _PairedDevicesPanel(
                    onRemove: (token, deviceName) => _confirmRemoveClient(
                      context,
                      ref,
                      token,
                      deviceName,
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  color: Colors.white10,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                ),
                // Right sub-column: Notifications history
                Expanded(
                  child: _RecentNotificationsPanel(
                    notificationHistory: notificationHistory,
                    primaryColor: primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Left sub-column of the TV dashboard: the list of paired phones with their
/// online/offline state and a remove action for each.
class _PairedDevicesPanel extends ConsumerWidget {
  const _PairedDevicesPanel({
    required this.onRemove,
  });

  final void Function(String token, String deviceName) onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tvState = ref.watch(tvServiceStateProvider);
    final pairedClients = tvState.pairedClients;
    final activeTokens = tvState.activeTokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [
        const Text('Paired Devices'),
        Expanded(
          child: pairedClients.isEmpty
              ? const _EmptyClientsCard()
              : ListView.builder(
                  itemCount: pairedClients.length,
                  itemBuilder: (context, index) {
                    final client = pairedClients[index];
                    final token = client.token ?? '';
                    final deviceName = client.name;
                    return PairedDeviceCard(
                      deviceName: deviceName,
                      ip: client.ip,
                      isOnline: activeTokens.contains(token),
                      onRemove: () => onRemove(token, deviceName),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _EmptyClientsCard extends StatelessWidget {
  const _EmptyClientsCard();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 12,
        children: [
          Icon(Icons.phone_android_outlined),
          Text('No devices paired yet.'),
        ],
      ),
    );
  }
}
