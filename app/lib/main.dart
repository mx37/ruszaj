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

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.locale,
    required this.themeMode,
    required this.onLocaleChanged,
    required this.onThemeChanged,
  });

  final Locale? locale;
  final ThemeMode themeMode;
  final ValueChanged<Locale> onLocaleChanged;
  final ValueChanged<ThemeMode> onThemeChanged;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTab = 0;
  String _city = 'Warszawa';
  final _locationService = LocationService();
  final _api = RuszajApi();
  List<Map<String, String>> _recentRoutes = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final preferences = await SharedPreferences.getInstance();
    final city = preferences.getString('city');
    if (mounted && city != null) setState(() => _city = city);
    await _loadRecentRoutes();
  }

  String get _recentRoutesKey => 'recent_routes_$_city';

  Future<void> _loadRecentRoutes() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getStringList(_recentRoutesKey) ?? [];
    final routes = <Map<String, String>>[];
    final keys = <String>{};
    for (final item in raw) {
      final route = Map<String, String>.from(jsonDecode(item) as Map);
      if (keys.add(_routeKey(route))) routes.add(route);
    }
    if (routes.length != raw.length || routes.length > 5) {
      await preferences.setStringList(
        _recentRoutesKey,
        routes.take(5).map(jsonEncode).toList(),
      );
    }
    if (!mounted) return;
    setState(() => _recentRoutes = routes.take(5).toList());
  }

  String _routeKey(Map<String, String> route) =>
      '${(route['fromValue'] ?? route['from'] ?? '').trim()}|'
      '${(route['toValue'] ?? route['to'] ?? '').trim()}';

  Future<void> _saveRecentRoute(
    String from,
    String to,
    String fromValue,
    String toValue,
  ) async {
    final route = {
      'from': from,
      'to': to,
      'fromValue': fromValue,
      'toValue': toValue,
    };
    final routes = [
      route,
      ..._recentRoutes.where((item) => _routeKey(item) != _routeKey(route)),
    ].take(5).toList();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
      _recentRoutesKey,
      routes.map(jsonEncode).toList(),
    );
    if (mounted) setState(() => _recentRoutes = routes);
  }

  Future<void> _openRecentRoute(Map<String, String> route) async {
    final from = route['fromValue'] ?? route['from'] ?? '';
    final to = route['toValue'] ?? route['to'] ?? '';
    if (from.isEmpty || to.isEmpty) return;
    try {
      final page = await _api.journeyPage(from: from, to: to);
      if (!mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (context) => _JourneyResults(
            page: page,
            fromName: route['from'] ?? from,
            toName: route['to'] ?? to,
            from: from,
            to: to,
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).requestFailed)),
        );
      }
    }
  }

  Future<void> _deleteRecentRoute(Map<String, String> route) async {
    final routes = _recentRoutes.where((item) => item != route).toList();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
      _recentRoutesKey,
      routes.map(jsonEncode).toList(),
    );
    if (mounted) setState(() => _recentRoutes = routes);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 140),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _Header(city: _city, onCityTap: _chooseCity),
                      const SizedBox(height: 34),
                      if (_selectedTab == 1)
                        const _NearbyScreen()
                      else ...[
                        _JourneyCard(
                          onUseLocation: _useCurrentLocation,
                          onSaved: _saveRecentRoute,
                          city: _city,
                        ),
                        const SizedBox(height: 32),
                        Text(
                          l10n.recentRoutes,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_recentRoutes.isEmpty)
                          _RecentEmpty(text: l10n.noRecentRoutes)
                        else
                          for (final route in _recentRoutes)
                            _RecentRoute(
                              from: route['from'] ?? '',
                              to: route['to'] ?? '',
                              onTap: () => _openRecentRoute(route),
                              onDelete: () => _deleteRecentRoute(route),
                            ),
                      ],
                    ]),
                  ),
                ),
              ],
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 16,
              child: Center(
                child: FloatingNav(
                  selectedIndex: _selectedTab,
                  onSelected: (index) async {
                    if (index == 2) {
                      await _showSettings();
                    } else {
                      setState(() => _selectedTab = index);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _chooseCity() async {
    final selected = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (context) => _CityPage(selectedCity: _city)),
    );
    if (selected != null && mounted) {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString('city', selected);
      setState(() => _city = selected);
      await _loadRecentRoutes();
    }
  }

  Future<void> _showSettings() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => SettingsPage(
          locale: widget.locale,
          themeMode: widget.themeMode,
          onLocaleChanged: widget.onLocaleChanged,
          onThemeChanged: widget.onThemeChanged,
        ),
      ),
    );
  }

  Future<SearchPlace?> _useCurrentLocation() async {
    final l10n = AppLocalizations.of(context);
    try {
      final position = await _locationService.currentPosition();
      return await _api.reverseGeocode(
            lat: position.latitude,
            lon: position.longitude,
          ) ??
          SearchPlace(
            id: '${position.latitude},${position.longitude}',
            name:
                '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}',
            type: 'ADDRESS',
            lat: position.latitude,
            lon: position.longitude,
          );
    } on LocationException catch (error) {
      if (!mounted) return null;
      final message = error.code == 'permission-denied-forever'
          ? l10n.locationUnavailable
          : l10n.locationPermissionNeeded;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      return null;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.locationUnavailable)));
      }
      return null;
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.city, required this.onCityTap});
  final String city;
  final VoidCallback onCityTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(
                    text: 'R',
                    style: TextStyle(color: AppColors.blue),
                  ),
                  TextSpan(
                    text: 'uszaj',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                letterSpacing: -1.5,
                height: 1,
              ),
            ),
          ),
        ),
        GestureDetector(
          onTap: onCityTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AppIcon(
                    HugeIcons.strokeRoundedBuilding03,
                    size: 18,
                    color: AppColors.blue,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    city,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 5),
                  AppIcon(
                    HugeIcons.strokeRoundedArrowDown01,
                    size: 17,
                    color: AppColors.textMuted(context),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                l10n.chooseCity,
                style: const TextStyle(fontSize: 12, color: AppColors.subtle),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _JourneyCard extends StatefulWidget {
  const _JourneyCard({
    required this.onUseLocation,
    required this.onSaved,
    required this.city,
  });
  final Future<SearchPlace?> Function() onUseLocation;
  final Future<void> Function(
    String from,
    String to,
    String fromValue,
    String toValue,
  )
  onSaved;
  final String city;

  @override
  State<_JourneyCard> createState() => _JourneyCardState();
}

class _JourneyCardState extends State<_JourneyCard> {
  final _api = RuszajApi();
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  Timer? _debounce;
  String? _fromValue;
  String? _toValue;
  List<SearchPlace> _suggestions = [];
  List<SearchPlace> _recentPlaces = [];
  List<SavedPlace> _savedPlaces = [];
  bool _searching = false;
  bool _loadingRoute = false;
  bool _editingFrom = true;
  int _searchRequestId = 0;
  bool _fieldFocused = false;
  DateTime? _routeTime;
  bool _arriveBy = false;

  String get _savedPlacesKey => 'saved_places_${widget.city}';

  @override
  void initState() {
    super.initState();
    _loadRecentPlaces();
    _loadSavedPlaces();
  }

  @override
  void didUpdateWidget(covariant _JourneyCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.city != widget.city) _loadSavedPlaces();
  }

  Future<void> _loadSavedPlaces() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getStringList(_savedPlacesKey) ?? [];
    if (!mounted) return;
    setState(() {
      _savedPlaces = raw
          .map(
            (item) =>
                SavedPlace.fromJson(jsonDecode(item) as Map<String, dynamic>),
          )
          .toList();
    });
  }

  Future<void> _savePlace(SearchPlace place) async {
    final saved = await showModalBottomSheet<SavedPlace>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SavePlaceSheet(place: place),
    );
    if (saved == null) return;
    final places = [
      saved,
      ..._savedPlaces.where((item) => item.key != saved.key),
    ].take(8).toList();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
      _savedPlacesKey,
      places.map((item) => jsonEncode(item.toJson())).toList(),
    );
    if (mounted) setState(() => _savedPlaces = places);
  }

  Future<void> _deleteSavedPlace(SavedPlace place) async {
    final places = _savedPlaces.where((item) => item.key != place.key).toList();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
      _savedPlacesKey,
      places.map((item) => jsonEncode(item.toJson())).toList(),
    );
    if (mounted) setState(() => _savedPlaces = places);
  }

  Future<void> _loadRecentPlaces() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getStringList('recent_places') ?? [];
    final places = <SearchPlace>[];
    final keys = <String>{};
    for (final item in raw) {
      final json = jsonDecode(item) as Map<String, dynamic>;
      final place = SearchPlace(
        id: json['id'] as String,
        name: json['name'] as String,
        type: json['type'] as String,
        lat: (json['lat'] as num).toDouble(),
        lon: (json['lon'] as num).toDouble(),
      );
      if (keys.add(_placeKey(place))) places.add(place);
    }
    if (places.length != raw.length || places.length > 8) {
      await _persistRecentPlaces(places);
    }
    if (!mounted) return;
    setState(() => _recentPlaces = places.take(8).toList());
  }

  String _placeKey(SearchPlace place) => place.id.isNotEmpty
      ? 'id:${place.id}'
      : 'geo:${place.lat.toStringAsFixed(5)},${place.lon.toStringAsFixed(5)}';

  Future<void> _persistRecentPlaces(List<SearchPlace> places) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
      'recent_places',
      places
          .take(8)
          .map(
            (item) => jsonEncode({
              'id': item.id,
              'name': item.name,
              'type': item.type,
              'lat': item.lat,
              'lon': item.lon,
            }),
          )
          .toList(),
    );
  }

  Future<void> _rememberPlace(SearchPlace place) async {
    final places = [
      place,
      ..._recentPlaces.where((item) => _placeKey(item) != _placeKey(place)),
    ].take(8).toList();
    await _persistRecentPlaces(places);
    if (mounted) setState(() => _recentPlaces = places);
  }

  Future<void> _deleteRecentPlace(SearchPlace place) async {
    final places = _recentPlaces
        .where((item) => _placeKey(item) != _placeKey(place))
        .toList();
    await _persistRecentPlaces(places);
    if (mounted) setState(() => _recentPlaces = places);
  }

  void _activateField(bool isFrom) {
    setState(() {
      _editingFrom = isFrom;
      _fieldFocused = true;
      _suggestions = [];
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value, bool isFrom) {
    if (isFrom) {
      _fromValue = null;
    } else {
      _toValue = null;
    }
    _debounce?.cancel();
    if (value.trim().length < 2) {
      setState(() {
        _suggestions = [];
      });
      return;
    }
    final requestId = ++_searchRequestId;
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      if (!mounted) return;
      setState(() {
        _searching = true;
      });
      try {
        final results = await _api.search(value.trim(), city: widget.city);
        if (mounted && requestId == _searchRequestId) {
          setState(() => _suggestions = results);
        }
      } catch (_) {
        if (mounted && requestId == _searchRequestId) {
          setState(() {
            _suggestions = [];
          });
        }
      } finally {
        if (mounted && requestId == _searchRequestId) {
          setState(() => _searching = false);
        }
      }
    });
  }

  void _selectPlace(SearchPlace place, bool isFrom) {
    final controller = isFrom ? _fromController : _toController;
    controller.text = place.name;
    _rememberPlace(place);
    setState(() {
      if (isFrom) {
        _fromValue = _placeValue(place);
      } else {
        _toValue = _placeValue(place);
      }
      _suggestions = [];
    });
  }

  Future<void> _fillCurrentLocation(bool isFrom) async {
    final place = await widget.onUseLocation();
    if (!mounted || place == null) return;
    _selectPlace(place, isFrom);
  }

  void _swapPlaces() {
    final fromText = _fromController.text;
    final fromValue = _fromValue;
    setState(() {
      _fromController.text = _toController.text;
      _toController.text = fromText;
      _fromValue = _toValue;
      _toValue = fromValue;
      _suggestions = [];
      _fieldFocused = false;
    });
  }

  Future<void> _pickRouteTime() async {
    final result = await showModalBottomSheet<_RouteTimeSelection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _RouteTimeSheet(
        initialTime: _routeTime ?? DateTime.now(),
        arriveBy: _arriveBy,
      ),
    );
    if (!mounted || result == null) return;
    setState(() {
      _routeTime = result.time;
      _arriveBy = result.arriveBy;
    });
  }

  String _routeTimeLabel(AppLocalizations l10n) {
    if (_routeTime == null) return l10n.now;
    final value = _routeTime!;
    return '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }

  String _placeValue(SearchPlace place) =>
      place.type == 'STOP' ? place.id : '${place.lat},${place.lon}';

  Future<void> _findRoute() async {
    final l10n = AppLocalizations.of(context);
    if ((_fromValue ?? _fromController.text).trim().isEmpty ||
        (_toValue ?? _toController.text).trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.noRoute)));
      return;
    }
    setState(() => _loadingRoute = true);
    try {
      final page = await _api.journeyPage(
        from: _fromValue ?? _fromController.text,
        to: _toValue ?? _toController.text,
        time: _routeTime,
        arriveBy: _arriveBy,
      );
      await widget.onSaved(
        _fromController.text,
        _toController.text,
        _fromValue ?? _fromController.text,
        _toValue ?? _toController.text,
      );
      if (!mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (context) => _JourneyResults(
            page: page,
            fromName: _fromController.text,
            toName: _toController.text,
            from: _fromValue ?? _fromController.text,
            to: _toValue ?? _toController.text,
            time: _routeTime,
            arriveBy: _arriveBy,
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.requestFailed)));
      }
    } finally {
      if (mounted) setState(() => _loadingRoute = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppRadii.card,
      ),
      child: Column(
        children: [
          _PlaceField(
            label: l10n.from,
            hint: l10n.whereAreYouStarting,
            color: AppColors.blue,
            trailing: HugeIcons.strokeRoundedLocation01,
            onTap: () => _fillCurrentLocation(true),
            controller: _fromController,
            onChanged: (value) => _onQueryChanged(value, true),
            onFieldTap: () => _activateField(true),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 23),
            child: Row(
              children: [
                Expanded(
                  child: Container(height: 1, color: AppColors.lineOf(context)),
                ),
                IconButton(
                  onPressed: _swapPlaces,
                  tooltip: l10n.swapPlaces,
                  visualDensity: VisualDensity.compact,
                  icon: AppIcon(
                    HugeIcons.strokeRoundedArrowUpDown,
                    size: 21,
                    color: AppColors.textMuted(context),
                  ),
                ),
                Expanded(
                  child: Container(height: 1, color: AppColors.lineOf(context)),
                ),
              ],
            ),
          ),
          _PlaceField(
            label: l10n.to,
            hint: l10n.whereAreYouGoing,
            color: AppColors.green,
            controller: _toController,
            onChanged: (value) => _onQueryChanged(value, false),
            trailing: HugeIcons.strokeRoundedLocation01,
            onTap: () => _fillCurrentLocation(false),
            onFieldTap: () => _activateField(false),
          ),
          if (_fieldFocused &&
              _suggestions.isEmpty &&
              !_searching &&
              _recentPlaces.isNotEmpty)
            _RecentPlaces(
              places: _recentPlaces,
              savedPlaces: _savedPlaces,
              onSelected: (place) => _selectPlace(place, _editingFrom),
              onDelete: _deleteRecentPlace,
              onSave: _savePlace,
              onDeleteSaved: _deleteSavedPlace,
            ),
          if (_suggestions.isNotEmpty || _searching)
            _Suggestions(
              suggestions: _suggestions,
              searching: _searching,
              onSelected: (place) => _selectPlace(place, _editingFrom),
            ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: _pickRouteTime,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.softOf(context),
                borderRadius: AppRadii.pill,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppIcon(
                    HugeIcons.strokeRoundedClock01,
                    size: 17,
                    color: AppColors.blue,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_arriveBy ? l10n.arriveBy : l10n.leaveAt}: ${_routeTimeLabel(l10n)}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 5),
                  AppIcon(
                    HugeIcons.strokeRoundedArrowDown01,
                    size: 16,
                    color: AppColors.textMuted(context),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _loadingRoute ? null : _findRoute,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.onSurface,
                foregroundColor: Theme.of(context).colorScheme.surface,
                elevation: 0,
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadii.pill,
                ),
              ),
              child: _loadingRoute
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Theme.of(context).colorScheme.surface,
                      ),
                    )
                  : Text(
                      l10n.findRoute,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceField extends StatelessWidget {
  const _PlaceField({
    required this.label,
    required this.hint,
    required this.color,
    this.trailing,
    this.onTap,
    required this.controller,
    required this.onChanged,
    this.onFieldTap,
  });
  final String label;
  final String hint;
  final Color color;
  final List<List<dynamic>>? trailing;
  final VoidCallback? onTap;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback? onFieldTap;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 13),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppColors.subtle,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 3),
            TextField(
              controller: controller,
              onChanged: onChanged,
              onTap: onFieldTap,
              decoration: InputDecoration(
                hintText: hint,
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: TextStyle(
                fontSize: 17,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
      GestureDetector(
        onTap: onTap,
        child: AppIcon(
          trailing ?? HugeIcons.strokeRoundedSearch01,
          size: 19,
          color: AppColors.subtle,
        ),
      ),
    ],
  );
}

