part of '../../main.dart';

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
