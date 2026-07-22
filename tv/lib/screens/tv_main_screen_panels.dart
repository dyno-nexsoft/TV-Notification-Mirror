part of 'tv_main_screen.dart';

/// Left panel of the TV dashboard: branding, permission warnings / server
/// status, and the primary DND + test-overlay controls.
class _LeftControlPanel extends StatelessWidget {
  const _LeftControlPanel({
    required this.hasOverlayPermission,
    required this.hasNotificationPermission,
    required this.isRunning,
    required this.isDnd,
    required this.tvIp,
    required this.primaryColor,
    required this.errorColor,
    required this.onToggleDnd,
    required this.onCheckPermission,
    required this.onTestOverlay,
  });

  final bool hasOverlayPermission;
  final bool hasNotificationPermission;
  final bool isRunning;
  final bool isDnd;
  final String tvIp;
  final Color primaryColor;
  final Color errorColor;
  final VoidCallback onToggleDnd;
  final VoidCallback onCheckPermission;
  final VoidCallback onTestOverlay;

  bool get _hasAllPermissions =>
      hasOverlayPermission && hasNotificationPermission;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TV MIRROR',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Gương thông báo điện thoại lên TV',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const Spacer(),
          if (!hasOverlayPermission) ...[
            const OverlayWarningCard(),
          ] else if (!hasNotificationPermission) ...[
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
            onPressed: _hasAllPermissions ? onToggleDnd : onCheckPermission,
            color: isDnd ? errorColor : primaryColor,
            label: _hasAllPermissions
                ? (isDnd ? 'Turn DND OFF' : 'Turn DND ON')
                : 'Check Permission Again',
            icon: isDnd ? Icons.do_not_disturb_on : Icons.do_not_disturb_off,
          ),
          const SizedBox(height: 16),
          if (_hasAllPermissions) ...[
            TvButton(
              onPressed: onTestOverlay,
              color: const Color(0xFF2E2A4A),
              label: 'Test Overlay Notification',
              icon: Icons.play_arrow,
            ),
          ],
        ],
      ),
    );
  }
}

/// Right panel of the TV dashboard: pairing/connection status header plus
/// the paired-devices and recent-notifications sub-columns.
class _RightInfoPanel extends StatelessWidget {
  const _RightInfoPanel({
    required this.pairingPin,
    required this.pairedClients,
    required this.activeTokens,
    required this.notificationHistory,
    required this.primaryColor,
    required this.onRemoveClient,
  });

  final String? pairingPin;
  final List<dynamic> pairedClients;
  final Set<String> activeTokens;
  final List<dynamic> notificationHistory;
  final Color primaryColor;
  final void Function(String token, String deviceName) onRemoveClient;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (pairingPin != null)
            PairingBox(pin: pairingPin!)
          else if (activeTokens.isNotEmpty)
            ConnectedBox(
              pairedClients: pairedClients,
              activeTokens: activeTokens,
            )
          else
            const WaitingBox(),
          const SizedBox(height: 24),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left sub-column: Paired Devices
                Expanded(
                  flex: 1,
                  child: _PairedDevicesPanel(
                    pairedClients: pairedClients,
                    activeTokens: activeTokens,
                    onRemove: onRemoveClient,
                  ),
                ),
                const SizedBox(width: 20),
                Container(
                  width: 1,
                  color: Colors.white10,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                ),
                const SizedBox(width: 20),
                // Right sub-column: Notifications history
                Expanded(
                  flex: 1,
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
class _PairedDevicesPanel extends StatelessWidget {
  const _PairedDevicesPanel({
    required this.pairedClients,
    required this.activeTokens,
    required this.onRemove,
  });

  final List<dynamic> pairedClients;
  final Set<String> activeTokens;
  final void Function(String token, String deviceName) onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Paired Devices',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: pairedClients.isEmpty
              ? const _EmptyClientsCard()
              : ListView.builder(
                  itemCount: pairedClients.length,
                  itemBuilder: (context, index) {
                    final client = pairedClients[index];
                    final token = client['token'] as String? ?? '';
                    final deviceName = client['deviceName'] ?? 'Unknown Phone';
                    return PairedDeviceCard(
                      deviceName: deviceName,
                      ip: client['ip'] ?? '',
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
        children: [
          Icon(Icons.phone_android_outlined, size: 48, color: Colors.grey),
          SizedBox(height: 12),
          Text(
            'No devices paired yet.',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

