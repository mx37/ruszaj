import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'l10n/generated/app_localizations.dart';
import 'location/location_service.dart';
import 'theme/app_theme.dart';
import 'widgets/app_icon.dart';
import 'widgets/floating_nav.dart';
import 'package:hugeicons/hugeicons.dart';
import 'data/ruszaj_api.dart';

void main() => runApp(const RuszajApp());

class RuszajApp extends StatefulWidget {
  const RuszajApp({super.key});

  @override
  State<RuszajApp> createState() => _RuszajAppState();
}

class _RuszajAppState extends State<RuszajApp> {
  Locale? _locale;

  @override
  void initState() {
    super.initState();
    _loadLocale();
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
      home: HomeScreen(onLocaleChanged: _setLocale),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onLocaleChanged});

  final ValueChanged<Locale> onLocaleChanged;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTab = 0;
  String _city = 'Warszawa';
  final _locationService = LocationService();

  @override
  void initState() {
    super.initState();
    _loadCity();
  }

  Future<void> _loadCity() async {
    final preferences = await SharedPreferences.getInstance();
    final city = preferences.getString('city');
    if (city != null && mounted) setState(() => _city = city);
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
                        Text(
                          l10n.appTagline,
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppColors.muted,
                          ),
                        ),
                        const SizedBox(height: 18),
                        _JourneyCard(onUseLocation: _useCurrentLocation),
                        const SizedBox(height: 32),
                        Text(
                          l10n.recentRoutes,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _RecentEmpty(text: l10n.noRecentRoutes),
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
    final l10n = AppLocalizations.of(context);
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _CitySheet(title: l10n.selectCity),
    );
    if (selected != null && mounted) {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString('city', selected);
      setState(() => _city = selected);
    }
  }

  Future<void> _showSettings() async {
    final l10n = AppLocalizations.of(context);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _SettingsSheet(l10n: l10n, onLocaleChanged: widget.onLocaleChanged),
    );
  }

  Future<void> _useCurrentLocation() async {
    final l10n = AppLocalizations.of(context);
    try {
      final position = await _locationService.currentPosition();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}',
            ),
          ),
        );
      }
    } on LocationException catch (error) {
      if (!mounted) return;
      final message = error.code == 'permission-denied-forever'
          ? l10n.locationUnavailable
          : l10n.locationPermissionNeeded;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.locationUnavailable)));
      }
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
    return Column(
      children: [
        const Text(
          'Ruszaj',
          style: TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: onCityTap,
          child: Row(
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
              const AppIcon(
                HugeIcons.strokeRoundedArrowDown01,
                size: 17,
                color: AppColors.muted,
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.chooseCity,
          style: const TextStyle(fontSize: 12, color: AppColors.subtle),
        ),
      ],
    );
  }
}

class _JourneyCard extends StatefulWidget {
  const _JourneyCard({required this.onUseLocation});
  final VoidCallback onUseLocation;

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
  bool _searching = false;
  bool _loadingRoute = false;
  bool _editingFrom = true;

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
      setState(() => _suggestions = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      setState(() => _searching = true);
      try {
        final results = await _api.search(value.trim());
        if (mounted) setState(() => _suggestions = results);
      } catch (_) {
        if (mounted) setState(() => _suggestions = []);
      } finally {
        if (mounted) setState(() => _searching = false);
      }
    });
  }

  void _selectPlace(SearchPlace place, bool isFrom) {
    final controller = isFrom ? _fromController : _toController;
    controller.text = place.name;
    setState(() {
      if (isFrom) {
        _fromValue = place.id.isNotEmpty
            ? place.id
            : '${place.lat},${place.lon}';
      } else {
        _toValue = place.id.isNotEmpty ? place.id : '${place.lat},${place.lon}';
      }
      _suggestions = [];
    });
  }

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
      final journeys = await _api.journeys(
        from: _fromValue ?? _fromController.text,
        to: _toValue ?? _toController.text,
      );
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) => _JourneyResults(journeys: journeys),
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
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.card,
      ),
      child: Column(
        children: [
          _PlaceField(
            label: l10n.from,
            hint: l10n.whereAreYouStarting,
            color: AppColors.blue,
            trailing: HugeIcons.strokeRoundedLocation01,
            onTap: widget.onUseLocation,
            controller: _fromController,
            onChanged: (value) => _onQueryChanged(value, true),
            onFieldTap: () => setState(() => _editingFrom = true),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 18),
            child: Row(
              children: [
                Expanded(child: Container(height: 1, color: AppColors.line)),
                const SizedBox(width: 10),
                const AppIcon(
                  HugeIcons.strokeRoundedArrowUpDown,
                  size: 19,
                  color: AppColors.muted,
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
            onFieldTap: () => setState(() => _editingFrom = false),
          ),
          if (_suggestions.isNotEmpty || _searching)
            _Suggestions(
              suggestions: _suggestions,
              searching: _searching,
              onSelected: (place) => _selectPlace(place, _editingFrom),
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _loadingRoute ? null : _findRoute,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.ink,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadii.pill,
                ),
              ),
              child: _loadingRoute
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
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
              style: const TextStyle(fontSize: 17, color: AppColors.ink),
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
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      border: Border.all(color: AppColors.line),
      borderRadius: AppRadii.card,
    ),
    child: Row(
      children: [
        const AppIcon(HugeIcons.strokeRoundedClock01, color: AppColors.subtle),
        const SizedBox(width: 13),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: AppColors.muted, height: 1.4),
          ),
        ),
      ],
    ),
  );
}

