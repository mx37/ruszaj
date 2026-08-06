// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTagline => 'Move through the city, simply.';

  @override
  String get chooseCity => 'Choose city';

  @override
  String get from => 'From';

  @override
  String get to => 'To';

  @override
  String get whereAreYouStarting => 'Where are you starting?';

  @override
  String get whereAreYouGoing => 'Where are you going?';

  @override
  String get useCurrentLocation => 'Use current location';

  @override
  String get findRoute => 'Find route';

  @override
  String get swapPlaces => 'Swap places';

  @override
  String get clear => 'Clear';

  @override
  String get route => 'Route';

  @override
  String get stops => 'Stops';

  @override
  String get stop => 'stop';

  @override
  String get settings => 'Settings';

  @override
  String get recentRoutes => 'Recent routes';

  @override
  String get noRecentRoutes => 'Your recent routes will appear here.';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get polish => 'Polski';

  @override
  String get locationPermissionNeeded =>
      'Location access helps find stops near you.';

  @override
  String get allowLocation => 'Allow location';

  @override
  String get notNow => 'Not now';

  @override
  String get locationUnavailable => 'Location is unavailable';

  @override
  String get selectCity => 'Select city';

  @override
  String get searchCities => 'Search cities';

  @override
  String get noResults => 'No results';

  @override
  String get close => 'Close';

  @override
  String get routeOptions => 'Route options';

  @override
  String get searching => 'Searching...';

  @override
  String get noRoute => 'No route found';

  @override
  String get requestFailed => 'Could not load results';

  @override
  String get nearbyTitle => 'Nearby stops';

  @override
  String get refresh => 'Refresh';

  @override
  String get searchUnavailable => 'Search unavailable';

  @override
  String get walking => 'Walking';

  @override
  String get transit => 'Public transport';

  @override
  String get transfers => 'transfers';

  @override
  String get transfer => 'transfer';

  @override
  String get minutes => 'min';

  @override
  String inMinutes(int minutes) {
    return 'in $minutes min';
  }

  @override
  String get walkTo => 'Walk to stop';

  @override
  String get youAreHere => 'You are here';

  @override
  String get mapLoading => 'Building walking route...';

  @override
  String get mapRouteUnavailable => 'Walking route unavailable';

  @override
  String get lightTheme => 'Light';

  @override
  String get darkTheme => 'Dark';

  @override
  String get savePlace => 'Save place';

  @override
  String get name => 'Name';

  @override
  String get icon => 'Icon';

  @override
  String get save => 'Save';

  @override
  String get savedPlaces => 'Saved places';

  @override
  String get recentPlaces => 'Recent places';

  @override
  String get noUpcomingJourneys => 'No upcoming departures';
}
