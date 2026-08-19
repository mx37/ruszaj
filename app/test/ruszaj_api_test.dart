import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:ruszaj/data/ruszaj_api.dart';

class FakeClient extends http.BaseClient {
  FakeClient(this.body);
  final String body;
  Uri? lastUri;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    lastUri = request.url;
    return http.StreamedResponse(
      Stream.value(body.codeUnits),
      200,
      headers: {'content-type': 'application/json'},
    );
  }
}

void main() {
  test('search decodes Ruszaj places', () async {
    final client = FakeClient(
      '[{"id":"stop-1","name":"Central","type":"STOP","coordinates":{"lat":52.2,"lon":21.0}}]',
    );
    final places = await RuszajApi(
      client: client,
      baseUrl: 'https://api.ruszaj.app',
    ).search('Central');
    expect(places.single.name, 'Central');
    expect(client.lastUri?.path, '/v1/search');
    expect(client.lastUri?.queryParameters['q'], 'Central');
  });

  test('journeys decodes options and legs', () async {
    final client = FakeClient(
      '{"journeys":[{"id":"j1","departure":"2026-08-06T10:00:00Z","arrival":"2026-08-06T10:30:00Z","durationSeconds":1800,"transfers":0,"legs":[{"mode":"BUS","departure":"2026-08-06T10:00:00Z","arrival":"2026-08-06T10:30:00Z","routeShortName":"18"}]}]}',
    );
    final journeys = await RuszajApi(
      client: client,
      baseUrl: 'https://api.ruszaj.app',
    ).journeys(from: 'a', to: 'b');
    expect(journeys.single.legs.single.routeName, '18');
    expect(client.lastUri?.queryParameters['from'], 'a');
  });

  test('stop decodes routes', () async {
    final client = FakeClient(
      '{"id":"pl-stop:1","name":"Rondo","coordinates":{"lat":53.12,"lon":18.01},"stopCode":"01","modes":["BUS","TRAM"],"routes":[{"id":"r1","shortName":"5","longName":"Centrum","mode":"TRAM","agencyName":"MZK"}]}',
    );
    final stop = await RuszajApi(
      client: client,
      baseUrl: 'https://api.ruszaj.app',
    ).stop('pl-stop:1');

    expect(stop.name, 'Rondo');
    expect(stop.routes.single.shortName, '5');
    expect(client.lastUri?.path, '/v1/stops/pl-stop%3A1');
  });

  test('departures decodes realtime and cancelled state', () async {
    final client = FakeClient(
      '{"stop":{"id":"pl-stop:1","name":"Rondo","coordinates":{"lat":53.12,"lon":18.01}},"departures":[{"mode":"TRAM","realTime":true,"headsign":"Centrum","tripId":"t1","routeShortName":"5","routeLongName":"Linia 5","displayName":"5","agencyName":"MZK","scheduledDeparture":"2026-08-19T08:00:00Z","departure":"2026-08-19T08:03:00Z","track":"2","cancelled":false,"tripCancelled":false,"bikesAllowed":true},{"mode":"BUS","realTime":false,"headsign":"Dworzec","tripId":"t2","routeShortName":"80","routeLongName":"Linia 80","displayName":"80","agencyName":"MZK","scheduledDeparture":"2026-08-19T08:10:00Z","departure":"2026-08-19T08:10:00Z","cancelled":true,"tripCancelled":false,"bikesAllowed":false}]}',
    );
    final page = await RuszajApi(
      client: client,
      baseUrl: 'https://api.ruszaj.app',
    ).departures('pl-stop:1');

    expect(page.departures.length, 2);
    expect(page.departures.first.realTime, isTrue);
    expect(
      page.departures.first.departure!
          .difference(page.departures.first.scheduledDeparture!)
          .inMinutes,
      3,
    );
    expect(page.departures.last.isCancelled, isTrue);
    expect(client.lastUri?.path, '/v1/stops/pl-stop%3A1/departures');
    expect(client.lastUri?.queryParameters['direction'], 'LATER');
  });
}
