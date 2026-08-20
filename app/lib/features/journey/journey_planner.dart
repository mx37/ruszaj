part of '../../main.dart';

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
  final _fromFocusNode = FocusNode();
  final _toFocusNode = FocusNode();
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
    _fromFocusNode.addListener(() => _onFieldFocusChange(_fromFocusNode));
    _toFocusNode.addListener(() => _onFieldFocusChange(_toFocusNode));
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

  void _onFieldFocusChange(FocusNode node) {
    if (!node.hasFocus && !_fromFocusNode.hasFocus && !_toFocusNode.hasFocus) {
      setState(() {
        _fieldFocused = false;
        _suggestions = [];
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _fromController.dispose();
    _toController.dispose();
    _fromFocusNode.dispose();
    _toFocusNode.dispose();
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
            focusNode: _fromFocusNode,
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
            focusNode: _toFocusNode,
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

class _PlaceField extends StatefulWidget {
  const _PlaceField({
    required this.label,
    required this.hint,
    required this.color,
    this.trailing,
    this.onTap,
    required this.controller,
    required this.onChanged,
    this.focusNode,
    this.onFieldTap,
  });
  final String label;
  final String hint;
  final Color color;
  final List<List<dynamic>>? trailing;
  final VoidCallback? onTap;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final FocusNode? focusNode;
  final VoidCallback? onFieldTap;

  @override
  State<_PlaceField> createState() => _PlaceFieldState();
}

class _PlaceFieldState extends State<_PlaceField> {
  late bool _hasText = widget.controller.text.isNotEmpty;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(covariant _PlaceField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTextChanged);
      widget.controller.addListener(_onTextChanged);
      _sync();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() => _sync();

  void _sync() {
    final hasText = widget.controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  void _clear() {
    widget.controller.clear();
    widget.onChanged('');
  }

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 13),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.label.toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppColors.subtle,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 3),
            TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              onChanged: widget.onChanged,
              onTap: widget.onFieldTap,
              decoration: InputDecoration(
                hintText: widget.hint,
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
      if (_hasText)
        GestureDetector(
          onTap: _clear,
          child: AppIcon(
            HugeIcons.strokeRoundedCancel01,
            size: 20,
            color: AppColors.textMuted(context),
          ),
        )
      else
        GestureDetector(
          onTap: widget.onTap,
          child: AppIcon(
            widget.trailing ?? HugeIcons.strokeRoundedSearch01,
            size: 19,
            color: AppColors.subtle,
          ),
        ),
    ],
  );
}
