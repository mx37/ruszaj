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
}
