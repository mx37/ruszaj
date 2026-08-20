part of '../../main.dart';

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
