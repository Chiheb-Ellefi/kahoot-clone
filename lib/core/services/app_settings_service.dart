import 'package:flutter/material.dart';

class AppSettingsService {
  AppSettingsService._();
  static final AppSettingsService instance = AppSettingsService._();

  final ValueNotifier<ThemeMode> themeMode =
      ValueNotifier<ThemeMode>(ThemeMode.system);
  final ValueNotifier<Locale> locale = const ValueNotifier<Locale>(Locale('en'));

  void setThemeMode(ThemeMode mode) => themeMode.value = mode;
  void setLocale(Locale newLocale) => locale.value = newLocale;
}
