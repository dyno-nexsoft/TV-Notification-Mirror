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
  final List<AppPreset> installedPresets;
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

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      initialIndex: currentIndex,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('TV Mirror'),
          systemOverlayStyle: SystemUiOverlayStyle.light,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: IconButton(
                icon: const Icon(YaruIcons.refresh),
                onPressed: onRefresh,
                tooltip: 'Refresh / Scan',
              ),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(YaruIcons.computer), text: 'Connect'),
              Tab(icon: Icon(YaruIcons.pen), text: 'Apps'),
              Tab(icon: Icon(YaruIcons.history), text: 'History'),
            ],
          ),
        ),
        body: Column(
          children: [
            if (!hasPermission) PermissionBanner(notifier: notifier),
            Expanded(
              child: TabBarView(
                children: [
                  _TabContent(
                    index: 0,
                    isConnected: isConnected,
                    discoveredDevices: discoveredDevices,
                    connectedTvName: connector.connectedTvName,
                    tvDndEnabled: settings.tvDndEnabled,
                    settings: settings,
                    connector: connector,
                    appFilters: appFilters,
                    installedPresets: installedPresets,
                    appIconCache: appIconCache,
                    history: history,
                    onSendTest: onSendTest,
                    onManualConnect: onManualConnect,
                    onDndChanged: onDndChanged,
                    onPairDevice: onPairDevice,
                    onSettingsChanged: onSettingsChanged,
                    onFilterChanged: onFilterChanged,
                    onAddCustomApp: onAddCustomApp,
                  ),
                  _TabContent(
                    index: 1,
                    isConnected: isConnected,
                    discoveredDevices: discoveredDevices,
                    connectedTvName: connector.connectedTvName,
                    tvDndEnabled: settings.tvDndEnabled,
                    settings: settings,
                    connector: connector,
                    appFilters: appFilters,
                    installedPresets: installedPresets,
                    appIconCache: appIconCache,
                    history: history,
                    onSendTest: onSendTest,
                    onManualConnect: onManualConnect,
                    onDndChanged: onDndChanged,
                    onPairDevice: onPairDevice,
                    onSettingsChanged: onSettingsChanged,
                    onFilterChanged: onFilterChanged,
                    onAddCustomApp: onAddCustomApp,
                  ),
                  _TabContent(
                    index: 2,
                    isConnected: isConnected,
                    discoveredDevices: discoveredDevices,
                    connectedTvName: connector.connectedTvName,
                    tvDndEnabled: settings.tvDndEnabled,
                    settings: settings,
                    connector: connector,
                    appFilters: appFilters,
                    installedPresets: installedPresets,
                    appIconCache: appIconCache,
                    history: history,
                    onSendTest: onSendTest,
                    onManualConnect: onManualConnect,
                    onDndChanged: onDndChanged,
                    onPairDevice: onPairDevice,
                    onSettingsChanged: onSettingsChanged,
                    onFilterChanged: onFilterChanged,
                    onAddCustomApp: onAddCustomApp,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabContent extends StatelessWidget {
  const _TabContent({
    required this.index,
    required this.isConnected,
    required this.discoveredDevices,
    this.connectedTvName,
    required this.tvDndEnabled,
    required this.settings,
    required this.connector,
    required this.appFilters,
    required this.installedPresets,
    required this.appIconCache,
    required this.history,
    required this.onSendTest,
    required this.onManualConnect,
    required this.onDndChanged,
    required this.onPairDevice,
    required this.onSettingsChanged,
    required this.onFilterChanged,
    required this.onAddCustomApp,
  });
  final int index;
  final bool isConnected;
  final List<TVDevice> discoveredDevices;
  final String? connectedTvName;
  final bool tvDndEnabled;
  final AppSettings settings;
  final ConnectorService connector;
  final Map<String, bool> appFilters;
  final List<AppPreset> installedPresets;
  final Map<String, Uint8List?> appIconCache;
  final List<NotificationItem> history;
  final VoidCallback onSendTest;
  final VoidCallback onManualConnect;
  final ValueChanged<bool> onDndChanged;
  final void Function(TVDevice device) onPairDevice;
  final ValueChanged<AppSettings> onSettingsChanged;
  final void Function(String packageName, bool value) onFilterChanged;
  final VoidCallback onAddCustomApp;

  @override
  Widget build(BuildContext context) {
    return switch (index) {
      0 => ConnectTab(
          isConnected: isConnected,
          discoveredDevices: discoveredDevices,
          connectedTvName: connectedTvName,
          tvDndEnabled: tvDndEnabled,
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
}
