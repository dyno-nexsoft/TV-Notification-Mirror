import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';

import 'providers/phone_providers.dart';
import 'screens/main_screen.dart';
import 'services/background_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeBackgroundService();
  runApp(const ProviderScope(child: MyApp()));
}

/// Root application widget configured with Yaru UI theme.
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(
      settingsProvider
          .select((settings) => settings.value?.themeMode ?? ThemeMode.dark),
    );

    return YaruTheme(
      builder: (context, yaru, child) {
        return MaterialApp(
          title: MirrorProtocol.appName,
          themeMode: themeMode,
          theme: YaruAppTheme.lightTheme,
          darkTheme: YaruAppTheme.darkTheme,
          builder: (context, child) {
            return GestureDetector(
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              child: child,
            );
          },
          home: const MainScreen(),
        );
      },
    );
  }
}
