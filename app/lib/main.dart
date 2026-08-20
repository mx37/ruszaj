import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'l10n/generated/app_localizations.dart';
import 'location/location_service.dart';
import 'theme/app_theme.dart';
import 'widgets/app_icon.dart';
import 'widgets/floating_nav.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'data/ruszaj_api.dart';
import 'map/walk_to_stop_page.dart';
import 'settings/settings_page.dart';

part 'features/home/home_screen.dart';
part 'features/journey/journey_planner.dart';
part 'features/journey/journey_options.dart';
part 'features/journey/journey_results.dart';
part 'features/places/saved_places.dart';
part 'features/nearby/nearby_screen.dart';

void main() => runApp(const RuszajApp());

class RuszajApp extends StatefulWidget {
  const RuszajApp({super.key});

  @override
  State<RuszajApp> createState() => _RuszajAppState();
}

class _RuszajAppState extends State<RuszajApp> {
  Locale? _locale;
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadLocale();
    _loadTheme();
    _loadApiBaseUrl();
  }

  Future<void> _loadApiBaseUrl() async {
    final preferences = await SharedPreferences.getInstance();
    RuszajApi.setBaseUrlOverride(preferences.getString('api_base_url') ?? '');
  }

  Future<void> _loadTheme() async {
    final preferences = await SharedPreferences.getInstance();
    final value = preferences.getString('theme_mode');
    if (!mounted || value == null) return;
    setState(
      () => _themeMode = value == 'dark' ? ThemeMode.dark : ThemeMode.light,
    );
  }

  Future<void> _setThemeMode(ThemeMode mode) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      'theme_mode',
      mode == ThemeMode.dark ? 'dark' : 'light',
    );
    if (mounted) setState(() => _themeMode = mode);
  }

  Future<void> _loadLocale() async {
    final preferences = await SharedPreferences.getInstance();
    final language = preferences.getString('language');
    if (language != null && mounted) setState(() => _locale = Locale(language));
  }

  Future<void> _setLocale(Locale locale) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('language', locale.languageCode);
    if (mounted) setState(() => _locale = locale);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ruszaj',
      debugShowCheckedModeBanner: false,
      theme: appTheme(),
      darkTheme: appTheme(brightness: Brightness.dark),
      themeMode: _themeMode,
      locale: _locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: (locale, supported) {
        if (locale == null) return supported.first;
        return supported.firstWhere(
          (item) => item.languageCode == locale.languageCode,
          orElse: () => supported.first,
        );
      },
      home: HomeScreen(
        locale: _locale,
        themeMode: _themeMode,
        onLocaleChanged: _setLocale,
        onThemeChanged: _setThemeMode,
      ),
    );
  }
}
