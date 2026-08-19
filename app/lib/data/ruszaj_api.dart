import 'dart:convert';
import 'package:http/http.dart' as http;

class SearchPlace {
  const SearchPlace({
    required this.id,
    required this.name,
    required this.type,
    required this.lat,
    required this.lon,
  });

  final String id;
  final String name;
  final String type;
  final double lat;
  final double lon;

  factory SearchPlace.fromJson(Map<String, dynamic> json) => SearchPlace(
    id: json['id'] as String,
    name: json['name'] as String,
    type: json['type'] as String,
    lat: (json['coordinates']['lat'] as num).toDouble(),
    lon: (json['coordinates']['lon'] as num).toDouble(),
  );
}

class JourneyOption {
  const JourneyOption({
    required this.id,
    required this.departure,
    required this.arrival,
    required this.durationSeconds,
    required this.transfers,
    required this.legs,
  });

  final String id;
  final DateTime departure;
  final DateTime arrival;
  final int durationSeconds;
  final int transfers;
  final List<JourneyLeg> legs;

  factory JourneyOption.fromJson(Map<String, dynamic> json) => JourneyOption(
    id: json['id'] as String,
    departure: DateTime.parse(json['departure'] as String).toLocal(),
    arrival: DateTime.parse(json['arrival'] as String).toLocal(),
    durationSeconds: json['durationSeconds'] as int,
    transfers: json['transfers'] as int,
    legs: (json['legs'] as List)
        .map((item) => JourneyLeg.fromJson(item as Map<String, dynamic>))
        .toList(),
  );
}

class JourneyPage {
  const JourneyPage({
    required this.journeys,
    this.previousPageCursor,
    this.nextPageCursor,
  });

  final List<JourneyOption> journeys;
  final String? previousPageCursor;
  final String? nextPageCursor;
}

class JourneyLeg {
  const JourneyLeg({
    required this.mode,
    required this.departure,
    required this.arrival,
    this.routeName,
    this.headsign,
    this.fromName,
    this.toName,
    this.fromLat,
    this.fromLon,
    this.toLat,
    this.toLon,
    this.intermediateStops = const [],
    this.geometry,
    this.geometryPrecision,
  });

  final String mode;
  final DateTime departure;
  final DateTime arrival;
  final String? routeName;
  final String? headsign;
  final String? fromName;
  final String? toName;
  final double? fromLat;
  final double? fromLon;
  final double? toLat;
  final double? toLon;
  final List<IntermediateStop> intermediateStops;
  final String? geometry;
  final int? geometryPrecision;

  factory JourneyLeg.fromJson(Map<String, dynamic> json) => JourneyLeg(
    mode: json['mode'] as String,
    departure: DateTime.parse(json['departure'] as String).toLocal(),
    arrival: DateTime.parse(json['arrival'] as String).toLocal(),
    routeName: json['routeShortName'] as String?,
    headsign: json['headsign'] as String?,
    fromName: (json['from'] as Map<String, dynamic>?)?['name'] as String?,
    toName: (json['to'] as Map<String, dynamic>?)?['name'] as String?,
    fromLat:
        (((json['from'] as Map<String, dynamic>?)?['coordinates']
                    as Map<String, dynamic>?)?['lat']
                as num?)
            ?.toDouble(),
    fromLon:
        (((json['from'] as Map<String, dynamic>?)?['coordinates']
                    as Map<String, dynamic>?)?['lon']
                as num?)
            ?.toDouble(),
    toLat:
        (((json['to'] as Map<String, dynamic>?)?['coordinates']
                    as Map<String, dynamic>?)?['lat']
                as num?)
            ?.toDouble(),
    toLon:
        (((json['to'] as Map<String, dynamic>?)?['coordinates']
                    as Map<String, dynamic>?)?['lon']
                as num?)
            ?.toDouble(),
    intermediateStops: (json['intermediateStops'] as List<dynamic>? ?? const [])
        .map((stop) => IntermediateStop.fromJson(stop as Map<String, dynamic>))
        .toList(),
    geometry: json['geometry'] as String?,
    geometryPrecision: json['geometryPrecision'] as int?,
  );
}

class IntermediateStop {
  const IntermediateStop({required this.name, this.arrival});

  final String name;
  final DateTime? arrival;

  factory IntermediateStop.fromJson(Map<String, dynamic> json) {
    final departureRaw = json['departure'] as String?;
    final arrivalRaw = json['arrival'] as String?;
    final time = arrivalRaw ?? departureRaw;
    return IntermediateStop(
      name: json['name'] as String,
      arrival: time == null ? null : DateTime.parse(time).toLocal(),
    );
  }
}

class NearbyStop {
  const NearbyStop({
    required this.id,
    required this.name,
    required this.distanceMeters,
    required this.lat,
    required this.lon,
  });

  final String id;
  final String name;
  final int distanceMeters;
  final double lat;
  final double lon;

