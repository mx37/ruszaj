import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:url_launcher/url_launcher.dart';
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
      _subscription =
          Geolocator.getPositionStream(
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
      // Route remains visible when location permission is unavailable.
    }
  }

  Future<void> _openMaps(LatLng origin, LatLng destination) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&origin=${origin.latitude},${origin.longitude}'
      '&destination=${destination.latitude},${destination.longitude}&travelmode=walking',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
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
        final from = leg.fromLat != null && leg.fromLon != null
            ? LatLng(leg.fromLat!, leg.fromLon!)
            : null;
        final to = leg.toLat != null && leg.toLon != null
            ? LatLng(leg.toLat!, leg.toLon!)
            : null;
        if (from != null && to != null) {
          polylines.add(
            Polyline(
              points: [from, to],
              color: leg.mode == 'WALK' ? AppColors.blue : AppColors.ink,
              strokeWidth: 5,
            ),
          );
          allPoints.addAll([from, to]);
        }
        continue;
      }
      polylines.add(
        Polyline(
          points: points,
          color: leg.mode == 'WALK' ? AppColors.blue : AppColors.ink,
          strokeWidth: 5,
        ),
      );
      allPoints.addAll(points);
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
    ];
    for (var i = 1; i < legs.length; i++) {
      final leg = legs[i];
      if (leg.fromLat == null || leg.fromLon == null) continue;
      markers.add(
        Marker(
          point: LatLng(leg.fromLat!, leg.fromLon!),
          width: 36,
          height: 36,
          child: _MapMarker(
            icon: HugeIcons.strokeRoundedArrowUpDown,
            color: AppColors.green,
          ),
        ),
      );
    }
    markers.add(
      Marker(
        point: destination,
        width: 36,
        height: 36,
        child: const _MapMarker(
          icon: HugeIcons.strokeRoundedBookmark01,
          color: AppColors.green,
        ),
      ),
    );
    if (_current != null) {
      markers.add(
        Marker(
          point: _current!,
          width: 42,
          height: 42,
          child: const _MapMarker(
            icon: HugeIcons.strokeRoundedNavigation03,
            color: AppColors.blue,
          ),
        ),
      );
    }
    final fallback = allPoints.isNotEmpty ? allPoints : [origin, destination];
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
                  IconButton(
                    onPressed: () => _openMaps(origin, destination),
                    tooltip: l10n.openInMaps,
                    icon: const AppIcon(
                      HugeIcons.strokeRoundedNavigation03,
                      size: 21,
                      color: AppColors.blue,
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
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.journey.durationSeconds >= 0
                              ? '${widget.journey.durationSeconds % 3600 ~/ 60} ${l10n.minutes}'
                              : l10n.transit,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                        if (widget.journey.transfers > 0)
                          Text(
                            '${widget.journey.transfers} ${l10n.transfers}',
                            style: TextStyle(
                              color: AppColors.textMuted(context),
                            ),
                          ),
                      ],
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

class _WalkToStopPageState extends State<WalkToStopPage> {
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
            return _MapContent(
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

class _MapContent extends StatelessWidget {
  const _MapContent({
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
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
      byte = encoded.codeUnitAt(index++) - 63;
      result |= (byte & 0x1f) << shift;
      shift += 5;
    } while (byte >= 0x20 && index < encoded.length);
    lat += (result & 1) != 0 ? ~(result >> 1) : result >> 1;
    result = 0;
    shift = 0;
    do {
      byte = encoded.codeUnitAt(index++) - 63;
      result |= (byte & 0x1f) << shift;
      shift += 5;
    } while (byte >= 0x20 && index < encoded.length);
    lon += (result & 1) != 0 ? ~(result >> 1) : result >> 1;
    points.add(LatLng(lat / factor, lon / factor));
  }
  return points;
}

double pow10(int value) =>
    List<double>.filled(value, 10).fold(1, (value, element) => value * element);
