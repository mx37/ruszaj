// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get appTagline => 'Poruszaj się po mieście. Prościej.';

  @override
  String get chooseCity => 'Wybierz miasto';

  @override
  String get from => 'Z';

  @override
  String get to => 'Do';

  @override
  String get whereAreYouStarting => 'Skąd jedziesz?';

  @override
  String get whereAreYouGoing => 'Dokąd jedziesz?';

  @override
  String get useCurrentLocation => 'Użyj bieżącej lokalizacji';

  @override
  String get findRoute => 'Znajdź trasę';

  @override
  String get swapPlaces => 'Zamień miejscami';

  @override
  String get clear => 'Wyczyść';

  @override
  String get route => 'Trasa';

  @override
  String get stops => 'Przystanki';

  @override
  String get settings => 'Ustawienia';

  @override
  String get recentRoutes => 'Ostatnie trasy';

  @override
  String get noRecentRoutes => 'Ostatnie trasy pojawią się tutaj.';

  @override
  String get language => 'Język';

  @override
  String get english => 'English';

  @override
  String get polish => 'Polski';

  @override
  String get locationPermissionNeeded =>
      'Dostęp do lokalizacji pomoże znaleźć przystanki w pobliżu.';

  @override
  String get allowLocation => 'Zezwól na lokalizację';

  @override
  String get notNow => 'Nie teraz';

  @override
  String get locationUnavailable => 'Lokalizacja jest niedostępna';

  @override
  String get selectCity => 'Wybierz miasto';

  @override
  String get searchCities => 'Szukaj miast';

  @override
  String get noResults => 'Brak wyników';

  @override
  String get close => 'Zamknij';

  @override
  String get routeOptions => 'Opcje trasy';

  @override
  String get searching => 'Wyszukiwanie...';

  @override
  String get noRoute => 'Nie znaleziono trasy';

  @override
  String get requestFailed => 'Nie udało się pobrać wyników';
}
