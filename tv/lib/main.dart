import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';

import 'providers/tv_settings_provider.dart';
import 'screens/tv_main_screen.dart';
import 'services/background_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  initializeBackgroundService();
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

/// TV Root Application Widget. Configured with Yaru UI theme.
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(
      tvSettingsProvider.select((settings) => settings.themeMode),
    );

    return YaruTheme(
      builder: (context, yaru, child) {
        return MaterialApp(
          title: 'TV Notification Receiver',
          themeMode: themeMode,
          theme: yaru.theme,
          darkTheme: YaruAppTheme.darkTheme,
          home: const TvMainScreen(),
        );
      },
    );
  }
}
