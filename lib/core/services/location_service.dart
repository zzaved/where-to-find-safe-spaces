import 'package:geolocator/geolocator.dart';

import '../error/exceptions.dart';
import '../../features/spaces/domain/entities/user_location.dart';

/// Wraps the device GPS (hardware) behind a small, testable surface and
/// translates platform permission errors into [LocationException]s.
class LocationService {
  const LocationService();

  Future<UserLocation> getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationException(
        'A localização está desativada. Ative o GPS para encontrar locais perto de você.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const LocationException(
        'Permissão de localização negada. Precisamos dela para mostrar locais próximos.',
      );
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(
        'Permissão de localização bloqueada. Habilite nos Ajustes do iPhone.',
      );
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    return UserLocation(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }
}