class _RecentEmpty extends StatelessWidget {
  const _RecentEmpty({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.lineOf(context)),
        borderRadius: AppRadii.card,
      ),
      child: Row(
        children: [
          const AppIcon(
            HugeIcons.strokeRoundedClock01,
            color: AppColors.subtle,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: AppColors.textMuted(context),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentRoute extends StatelessWidget {
  const _RecentRoute({
    required this.from,
    required this.to,
    required this.onTap,
    required this.onDelete,
  });
  final String from;
  final String to;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppRadii.field,
      ),
      child: Row(
        children: [
          const AppIcon(HugeIcons.strokeRoundedRoute01, color: AppColors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  from,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  to,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.textMuted(context)),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const AppIcon(
              HugeIcons.strokeRoundedDelete02,
              size: 19,
              color: AppColors.subtle,
            ),
          ),
        ],
      ),
    ),
  );
}

class _CityPage extends StatefulWidget {
  const _CityPage({required this.selectedCity});
  final String selectedCity;

  @override
  State<_CityPage> createState() => _CityPageState();
}

class _CityPageState extends State<_CityPage> {
  static const _cities = [
    'Warszawa',
    'Kraków',
    'Łódź',
    'Wrocław',
    'Poznań',
    'Gdańsk',
    'Szczecin',
    'Bydgoszcz',
    'Lublin',
    'Białystok',
    'Katowice',
    'Gdynia',
    'Częstochowa',
    'Radom',
    'Toruń',
    'Sosnowiec',
    'Rzeszów',
    'Kielce',
    'Gliwice',
    'Olsztyn',
    'Zabrze',
    'Bielsko-Biała',
    'Bytom',
    'Zielona Góra',
    'Rybnik',
    'Opole',
    'Tychy',
    'Gorzów Wielkopolski',
    'Elbląg',
    'Płock',
    'Wałbrzych',
    'Włocławek',
    'Tarnów',
    'Chorzów',
    'Kalisz',
    'Koszalin',
    'Legnica',
    'Grudziądz',
    'Słupsk',
    'Jaworzno',
    'Jastrzębie-Zdrój',
  ];

  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const AppIcon(HugeIcons.strokeRoundedArrowLeft01, size: 24),
        ),
        title: Text(
          l10n.selectCity,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ValueListenableBuilder<TextEditingValue>(
        valueListenable: _searchController,
        builder: (context, value, child) {
          final query = value.text.trim().toLowerCase();
          final cities = _cities
              .where((city) => city.toLowerCase().contains(query))
              .toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: l10n.searchCities,
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(left: 16, right: 8),
                    child: AppIcon(HugeIcons.strokeRoundedSearch01, size: 20),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 15,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: AppRadii.field,
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              if (cities.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 30),
                  child: Center(
                    child: Text(
                      l10n.noResults,
                      style: TextStyle(color: AppColors.textMuted(context)),
                    ),
                  ),
                )
              else
                for (final city in cities)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: Material(
                      color: city == widget.selectedCity
                          ? AppColors.softOf(context)
                          : Theme.of(context).colorScheme.surface,
                      borderRadius: AppRadii.field,
                      child: InkWell(
                        borderRadius: AppRadii.field,
                        onTap: () => Navigator.pop(context, city),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          child: Row(
                            children: [
                              AppIcon(
                                HugeIcons.strokeRoundedBuilding03,
                                size: 20,
                                color: city == widget.selectedCity
                                    ? AppColors.blue
                                    : AppColors.textMuted(context),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  city,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const AppIcon(
                                HugeIcons.strokeRoundedArrowRight01,
                                size: 18,
                                color: AppColors.subtle,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }
}

class SavedPlace {
  const SavedPlace({
    required this.place,
    required this.label,
    required this.iconKey,
  });
  final SearchPlace place;
  final String label;
  final String iconKey;

  String get key => place.id.isNotEmpty
      ? place.id
      : '${place.lat.toStringAsFixed(5)},${place.lon.toStringAsFixed(5)}';

  factory SavedPlace.fromJson(Map<String, dynamic> json) => SavedPlace(
    place: SearchPlace(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
    ),
    label: json['label'] as String,
    iconKey: json['iconKey'] as String,
  );

  Map<String, dynamic> toJson() => {
    'id': place.id,
    'name': place.name,
    'type': place.type,
    'lat': place.lat,
    'lon': place.lon,
    'label': label,
    'iconKey': iconKey,
  };
}

List<List<dynamic>> savedPlaceIcon(String key) => switch (key) {
  'home' => HugeIcons.strokeRoundedHome01,
  'school' => HugeIcons.strokeRoundedSchool01,
  'work' => HugeIcons.strokeRoundedBriefcase01,
  _ => HugeIcons.strokeRoundedFavourite,
};

class _RecentPlaces extends StatelessWidget {
  const _RecentPlaces({
    required this.places,
    required this.savedPlaces,
    required this.onSelected,
    required this.onDelete,
    required this.onSave,
    required this.onDeleteSaved,
  });
  final List<SearchPlace> places;
  final List<SavedPlace> savedPlaces;
  final ValueChanged<SearchPlace> onSelected;
  final ValueChanged<SearchPlace> onDelete;
  final ValueChanged<SearchPlace> onSave;
  final ValueChanged<SavedPlace> onDeleteSaved;

  String _key(SearchPlace place) => place.id.isNotEmpty
      ? place.id
      : '${place.lat.toStringAsFixed(5)},${place.lon.toStringAsFixed(5)}';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppRadii.field,
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          if (savedPlaces.isNotEmpty) _ListLabel(text: l10n.savedPlaces),
          for (final saved in savedPlaces)
            ListTile(
              dense: true,
              leading: AppIcon(
                savedPlaceIcon(saved.iconKey),
                color: AppColors.blue,
                size: 20,
              ),
              title: Text(saved.label),
              subtitle: Text(saved.place.name),
              onTap: () => onSelected(saved.place),
              trailing: IconButton(
                onPressed: () => onDeleteSaved(saved),
                icon: const AppIcon(
                  HugeIcons.strokeRoundedDelete02,
                  size: 18,
                  color: AppColors.subtle,
                ),
              ),
            ),
          if (places.any(
            (place) => !savedPlaces.any((saved) => saved.key == _key(place)),
          ))
            _ListLabel(text: l10n.recentPlaces),
          for (final place in places)
            if (!savedPlaces.any((saved) => saved.key == _key(place)))
              ListTile(
                dense: true,
                leading: AppIcon(
                  place.type == 'STOP'
                      ? HugeIcons.strokeRoundedBus01
                      : HugeIcons.strokeRoundedLocation01,
                  color: AppColors.blue,
                  size: 20,
                ),
                title: Text(place.name),
                subtitle: Text(place.type),
                onTap: () => onSelected(place),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => onSave(place),
                      icon: const AppIcon(
                        HugeIcons.strokeRoundedBookmark01,
                        size: 18,
                        color: AppColors.blue,
                      ),
                    ),
                    IconButton(
                      onPressed: () => onDelete(place),
                      icon: const AppIcon(
                        HugeIcons.strokeRoundedDelete02,
                        size: 18,
                        color: AppColors.subtle,
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class _ListLabel extends StatelessWidget {
  const _ListLabel({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
      ),
    ),
  );
}

class _SavePlaceSheet extends StatefulWidget {
  const _SavePlaceSheet({required this.place});
  final SearchPlace place;
  @override
  State<_SavePlaceSheet> createState() => _SavePlaceSheetState();
}

class _SavePlaceSheetState extends State<_SavePlaceSheet> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.place.name,
  );
  String _iconKey = 'home';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: AppRadii.pill,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.savePlace,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: InputDecoration(
              labelText: l10n.name,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.icon,
            style: TextStyle(
              color: AppColors.textMuted(context),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final entry in {
                'home': HugeIcons.strokeRoundedHome01,
                'school': HugeIcons.strokeRoundedSchool01,
                'work': HugeIcons.strokeRoundedBriefcase01,
                'favourite': HugeIcons.strokeRoundedFavourite,
              }.entries)
                GestureDetector(
                  onTap: () => setState(() => _iconKey = entry.key),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _iconKey == entry.key
                          ? AppColors.softOf(context)
                          : Colors.transparent,
                      borderRadius: AppRadii.field,
                    ),
                    child: AppIcon(
                      entry.value,
                      color: _iconKey == entry.key
                          ? AppColors.blue
                          : AppColors.textMuted(context),
                      size: 24,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(
                context,
                SavedPlace(
                  place: widget.place,
                  label: _controller.text.trim().isEmpty
                      ? widget.place.name
                      : _controller.text.trim(),
                  iconKey: _iconKey,
                ),
              ),
              child: Text(l10n.save),
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteTimeSelection {
  const _RouteTimeSelection({required this.time, required this.arriveBy});
  final DateTime time;
  final bool arriveBy;
}

class _RouteTimeSheet extends StatefulWidget {
  const _RouteTimeSheet({required this.initialTime, required this.arriveBy});
  final DateTime initialTime;
  final bool arriveBy;

  @override
  State<_RouteTimeSheet> createState() => _RouteTimeSheetState();
}

class _RouteTimeSheetState extends State<_RouteTimeSheet> {
  late DateTime _time = widget.initialTime;
  late bool _arriveBy = widget.arriveBy;

  void _chooseDate(DateTime date) {
    setState(
      () => _time = DateTime(
        date.year,
        date.month,
        date.day,
        _time.hour,
        _time.minute,
      ),
    );
  }

  List<DateTime> _dateOptions() {
    final selected = DateUtils.dateOnly(_time);
    return List.generate(5, (index) => selected.add(Duration(days: index - 2)));
  }

  Future<void> _chooseTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_time),
    );
    if (time == null || !mounted) return;
    setState(
      () => _time = DateTime(
        _time.year,
        _time.month,
        _time.day,
        time.hour,
        time.minute,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.lineOf(context),
              borderRadius: AppRadii.pill,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _arriveBy ? l10n.arriveBy : l10n.leaveAt,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppColors.softOf(context),
                  borderRadius: AppRadii.pill,
                ),
                child: Row(
                  children: [
                    _TimeModeButton(
                      label: l10n.leaveAt,
                      selected: !_arriveBy,
                      onTap: () => setState(() => _arriveBy = false),
                    ),
                    _TimeModeButton(
                      label: l10n.arriveBy,
                      selected: _arriveBy,
                      onTap: () => setState(() => _arriveBy = true),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 92,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _dateOptions().length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final date = _dateOptions()[index];
                final selected = DateUtils.isSameDay(date, _time);
                return GestureDetector(
                  onTap: () => _chooseDate(date),
                  child: Container(
                    width: 76,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.blue
                          : Theme.of(context).colorScheme.surface,
                      borderRadius: AppRadii.field,
                      border: Border.all(
                        color: selected
                            ? AppColors.blue
                            : AppColors.lineOf(context),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat.MMM(
                            Localizations.localeOf(context).toString(),
                          ).format(date),
                          style: TextStyle(
                            color: selected
                                ? Colors.white
                                : AppColors.textMuted(context),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${date.day}',
                          style: TextStyle(
                            color: selected
                                ? Colors.white
                                : Theme.of(context).colorScheme.onSurface,
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _chooseTime,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.softOf(context),
                borderRadius: AppRadii.field,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const AppIcon(
                    HugeIcons.strokeRoundedClock01,
                    color: AppColors.blue,
                    size: 21,
                  ),
                  const SizedBox(width: 9),
                  Text(
                    '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(
                context,
                _RouteTimeSelection(time: _time, arriveBy: _arriveBy),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blue,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadii.field,
                ),
              ),
              child: Text(l10n.saveTime),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeModeButton extends StatelessWidget {
  const _TimeModeButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: selected
            ? Theme.of(context).colorScheme.surface
            : Colors.transparent,
        borderRadius: AppRadii.pill,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: selected
              ? Theme.of(context).colorScheme.onSurface
              : AppColors.textMuted(context),
        ),
      ),
    ),
  );
}

class _Suggestions extends StatelessWidget {
  const _Suggestions({
    required this.suggestions,
    required this.searching,
    required this.onSelected,
  });
  final List<SearchPlace> suggestions;
  final bool searching;
  final ValueChanged<SearchPlace> onSelected;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 10),
    decoration: BoxDecoration(
      color: AppColors.softOf(context),
      borderRadius: AppRadii.field,
    ),
    child: searching
        ? Padding(
            padding: EdgeInsets.all(14),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        : Column(
            children: [
              for (final place in suggestions)
                ListTile(
                  dense: true,
                  title: Text(place.name),
                  subtitle: Text(place.type),
                  onTap: () => onSelected(place),
                ),
            ],
          ),
  );
}

class _JourneyResults extends StatefulWidget {
  const _JourneyResults({
    required this.page,
    required this.fromName,
    required this.toName,
    required this.from,
    required this.to,
    this.time,
    this.arriveBy = false,
  });
  final JourneyPage page;
  final String fromName;
  final String toName;
  final String from;
  final String to;
  final DateTime? time;
  final bool arriveBy;

  @override
  State<_JourneyResults> createState() => _JourneyResultsState();
}

class _JourneyResultsState extends State<_JourneyResults> {
  late JourneyPage _page = widget.page;
  bool _loading = false;

  Future<void> _loadPage(String cursor, {required bool append}) async {
    setState(() => _loading = true);
    try {
      final page = await RuszajApi().journeyPage(
        from: widget.from,
        to: widget.to,
        time: widget.time,
        arriveBy: widget.arriveBy,
        pageCursor: cursor,
      );
      if (!mounted) return;
      final combined = append
          ? [..._page.journeys, ...page.journeys]
          : [...page.journeys, ..._page.journeys];
      final journeys = <JourneyOption>[];
      final ids = <String>{};
      for (final journey in combined) {
        final key = journey.id.isEmpty
            ? '${journey.departure.toIso8601String()}|${journey.arrival.toIso8601String()}'
            : journey.id;
        if (ids.add(key)) journeys.add(journey);
      }
      setState(
        () => _page = JourneyPage(
          journeys: journeys,
          previousPageCursor: append
              ? _page.previousPageCursor ?? page.previousPageCursor
              : page.previousPageCursor,
          nextPageCursor: append
              ? page.nextPageCursor
              : _page.nextPageCursor ?? page.nextPageCursor,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final journeys = _page.journeys;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const AppIcon(
                      HugeIcons.strokeRoundedArrowLeft01,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.routeOptions,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${widget.fromName}  →  ${widget.toName}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: AppColors.textMuted(context)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: journeys.isEmpty
                  ? Center(
                      child: Text(
                        l10n.noUpcomingJourneys,
                        style: TextStyle(color: AppColors.textMuted(context)),
                      ),
                    )
                  : NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        if (notification.metrics.extentAfter < 240 &&
                            _page.nextPageCursor != null &&
                            !_loading) {
                          unawaited(
                            _loadPage(_page.nextPageCursor!, append: true),
                          );
                        }
                        return false;
                      },
                      child: RefreshIndicator(
                        onRefresh: _page.previousPageCursor == null
                            ? () async {}
                            : () => _loadPage(
                                _page.previousPageCursor!,
                                append: false,
                              ),
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                          itemCount:
                              journeys.length +
                              (_loading && _page.nextPageCursor != null
                                  ? 1
                                  : 0),
                          itemBuilder: (context, index) {
                            if (index >= journeys.length) {
                              return const Padding(
                                padding: EdgeInsets.all(18),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            }
                            final journey = journeys[index];
                            final isPast = journey.departure.isBefore(
                              DateTime.now(),
                            );
                            final textColor = isPast
                                ? AppColors.textMuted(context)
                                : Theme.of(context).colorScheme.onSurface;
                            return GestureDetector(
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => _JourneyDetail(
                                    journey: journey,
                                    fromName: widget.fromName,
                                    toName: widget.toName,
                                  ),
                                ),
                              ),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isPast
                                      ? Theme.of(context).colorScheme.surface
                                            .withValues(alpha: 0.55)
                                      : Theme.of(context).colorScheme.surface,
                                  borderRadius: AppRadii.field,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          _departureLabel(
                                            journey.departure,
                                            l10n,
                                          ),
                                          style: TextStyle(
                                            color: textColor,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 18,
                                          ),
                                        ),
                                        const Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 10,
                                          ),
                                          child: AppIcon(
                                            HugeIcons.strokeRoundedArrowRight01,
                                            size: 17,
                                            color: AppColors.subtle,
                                          ),
                                        ),
                                        Text(
                                          _time(journey.arrival),
                                          style: TextStyle(
                                            color: textColor,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 18,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          '${(journey.durationSeconds / 60).round()} ${l10n.minutes}',
                                          style: TextStyle(
                                            color: isPast
                                                ? AppColors.textMuted(context)
                                                : AppColors.textMuted(context),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 7,
                                      runSpacing: 7,
                                      children: [
                                        for (final leg in journey.legs)
                                          _ModeChip(leg: leg, l10n: l10n),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      journey.transfers == 0
                                          ? l10n.transit
                                          : '${journey.transfers} ${journey.transfers == 1 ? l10n.transfer : l10n.transfers}',
                                      style: TextStyle(
                                        color: isPast
                                            ? AppColors.textMuted(context)
                                            : AppColors.textMuted(context),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _time(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

  String _departureLabel(DateTime departure, AppLocalizations l10n) {
    final difference = departure.difference(DateTime.now());
    if (difference.isNegative) {
      final minutes = difference.inMinutes.abs();
      if (minutes < 5) return '-${minutes == 0 ? 1 : minutes} ${l10n.minutes}';
      return l10n.departed;
    }
    final minutes = difference.inMinutes;
    if (minutes < 60) return l10n.inMinutes(minutes);
    return _time(departure);
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({required this.leg, required this.l10n});
  final JourneyLeg leg;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final isWalk = leg.mode == 'WALK';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: isWalk
            ? AppColors.softOf(context)
            : Theme.of(context).colorScheme.onSurface,
        borderRadius: AppRadii.pill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(
            isWalk
                ? HugeIcons.strokeRoundedWalking
                : HugeIcons.strokeRoundedBus01,
            size: 16,
            color: isWalk
                ? AppColors.blue
                : Theme.of(context).colorScheme.surface,
          ),
          const SizedBox(width: 5),
          Text(
            isWalk ? l10n.walking : (leg.routeName ?? leg.mode),
            style: TextStyle(
              color: isWalk
                  ? AppColors.blue
                  : Theme.of(context).colorScheme.surface,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _JourneyDetail extends StatelessWidget {
  const _JourneyDetail({
    required this.journey,
    required this.fromName,
    required this.toName,
  });
  final JourneyOption journey;
  final String fromName;
  final String toName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: PageView(
          children: [
            CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const AppIcon(
                            HugeIcons.strokeRoundedArrowLeft01,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fromName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                toName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppColors.textMuted(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _time(journey.departure),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: AppIcon(
                              HugeIcons.strokeRoundedArrowRight01,
                              color: AppColors.subtle,
                            ),
                          ),
                          Text(
                            _time(journey.arrival),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${(journey.durationSeconds / 60).round()} ${l10n.minutes}',
                            style: TextStyle(
                              color: AppColors.textMuted(context),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      for (final leg in journey.legs)
                        _DetailLeg(leg: leg, l10n: l10n),
                    ]),
                  ),
                ),
              ],
            ),
            JourneyRouteMap(
              journey: journey,
              fromName: fromName,
              toName: toName,
            ),
          ],
        ),
      ),
    );
  }

  String _time(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}

class _DetailLeg extends StatefulWidget {
  const _DetailLeg({required this.leg, required this.l10n});
  final JourneyLeg leg;
  final AppLocalizations l10n;

  @override
  State<_DetailLeg> createState() => _DetailLegState();
}

class _DetailLegState extends State<_DetailLeg> {
  bool _stopsExpanded = false;

  JourneyLeg get leg => widget.leg;
  AppLocalizations get l10n => widget.l10n;

  @override
  Widget build(BuildContext context) {
    final isWalk = leg.mode == 'WALK';
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIcon(
            isWalk
                ? HugeIcons.strokeRoundedWalking
                : HugeIcons.strokeRoundedBus01,
            color: isWalk ? AppColors.blue : AppColors.green,
            size: 25,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isWalk
                      ? l10n.walking
                      : '${leg.routeName ?? leg.mode}${leg.headsign == null ? '' : ' → ${leg.headsign}'}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${_time(leg.departure)}  →  ${_time(leg.arrival)}',
                  style: TextStyle(color: AppColors.textMuted(context)),
                ),
                if (leg.fromName != null || leg.toName != null) ...[
                  const SizedBox(height: 7),
                  Text(
                    '${leg.fromName ?? ''}  →  ${leg.toName ?? ''}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
                if (!isWalk && leg.intermediateStops.isNotEmpty) ...[
                  const SizedBox(height: 9),
                  _StopsDropdown(
                    expanded: _stopsExpanded,
                    stops: leg.intermediateStops,
                    onToggle: () =>
                        setState(() => _stopsExpanded = !_stopsExpanded),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _time(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}

class _StopsDropdown extends StatelessWidget {
  const _StopsDropdown({
    required this.expanded,
    required this.stops,
    required this.onToggle,
  });
  final bool expanded;
  final List<IntermediateStop> stops;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.softOf(context),
        borderRadius: AppRadii.field,
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: AppRadii.field,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  const AppIcon(
                    HugeIcons.strokeRoundedBus01,
                    size: 16,
                    color: AppColors.blue,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${stops.length} ${stops.length == 1 ? l10n.stop : l10n.stops}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  AppIcon(
                    expanded
                        ? HugeIcons.strokeRoundedArrowUp01
                        : HugeIcons.strokeRoundedArrowDown01,
                    size: 16,
                    color: AppColors.textMuted(context),
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.lineOf(context)),
                ),
              ),
              child: Column(
                children: [
                  for (var index = 0; index < stops.length; index++) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 24),
                          Expanded(
                            child: Text(
                              stops[index].name,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          if (stops[index].arrival != null)
                            Text(
                              _time(stops[index].arrival!),
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textMuted(context),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (index != stops.length - 1)
                      Padding(
                        padding: EdgeInsets.only(left: 36),
                        child: Divider(
                          height: 1,
                          thickness: 1,
                          color: AppColors.lineOf(context),
                        ),
                      ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _time(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}

class _NearbyScreen extends StatefulWidget {
  const _NearbyScreen();

  @override
  State<_NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends State<_NearbyScreen> {
  final _api = RuszajApi();
  final _location = LocationService();
  late Future<List<NearbyStop>> _stops;

  @override
  void initState() {
    super.initState();
    _stops = _load();
  }

  Future<List<NearbyStop>> _load() async {
    final position = await _location.currentPosition();
    return _api.nearbyStops(lat: position.latitude, lon: position.longitude);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FutureBuilder<List<NearbyStop>>(
      future: _stops,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.lineOf(context)),
              borderRadius: AppRadii.card,
            ),
            child: Text(
              l10n.locationUnavailable,
              style: TextStyle(color: AppColors.textMuted(context)),
            ),
          );
        }
        final stops = snapshot.data ?? [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.nearbyTitle,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            for (final stop in stops)
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => WalkToStopPage(stop: stop),
                  ),
                ),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: AppRadii.field,
                  ),
                  child: Row(
                    children: [
                      const AppIcon(
                        HugeIcons.strokeRoundedBus01,
                        color: AppColors.blue,
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Text(
                          stop.name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text(
                        '${stop.distanceMeters} m',
                        style: TextStyle(
                          color: AppColors.textMuted(context),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
