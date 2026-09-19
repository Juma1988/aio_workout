import 'dart:ui' show PlatformDispatcher;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'l10n/app_localizations.dart';

import 'core/clock.dart';
import 'core/localization/locale_provider.dart';
import 'core/theme/app_theme.dart';
import 'features/achievements/providers/achievement_provider.dart';
import 'features/achievements/services/shared_prefs_achievement_storage.dart';
import 'features/notifications/services/notification_service.dart';
import 'features/splash/splash_screen.dart';
import 'services/workout_storage_service.dart';

bool _firebaseReady = false;

void _configureErrorHandlers() {
  FlutterError.onError = (details) {
    if (_firebaseReady) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    } else {
      FlutterError.presentError(details);
    }
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    if (_firebaseReady) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    }
    return true;
  };

  ErrorWidget.builder = (FlutterErrorDetails details) {
    if (_firebaseReady) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    }
    return Material(
      child: Container(
        color: AppTheme.darkBackground,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.redAccent,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Something went wrong',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  details.exceptionAsString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  };
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _configureErrorHandlers();

  try {
    await Firebase.initializeApp();
    _firebaseReady = true;
  } catch (e, s) {
    debugPrint('Firebase init skipped: $e\n$s');
  }

  final localeProvider = LocaleProvider();
  await localeProvider.loadSavedLocale();

  await _initNotifications();

  runApp(
    ChangeNotifierProvider<LocaleProvider>.value(
      value: localeProvider,
      child: const MainApp(),
    ),
  );
}

Future<void> _initNotifications() async {
  try {
    final service = NotificationService();
    await service.initialize();
  } catch (e, s) {
    if (_firebaseReady) {
      FirebaseCrashlytics.instance.recordError(e, s, fatal: false);
    } else {
      debugPrint('Notification init error: $e\n$s');
    }
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
            home: SplashScreen(onThemeToggle: _toggleTheme),
          );
        },
      ),
    );
  }
}
