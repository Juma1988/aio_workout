import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';

import 'core/clock.dart';
import 'core/localization/locale_provider.dart';
import 'core/theme/app_theme.dart';
import 'features/achievements/providers/achievement_provider.dart';
import 'features/achievements/services/shared_prefs_achievement_storage.dart';
import 'features/navigation/main_shell.dart';
import 'features/notifications/services/notification_service.dart';
import 'services/workout_storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final localeProvider = LocaleProvider();
  await localeProvider.loadSavedLocale();

  await _initNotifications(localeProvider);

  runApp(
    ChangeNotifierProvider<LocaleProvider>.value(
      value: localeProvider,
      child: const MainApp(),
    ),
  );
}

Future<void> _initNotifications(LocaleProvider localeProvider) async {
  try {
    final service = NotificationService();
    await service.initialize();
  } catch (e) {
    debugPrint('Notification init failed (non-fatal): $e');
  }
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  ThemeMode _themeMode = ThemeMode.dark;
  final _workoutStorage = WorkoutStorageService();

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('theme_is_dark') ?? true;
    if (mounted) {
      setState(() {
        _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
      });
    }
  }

  void _toggleTheme() {
    final newMode = _themeMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    setState(() {
      _themeMode = newMode;
    });
    _persistThemeMode(newMode);
  }

  Future<void> _persistThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('theme_is_dark', mode == ThemeMode.dark);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AchievementProvider>(
          create: (_) => AchievementProvider(
            storage: SharedPrefsAchievementStorage(),
            clock: const SystemClock(),
            workoutStorage: _workoutStorage,
          ),
        ),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, _) {
          return MaterialApp(
            title: 'AIO Workout',
            debugShowCheckedModeBanner: false,
            locale: localeProvider.locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: LocaleProvider.supportedLocales,
            localeResolutionCallback: (locale, supportedLocales) {
              if (locale == null) return const Locale('en');
              for (final supported in supportedLocales) {
                if (supported.languageCode == locale.languageCode) {
                  return supported;
                }
              }
              return const Locale('en');
            },
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: _themeMode,
            home: MainShell(
              onThemeToggle: _toggleTheme,
            ),
          );
        },
      ),
    );
  }
}