  factory NearbyStop.fromJson(Map<String, dynamic> json) => NearbyStop(
    id: json['id'] as String,
    name: json['name'] as String,
    distanceMeters: json['distanceMeters'] as int,
    lat: (json['coordinates']['lat'] as num).toDouble(),
    lon: (json['coordinates']['lon'] as num).toDouble(),
  );
}

class StopRoute {
  const StopRoute({
    required this.id,
    required this.shortName,
    required this.longName,
    required this.mode,
    required this.agencyName,
    this.routeColor,
  });

  final String id;
  final String shortName;
  final String longName;
  final String mode;
  final String agencyName;
  final String? routeColor;

  factory StopRoute.fromJson(Map<String, dynamic> json) => StopRoute(
    id: json['id'] as String? ?? '',
    shortName: json['shortName'] as String? ?? '',
    longName: json['longName'] as String? ?? '',
    mode: json['mode'] as String? ?? '',
    agencyName: json['agencyName'] as String? ?? '',
    routeColor: json['routeColor'] as String?,
  );
}

class StopDetails {
  const StopDetails({
    required this.id,
    required this.name,
    required this.lat,
    required this.lon,
    required this.routes,
    this.stopCode,
    this.modes = const [],
  });

  final String id;
  final String name;
  final double lat;
  final double lon;
  final String? stopCode;
  final List<String> modes;
  final List<StopRoute> routes;

  factory StopDetails.fromJson(Map<String, dynamic> json) => StopDetails(
    id: json['id'] as String,
    name: json['name'] as String,
    lat: (json['coordinates']['lat'] as num).toDouble(),
    lon: (json['coordinates']['lon'] as num).toDouble(),
    stopCode: json['stopCode'] as String?,
    modes: (json['modes'] as List<dynamic>? ?? const [])
        .map((value) => value.toString())
        .toList(),
    routes: (json['routes'] as List<dynamic>? ?? const [])
        .map((value) => StopRoute.fromJson(value as Map<String, dynamic>))
        .toList(),
  );
}

class StopDeparture {
  const StopDeparture({
    required this.mode,
    required this.realTime,
    required this.headsign,
    required this.tripId,
    required this.routeShortName,
    required this.routeLongName,
    required this.displayName,
    required this.agencyName,
    required this.cancelled,
    required this.tripCancelled,
    required this.bikesAllowed,
    this.scheduledDeparture,
    this.departure,
    this.track,
  });

  final String mode;
  final bool realTime;
  final String headsign;
  final String tripId;
  final String routeShortName;
  final String routeLongName;
  final String displayName;
  final String agencyName;
  final DateTime? scheduledDeparture;
  final DateTime? departure;
  final String? track;
  final bool cancelled;
  final bool tripCancelled;
  final bool bikesAllowed;

  bool get isCancelled => cancelled || tripCancelled;

  factory StopDeparture.fromJson(Map<String, dynamic> json) => StopDeparture(
    mode: json['mode'] as String? ?? '',
    realTime: json['realTime'] as bool? ?? false,
    headsign: json['headsign'] as String? ?? '',
    tripId: json['tripId'] as String? ?? '',
    routeShortName: json['routeShortName'] as String? ?? '',
    routeLongName: json['routeLongName'] as String? ?? '',
    displayName: json['displayName'] as String? ?? '',
    agencyName: json['agencyName'] as String? ?? '',
    scheduledDeparture: _dateTimeOrNull(json['scheduledDeparture']),
    departure: _dateTimeOrNull(json['departure']),
    track: json['track'] as String?,
    cancelled: json['cancelled'] as bool? ?? false,
    tripCancelled: json['tripCancelled'] as bool? ?? false,
    bikesAllowed: json['bikesAllowed'] as bool? ?? false,
  );
}

class DeparturesPage {
  const DeparturesPage({
    required this.stop,
    required this.departures,
    this.previousPageCursor,
    this.nextPageCursor,
  });

  final NearbyStop stop;
  final List<StopDeparture> departures;
  final String? previousPageCursor;
  final String? nextPageCursor;

  factory DeparturesPage.fromJson(Map<String, dynamic> json) {
    final stop = json['stop'] as Map<String, dynamic>;
    return DeparturesPage(
      stop: NearbyStop(
        id: stop['id'] as String,
        name: stop['name'] as String,
        distanceMeters: 0,
        lat: (stop['coordinates']['lat'] as num).toDouble(),
        lon: (stop['coordinates']['lon'] as num).toDouble(),
      ),
      departures: (json['departures'] as List<dynamic>? ?? const [])
          .map((value) => StopDeparture.fromJson(value as Map<String, dynamic>))
          .toList(),
      previousPageCursor: json['previousPageCursor'] as String?,
      nextPageCursor: json['nextPageCursor'] as String?,
    );
  }
}

