import 'dart:convert';
import 'package:flutter/foundation.dart';
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
    departure: DateTime.parse(json['departure'] as String),
    arrival: DateTime.parse(json['arrival'] as String),
    durationSeconds: json['durationSeconds'] as int,
    transfers: json['transfers'] as int,
    legs: (json['legs'] as List)
        .map((item) => JourneyLeg.fromJson(item as Map<String, dynamic>))
        .toList(),
  );
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
  final List<String> intermediateStops;
  final String? geometry;
  final int? geometryPrecision;

  factory JourneyLeg.fromJson(Map<String, dynamic> json) => JourneyLeg(
    mode: json['mode'] as String,
    departure: DateTime.parse(json['departure'] as String),
    arrival: DateTime.parse(json['arrival'] as String),
    routeName: json['routeShortName'] as String?,
    headsign: json['headsign'] as String?,
    fromName: (json['from'] as Map<String, dynamic>?)?['name'] as String?,
    toName: (json['to'] as Map<String, dynamic>?)?['name'] as String?,
    intermediateStops: (json['intermediateStops'] as List<dynamic>? ?? const [])
        .map((stop) => (stop as Map<String, dynamic>)['name'] as String)
        .toList(),
    geometry: json['geometry'] as String?,
    geometryPrecision: json['geometryPrecision'] as int?,
  );
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

class RuszajApi {
  RuszajApi({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl =
          baseUrl ??
          const String.fromEnvironment('RUSZAJ_API_URL', defaultValue: '');

  final http.Client _client;
  final String _baseUrl;
  static const _timeout = Duration(seconds: 8);

  String get _effectiveBaseUrl {
    if (_baseUrl.isNotEmpty) return _baseUrl;
    return defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:8080'
        : 'http://127.0.0.1:8080';
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

  Future<List<JourneyOption>> journeys({
    required String from,
    required String to,
    bool walkingOnly = false,
  }) async {
    final uri = Uri.parse('$_effectiveBaseUrl/v1/journeys').replace(
      queryParameters: {
        'from': from,
        'to': to,
        'numItineraries': '10',
        if (walkingOnly) 'walkingOnly': 'true',
      },
    );
    final response = await _client.get(uri).timeout(_timeout);
    _check(response);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (data['journeys'] as List)
        .map((item) => JourneyOption.fromJson(item as Map<String, dynamic>))
        .toList();
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

  void _check(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw RuszajApiException(response.statusCode);
  }
}

class RuszajApiException implements Exception {
  const RuszajApiException(this.statusCode);
  final int statusCode;
}
