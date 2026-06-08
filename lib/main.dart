import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/navigation/main_shell.dart';
import 'features/notifications/services/notification_repository.dart';
import 'features/notifications/services/notification_service.dart';
import 'features/notifications/services/notification_strings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().initialize();
  final repo = NotificationRepository();
  final lang = await repo.languageCode;
  NotificationStrings.setOverride(lang);
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark
          ? ThemeMode.light
          : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AIO Workout',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: _themeMode,
      home: MainShell(
        onThemeToggle: _toggleTheme,
      ),
    );
  }
}
