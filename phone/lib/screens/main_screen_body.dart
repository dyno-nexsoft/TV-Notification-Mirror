part of 'main_screen.dart';

/// Composes the navigation rail and the currently selected tab. Pulled out of
/// [_MainScreenState] so the state class stays focused on lifecycle and data,
/// with pure widget composition living here instead.
class _MainScreenBody extends StatelessWidget {
  const _MainScreenBody({
    required this.currentIndex,
    required this.hasPermission,
    required this.isConnected,
    required this.discoveredDevices,
    required this.history,
    required this.appFilters,
    required this.appIconCache,
    required this.installedPresets,
    required this.settings,
    required this.connector,
    required this.notifier,
    required this.onTabSelected,
    required this.onRefresh,
    required this.onSendTest,
    required this.onManualConnect,
    required this.onDndChanged,
    required this.onPairDevice,
    required this.onSettingsChanged,
    required this.onFilterChanged,
    required this.onAddCustomApp,
  });

  final int currentIndex;
  final bool hasPermission;
  final bool isConnected;
  final List<TVDevice> discoveredDevices;
  final List<NotificationItem> history;
  final Map<String, bool> appFilters;
  final Map<String, Uint8List?> appIconCache;
  final List<Map<String, dynamic>> installedPresets;
  final AppSettings settings;
  final ConnectorService connector;
  final NotificationService notifier;

  final ValueChanged<int> onTabSelected;
  final VoidCallback onRefresh;
  final VoidCallback onSendTest;
  final VoidCallback onManualConnect;
  final ValueChanged<bool> onDndChanged;
  final void Function(TVDevice device) onPairDevice;
  final ValueChanged<AppSettings> onSettingsChanged;
  final void Function(String packageName, bool value) onFilterChanged;
  final VoidCallback onAddCustomApp;

  static const _navItems = [
    (icon: YaruIcons.computer, label: 'Connect'),
    (icon: YaruIcons.pen, label: 'Apps'),
    (icon: YaruIcons.history, label: 'History'),
  ];

  Widget _buildTab(int index) {
    return switch (index) {
      0 => ConnectTab(
          isConnected: isConnected,
          discoveredDevices: discoveredDevices,
          connectedTvName: connector.connectedTvName,
          tvDndEnabled: settings.tvDndEnabled,
          settings: settings,
          connector: connector,
          onSendTest: onSendTest,
          onManualConnect: onManualConnect,
          onDndChanged: onDndChanged,
          onPairDevice: onPairDevice,
        ),
      1 => FiltersTab(
          settings: settings,
          appFilters: appFilters,
          installedPresets: installedPresets,
          iconCache: appIconCache,
          onSettingsChanged: onSettingsChanged,
          onFilterChanged: onFilterChanged,
          onAddCustomApp: onAddCustomApp,
        ),
      _ => HistoryTab(
          history: history,
          iconCache: appIconCache,
        ),
    };
  }

  Widget _buildPage(int index) {
    if (!hasPermission) {
      return Column(
        children: [
          PermissionBanner(notifier: notifier),
          Expanded(child: _buildTab(index)),
        ],
      );
    }
    return _buildTab(index);
  }

  @override
  Widget build(BuildContext context) {
    return YaruNavigationPage(
      length: _navItems.length,
      initialIndex: currentIndex,
      onSelected: onTabSelected,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: YaruIconButton(
          icon: const Icon(YaruIcons.refresh),
          onPressed: onRefresh,
          tooltip: 'Refresh / Scan',
        ),
      ),
      itemBuilder: (context, index, selected) => YaruNavigationRailItem(
        icon: Icon(_navItems[index].icon),
        label: Text(_navItems[index].label),
        style: YaruNavigationRailStyle.labelledExtended,
        selected: selected,
      ),
      pageBuilder: (context, index) => _buildPage(index),
    );
  }
}