DateTime? _dateTimeOrNull(dynamic raw) {
  if (raw is! String || raw.isEmpty) return null;
  return DateTime.tryParse(raw)?.toLocal();
}

class RuszajApi {
  RuszajApi({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl =
          baseUrl ??
          const String.fromEnvironment('RUSZAJ_API_URL', defaultValue: '');

  final http.Client _client;
  final String _baseUrl;
  static const _timeout = Duration(seconds: 8);
  static String _baseUrlOverride = '';

  static String get configuredBaseUrl => _baseUrlOverride;

  static void setBaseUrlOverride(String value) {
    _baseUrlOverride = value.trim().replaceAll(RegExp(r'/+$'), '');
  }

  String get _effectiveBaseUrl {
    if (_baseUrlOverride.isNotEmpty) return _baseUrlOverride;
    if (_baseUrl.isNotEmpty) return _baseUrl;
    return 'https://ruszaj.mx37.me';
  }

  Future<List<SearchPlace>> search(
    String query, {
    int limit = 8,
    String? city,
  }) async {
    final queryParameters = {'q': query, 'limit': '$limit'};
    if (city != null) queryParameters['city'] = city;
    final uri = Uri.parse(
      '$_effectiveBaseUrl/v1/search',
    ).replace(queryParameters: queryParameters);
    final response = await _client.get(uri).timeout(_timeout);
    _check(response);
    final data = jsonDecode(response.body) as List;
    return data
        .map((item) => SearchPlace.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<SearchPlace?> reverseGeocode({
    required double lat,
    required double lon,
  }) async {
    final uri = Uri.parse(
      '$_effectiveBaseUrl/v1/reverse-geocode',
    ).replace(queryParameters: {'lat': '$lat', 'lon': '$lon'});
    final response = await _client.get(uri).timeout(_timeout);
    _check(response);
    final data = jsonDecode(response.body) as List;
    if (data.isEmpty) return null;
    final places = data
        .map((item) => SearchPlace.fromJson(item as Map<String, dynamic>))
        .toList();
    return places.firstWhere(
      (place) => place.type == 'ADDRESS',
      orElse: () => places.first,
    );
  }

  Future<JourneyPage> journeyPage({
    required String from,
    required String to,
    bool walkingOnly = false,
    DateTime? time,
    bool arriveBy = false,
    String? pageCursor,
  }) async {
    final uri = Uri.parse('$_effectiveBaseUrl/v1/journeys').replace(
      queryParameters: {
        'from': from,
        'to': to,
        'numItineraries': '10',
        if (walkingOnly) 'walkingOnly': 'true',
        if (time != null) 'time': time.toUtc().toIso8601String(),
        if (arriveBy) 'arriveBy': 'true',
        ...?(pageCursor == null ? null : {'pageCursor': pageCursor}),
      },
    );
    final response = await _client.get(uri).timeout(_timeout);
    _check(response);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return JourneyPage(
      journeys: (data['journeys'] as List)
          .map((item) => JourneyOption.fromJson(item as Map<String, dynamic>))
          .toList(),
      previousPageCursor: data['previousPageCursor'] as String?,
      nextPageCursor: data['nextPageCursor'] as String?,
    );
  }

  Future<List<JourneyOption>> journeys({
    required String from,
    required String to,
    bool walkingOnly = false,
  }) async {
    final page = await journeyPage(
      from: from,
      to: to,
      walkingOnly: walkingOnly,
    );
    return page.journeys;
  }

  Future<List<NearbyStop>> nearbyStops({
    required double lat,
    required double lon,
  }) async {
    final uri = Uri.parse(
      '$_effectiveBaseUrl/v1/stops/nearby',
    ).replace(queryParameters: {'lat': '$lat', 'lon': '$lon', 'limit': '20'});
    final response = await _client.get(uri).timeout(_timeout);
    _check(response);
    final data = jsonDecode(response.body) as List;
    return data
        .map((item) => NearbyStop.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<StopDetails> stop(String id) async {
    final uri = Uri.parse('$_effectiveBaseUrl/v1/stops/${Uri.encodeComponent(id)}');
    final response = await _client.get(uri).timeout(_timeout);
    _check(response);
    return StopDetails.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<DeparturesPage> departures(
    String stopId, {
    int limit = 30,
    DateTime? time,
    String direction = 'LATER',
  }) async {
    final uri = Uri.parse(
      '$_effectiveBaseUrl/v1/stops/${Uri.encodeComponent(stopId)}/departures',
    ).replace(
      queryParameters: {
        'limit': '$limit',
        'direction': direction,
        if (time != null) 'time': time.toUtc().toIso8601String(),
      },
    );
    final response = await _client.get(uri).timeout(_timeout);
    _check(response);
    return DeparturesPage.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  void _check(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw RuszajApiException(response.statusCode);
  }
}

class RuszajApiException implements Exception {
  const RuszajApiException(this.statusCode);
  final int statusCode;
}
