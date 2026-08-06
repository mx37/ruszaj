import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<Position> currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationException('service-disabled');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const LocationException('permission-denied');
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationException('permission-denied-forever');
    }
    return Geolocator.getCurrentPosition();
  }
}

class LocationException implements Exception {
  const LocationException(this.code);
  final String code;
}
