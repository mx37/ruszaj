import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:latlong2/latlong.dart';

import '../data/ruszaj_api.dart';
import '../l10n/generated/app_localizations.dart';
import '../location/location_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icon.dart';

class WalkToStopPage extends StatefulWidget {
  const WalkToStopPage({super.key, required this.stop});

  final NearbyStop stop;

  @override
  State<WalkToStopPage> createState() => _WalkToStopPageState();
}

class _WalkToStopPageState extends State<WalkToStopPage> {
  final _api = RuszajApi();
  late Future<_StopPageData> _data;

  @override
  void initState() {
    super.initState();
    _data = _load();
  }

  Future<_StopPageData> _load() async {
    final results = await Future.wait<dynamic>([
      _api.stop(widget.stop.id),
      _api.departures(widget.stop.id),
    ]);
    return _StopPageData(
      stop: results[0] as StopDetails,
      departures: results[1] as DeparturesPage,
    );
  }

  Future<void> _refresh() async {
    final next = _load();
    setState(() => _data = next);
    await next;
  }

  void _openWalkingMap() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _WalkingMapPage(stop: widget.stop),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: FutureBuilder<_StopPageData>(
          future: _data,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Column(
                children: [
                  _StopHeader(name: widget.stop.name),
                  const Expanded(
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ],
              );
            }

            if (snapshot.hasError || snapshot.data == null) {
              return Column(
                children: [
                  _StopHeader(name: widget.stop.name),
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              l10n.requestFailed,
                              style: TextStyle(
                                color: AppColors.textMuted(context),
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextButton(
                              onPressed: _refresh,
                              child: Text(l10n.refresh),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }

            final data = snapshot.data!;
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 112),
                children: [
                  _StopHeader(name: data.stop.name),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: _StopSummary(stop: data.stop),
                  ),
                  const SizedBox(height: 26),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.noUpcomingJourneys.replaceFirst(
                              RegExp(r'^No |^Brak '),
                              '',
                            ),
                            style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _refresh,
                          tooltip: l10n.refresh,
                          icon: const AppIcon(
                            HugeIcons.strokeRoundedRefresh,
                            size: 20,
                            color: AppColors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (data.departures.departures.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _EmptyDepartures(text: l10n.noUpcomingJourneys),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          for (final departure in data.departures.departures)
                            _DepartureCard(departure: departure),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _openWalkingMap,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.onSurface,
                foregroundColor: Theme.of(context).colorScheme.surface,
                elevation: 0,
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadii.pill,
                ),
              ),
              icon: const AppIcon(
                HugeIcons.strokeRoundedWalking,
                size: 20,
              ),
              label: Text(
                l10n.walkTo,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StopHeader extends StatelessWidget {
  const _StopHeader({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
    child: Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const AppIcon(HugeIcons.strokeRoundedArrowLeft01, size: 26),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    ),
  );
}

class _StopSummary extends StatelessWidget {
  const _StopSummary({required this.stop});

  final StopDetails stop;

  @override
  Widget build(BuildContext context) {
    final routes = stop.routes
        .where((route) => route.shortName.trim().isNotEmpty)
        .toList();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppRadii.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AppIcon(
                HugeIcons.strokeRoundedBus01,
                color: AppColors.blue,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  stop.name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (stop.stopCode != null && stop.stopCode!.isNotEmpty)
                Text(
                  stop.stopCode!,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          if (routes.isNotEmpty) ...[
            const SizedBox(height: 15),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (final route in routes.take(12))
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.softOf(context),
                      borderRadius: AppRadii.pill,
                    ),
                    child: Text(
                      route.shortName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _DepartureCard extends StatelessWidget {
  const _DepartureCard({required this.departure});

  final StopDeparture departure;

  @override
  Widget build(BuildContext context) {
    final actual = departure.departure ?? departure.scheduledDeparture;
    final scheduled = departure.scheduledDeparture;
    final delayMinutes = actual == null || scheduled == null
        ? 0
        : actual.difference(scheduled).inMinutes;
    final cancelled = departure.isCancelled;
    final route = departure.routeShortName.trim().isNotEmpty
        ? departure.routeShortName
        : (departure.displayName.trim().isNotEmpty
              ? departure.displayName
              : departure.mode);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppRadii.field,
        border: Border.all(color: AppColors.lineOf(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            constraints: const BoxConstraints(minWidth: 44),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
            decoration: BoxDecoration(
              color: cancelled
                  ? AppColors.softOf(context)
                  : Theme.of(context).colorScheme.onSurface,
              borderRadius: AppRadii.pill,
            ),
            child: Text(
              route,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: cancelled
                    ? AppColors.textMuted(context)
                    : Theme.of(context).colorScheme.surface,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  departure.headsign.trim().isEmpty
                      ? departure.routeLongName
                      : departure.headsign,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    decoration: cancelled ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 5,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (departure.realTime && !cancelled)
                      _StatusPill(
                        text: _localized(context, 'Live', 'Na żywo'),
                        icon: HugeIcons.strokeRoundedSignal,
                      ),
                    if (cancelled)
                      _StatusPill(
                        text: _localized(context, 'Cancelled', 'Anulowano'),
                        icon: HugeIcons.strokeRoundedCancel01,
                      ),
                    if (delayMinutes > 0 && !cancelled)
                      Text(
                        '+$delayMinutes min',
                        style: const TextStyle(
                          color: AppColors.blue,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    if (departure.track != null && departure.track!.isNotEmpty)
                      Text(
                        '${_localized(context, 'Platform', 'Peron')} ${departure.track}',
                        style: TextStyle(
                          color: AppColors.textMuted(context),
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                actual == null ? '--:--' : _time(actual),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  decoration: cancelled ? TextDecoration.lineThrough : null,
                ),
              ),
              if (scheduled != null &&
                  actual != null &&
                  scheduled.difference(actual).inMinutes != 0)
                Text(
                  _time(scheduled),
                  style: TextStyle(
                    color: AppColors.textMuted(context),
                    fontSize: 12,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.text, required this.icon});

  final String text;
  final List<List<dynamic>> icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: AppColors.softOf(context),
      borderRadius: AppRadii.pill,
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIcon(icon, size: 13, color: AppColors.blue),
        const SizedBox(width: 5),
        Text(
          text,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );
}

class _EmptyDepartures extends StatelessWidget {
  const _EmptyDepartures({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: AppRadii.field,
    ),
    child: Text(
      text,
      style: TextStyle(color: AppColors.textMuted(context)),
    ),
  );
}

class _StopPageData {
  const _StopPageData({required this.stop, required this.departures});

  final StopDetails stop;
  final DeparturesPage departures;
}

class _WalkingMapPage extends StatefulWidget {
  const _WalkingMapPage({required this.stop});

  final NearbyStop stop;

  @override
  State<_WalkingMapPage> createState() => _WalkingMapPageState();
}

class _WalkingMapPageState extends State<_WalkingMapPage> {
  final _api = RuszajApi();
  final _location = LocationService();
  late final Future<_WalkingRoute> _route;

  @override
  void initState() {
    super.initState();
    _route = _loadRoute();
  }

  Future<_WalkingRoute> _loadRoute() async {
    final position = await _location.currentPosition();
    final journeys = await _api.journeys(
      from: '${position.latitude},${position.longitude}',
      to: widget.stop.id,
      walkingOnly: true,
    );
    return _WalkingRoute(
      position: LatLng(position.latitude, position.longitude),
      journey: journeys.isEmpty ? null : journeys.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: FutureBuilder<_WalkingRoute>(
          future: _route,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Column(
                children: [
                  _MapHeader(stop: widget.stop, title: l10n.mapLoading),
                  const Expanded(
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ],
              );
            }
            if (snapshot.hasError || snapshot.data == null) {
              return Column(
                children: [
                  _MapHeader(
                    stop: widget.stop,
                    title: l10n.mapRouteUnavailable,
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        l10n.mapRouteUnavailable,
                        style: TextStyle(color: AppColors.textMuted(context)),
                      ),
                    ),
                  ),
                ],
              );
            }
            return _WalkingMapContent(
              route: snapshot.data!,
              stop: widget.stop,
              l10n: l10n,
            );
          },
        ),
      ),
    );
  }
}

class _WalkingMapContent extends StatelessWidget {
  const _WalkingMapContent({
    required this.route,
    required this.stop,
    required this.l10n,
  });

  final _WalkingRoute route;
  final NearbyStop stop;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final stopPoint = LatLng(stop.lat, stop.lon);
    final points =
        route.journey?.legs
            .expand(
              (leg) => decodePolyline(
                leg.geometry ?? '',
                leg.geometryPrecision ?? 6,
              ),
            )
            .toList() ??
        [];
    final mapPoints = points.isEmpty ? [route.position, stopPoint] : points;
    final walkingLeg = route.journey?.legs.firstWhere(
      (leg) => leg.mode == 'WALK',
      orElse: () => route.journey!.legs.first,
    );

    return Column(
      children: [
        _MapHeader(stop: stop, title: l10n.walkTo),
        Expanded(
          child: FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(
                (route.position.latitude + stop.lat) / 2,
                (route.position.longitude + stop.lon) / 2,
              ),
              initialZoom: 14.8,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'dev.ruszaj.ruszaj',
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: mapPoints,
                    color: AppColors.blue,
                    strokeWidth: 5,
                    pattern: const StrokePattern.solid(),
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: route.position,
                    width: 36,
                    height: 36,
                    child: const _MapMarker(
                      icon: HugeIcons.strokeRoundedLocation01,
                      color: AppColors.blue,
                    ),
                  ),
                  Marker(
                    point: stopPoint,
                    width: 36,
                    height: 36,
                    child: const _MapMarker(
                      icon: HugeIcons.strokeRoundedBus01,
                      color: AppColors.green,
                    ),
                  ),
                ],
              ),
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('OpenStreetMap contributors'),
                ],
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Row(
            children: [
              const AppIcon(
                HugeIcons.strokeRoundedWalking,
                color: AppColors.blue,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stop.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    if (walkingLeg != null)
                      Text(
                        '${walkingLeg.arrival.difference(walkingLeg.departure).inMinutes.ceil()} ${l10n.minutes}',
                        style: TextStyle(color: AppColors.textMuted(context)),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class JourneyRouteMap extends StatefulWidget {
  const JourneyRouteMap({
    super.key,
    required this.journey,
    required this.fromName,
    required this.toName,
  });

  final JourneyOption journey;
  final String fromName;
  final String toName;

  @override
  State<JourneyRouteMap> createState() => _JourneyRouteMapState();
}

class _JourneyRouteMapState extends State<JourneyRouteMap> {
  final _location = LocationService();
  StreamSubscription<Position>? _subscription;
  LatLng? _current;

  @override
  void initState() {
    super.initState();
    _startLocationTracking();
  }

  Future<void> _startLocationTracking() async {
    try {
      final position = await _location.currentPosition();
      if (!mounted) return;
      setState(() => _current = LatLng(position.latitude, position.longitude));
      _subscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 5,
        ),
      ).listen((position) {
        if (mounted) {
          setState(
            () => _current = LatLng(position.latitude, position.longitude),
          );
        }
      });
    } catch (_) {
      // The route remains usable when location permission is unavailable.
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final legs = widget.journey.legs;
    final polylines = <Polyline>[];
    final allPoints = <LatLng>[];

    for (final leg in legs) {
      final points = decodePolyline(
        leg.geometry ?? '',
        leg.geometryPrecision ?? 6,
      );
      if (points.isEmpty) {
        if (leg.fromLat != null &&
            leg.fromLon != null &&
            leg.toLat != null &&
            leg.toLon != null) {
          final fallback = [
            LatLng(leg.fromLat!, leg.fromLon!),
            LatLng(leg.toLat!, leg.toLon!),
          ];
          polylines.add(
            Polyline(
              points: fallback,
              color: leg.mode == 'WALK' ? AppColors.blue : AppColors.ink,
              strokeWidth: 5,
            ),
          );
          allPoints.addAll(fallback);
        }
      } else {
        polylines.add(
          Polyline(
            points: points,
            color: leg.mode == 'WALK' ? AppColors.blue : AppColors.ink,
            strokeWidth: 5,
          ),
        );
        allPoints.addAll(points);
      }
    }

    final origin =
        legs.isNotEmpty &&
            legs.first.fromLat != null &&
            legs.first.fromLon != null
        ? LatLng(legs.first.fromLat!, legs.first.fromLon!)
        : (allPoints.isNotEmpty
              ? allPoints.first
              : const LatLng(52.2297, 21.0122));
    final destination =
        legs.isNotEmpty && legs.last.toLat != null && legs.last.toLon != null
        ? LatLng(legs.last.toLat!, legs.last.toLon!)
        : (allPoints.isNotEmpty ? allPoints.last : origin);
    final fallback = allPoints.isEmpty ? [origin, destination] : allPoints;

    final markers = <Marker>[
      Marker(
        point: origin,
        width: 36,
        height: 36,
        child: const _MapMarker(
          icon: HugeIcons.strokeRoundedLocation01,
          color: AppColors.blue,
        ),
      ),
      Marker(
        point: destination,
        width: 36,
        height: 36,
        child: const _MapMarker(
          icon: HugeIcons.strokeRoundedBookmark01,
          color: AppColors.green,
        ),
      ),
      if (_current != null)
        Marker(
          point: _current!,
          width: 42,
          height: 42,
          child: const _MapMarker(
            icon: HugeIcons.strokeRoundedNavigation03,
            color: AppColors.blue,
          ),
        ),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
              child: Row(
                children: [
                  const AppIcon(
                    HugeIcons.strokeRoundedMaps,
                    size: 24,
                    color: AppColors.blue,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.route,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textMuted(context),
                          ),
                        ),
                        Text(
                          '${widget.fromName} → ${widget.toName}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: fallback[fallback.length ~/ 2],
                  initialZoom: 14.2,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'dev.ruszaj.ruszaj',
                  ),
                  PolylineLayer(polylines: polylines),
                  MarkerLayer(markers: markers),
                  RichAttributionWidget(
                    attributions: [
                      TextSourceAttribution('OpenStreetMap contributors'),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 15, 20, 22),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  const AppIcon(
                    HugeIcons.strokeRoundedRoute01,
                    color: AppColors.blue,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${widget.journey.durationSeconds ~/ 60} ${l10n.minutes}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  Text(
                    l10n.transit,
                    style: TextStyle(color: AppColors.textMuted(context)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapHeader extends StatelessWidget {
  const _MapHeader({required this.stop, required this.title});

  final NearbyStop stop;
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
    child: Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const AppIcon(HugeIcons.strokeRoundedArrowLeft01, size: 26),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textMuted(context),
                ),
              ),
              Text(
                stop.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _MapMarker extends StatelessWidget {
  const _MapMarker({required this.icon, required this.color});

  final List<List<dynamic>> icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 6)],
    ),
    child: AppIcon(icon, color: Colors.white, size: 17),
  );
}

class _WalkingRoute {
  const _WalkingRoute({required this.position, required this.journey});

  final LatLng position;
  final JourneyOption? journey;
}

String _localized(BuildContext context, String en, String pl) =>
    Localizations.localeOf(context).languageCode == 'pl' ? pl : en;

String _time(DateTime value) =>
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

List<LatLng> decodePolyline(String encoded, int precision) {
  if (encoded.isEmpty) return [];
  final points = <LatLng>[];
  var index = 0;
  var lat = 0;
  var lon = 0;
  final factor = pow10(precision);

  while (index < encoded.length) {
    var result = 0;
    var shift = 0;
    int byte;
    do {
      if (index >= encoded.length) return points;
      byte = encoded.codeUnitAt(index++) - 63;
      result |= (byte & 0x1f) << shift;
      shift += 5;
    } while (byte >= 0x20);
    lat += (result & 1) != 0 ? ~(result >> 1) : result >> 1;

    result = 0;
    shift = 0;
    do {
      if (index >= encoded.length) return points;
      byte = encoded.codeUnitAt(index++) - 63;
      result |= (byte & 0x1f) << shift;
      shift += 5;
    } while (byte >= 0x20);
    lon += (result & 1) != 0 ? ~(result >> 1) : result >> 1;

    points.add(LatLng(lat / factor, lon / factor));
  }
  return points;
}

double pow10(int value) =>
    List<double>.filled(value, 10).fold(1, (value, element) => value * element);
