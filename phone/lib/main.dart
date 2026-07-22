import 'package:flutter/material.dart';
import 'package:yaru/yaru.dart';
import 'app_theme.dart';
import 'screens/main_screen.dart';

void main() {
  runApp(const MyApp());
}

/// Root application widget configured with Yaru UI theme.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return YaruTheme(
      builder: (context, yaru, child) {
        return MaterialApp(
          title: 'TV Notification Mirror',
          themeMode: ThemeMode.dark,
          theme: yaru.theme,
          darkTheme: AppTheme.darkTheme,
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
