import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');
  bool _initialized = false;

  static const String _languageKey = 'notif_language';
  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('ar'),
  ];

  bool get isRTL => _locale.languageCode == 'ar';
  Locale get locale => _locale;
  bool get initialized => _initialized;

  Future<void> loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_languageKey);
    if (code != null && supportedLocales.any((l) => l.languageCode == code)) {
      _locale = Locale(code);
    } else {
      _locale = _deviceLocaleFallback();
    }
    _initialized = true;
    notifyListeners();
  }

  Locale _deviceLocaleFallback() {
    final device = WidgetsBinding.instance.platformDispatcher.locale;
    if (device.languageCode == 'ar') return const Locale('ar');
    return const Locale('en');
  }

  Future<void> setLocale(Locale locale) async {
    if (!supportedLocales.any((l) => l.languageCode == locale.languageCode)) {
      return;
    }
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, locale.languageCode);
  }

  Future<void> setLanguageCode(String code) async {
    await setLocale(Locale(code));
  }
}
