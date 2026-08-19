part of '../../main.dart';

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