class _CitySheet extends StatelessWidget {
  const _CitySheet({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
    decoration: const BoxDecoration(
      color: AppColors.canvas,
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.line,
            borderRadius: AppRadii.pill,
          ),
        ),
        const SizedBox(height: 22),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 14),
        for (final city in [
          'Warszawa',
          'Kraków',
          'Gdańsk',
          'Wrocław',
          'Poznań',
        ])
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(city),
            trailing: const AppIcon(
              HugeIcons.strokeRoundedArrowRight01,
              size: 18,
              color: AppColors.subtle,
            ),
            onTap: () => Navigator.pop(context, city),
          ),
      ],
    ),
  );
}

class _SettingsSheet extends StatelessWidget {
  const _SettingsSheet({required this.l10n, required this.onLocaleChanged});
  final AppLocalizations l10n;
  final ValueChanged<Locale> onLocaleChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
    decoration: const BoxDecoration(
      color: AppColors.canvas,
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
              color: AppColors.line,
              borderRadius: AppRadii.pill,
            ),
          ),
        ),
        const SizedBox(height: 22),
        Text(
          l10n.settings,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 20),
        Text(
          l10n.language,
          style: const TextStyle(
            color: AppColors.muted,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        _LanguageOption(
          label: l10n.english,
          locale: const Locale('en'),
          onChanged: onLocaleChanged,
        ),
        _LanguageOption(
          label: l10n.polish,
          locale: const Locale('pl'),
          onChanged: onLocaleChanged,
        ),
      ],
    ),
  );
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.label,
    required this.locale,
    required this.onChanged,
  });
  final String label;
  final Locale locale;
  final ValueChanged<Locale> onChanged;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(label),
    trailing: const AppIcon(
      HugeIcons.strokeRoundedArrowRight01,
      size: 18,
      color: AppColors.subtle,
    ),
    onTap: () {
      onChanged(locale);
      Navigator.pop(context);
    },
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
      color: AppColors.blueSoft,
      borderRadius: AppRadii.field,
    ),
    child: searching
        ? const Padding(
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

class _JourneyResults extends StatelessWidget {
  const _JourneyResults({required this.journeys});
  final List<JourneyOption> journeys;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
      decoration: const BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                color: AppColors.line,
                borderRadius: AppRadii.pill,
              ),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            l10n.routeOptions,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          if (journeys.isEmpty)
            Text(l10n.noRoute, style: const TextStyle(color: AppColors.muted)),
          for (final journey in journeys.take(5))
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: AppRadii.field,
              ),
              child: Row(
                children: [
                  Text(
                    _time(journey.departure),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: AppIcon(
                      HugeIcons.strokeRoundedArrowRight01,
                      size: 17,
                      color: AppColors.subtle,
                    ),
                  ),
                  Text(
                    _time(journey.arrival),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${journey.transfers}',
                    style: const TextStyle(color: AppColors.muted),
                  ),
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
              border: Border.all(color: AppColors.line),
              borderRadius: AppRadii.card,
            ),
            child: Text(
              l10n.locationUnavailable,
              style: const TextStyle(color: AppColors.muted),
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
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
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
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
