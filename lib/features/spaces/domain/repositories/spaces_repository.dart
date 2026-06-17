import '../entities/place_category.dart';
import '../entities/safe_space.dart';
import '../entities/user_location.dart';

/// Contract for everything the app needs to know about safe spaces.
/// The presentation layer depends on this abstraction, never on Supabase.
abstract interface class SpacesRepository {
  /// Discover nearby places ordered by proximity, each classified.
  Future<List<SafeSpace>> discover({
    required UserLocation location,
    required PlaceCategory category,
    int radius,
    bool forceRefresh,
  });

  /// Full details for a single place, running a deep web check on demand.
  Future<SafeSpace> details({
    required String googlePlaceId,
    bool forceRefresh,
  });

  /// Places the current device has saved as favorites.
  Future<List<SafeSpace>> favorites();

  /// IDs (place uuid) currently favorited by this device.
  Future<Set<String>> favoriteIds();

  Future<void> addFavorite(String placeId);

  Future<void> removeFavorite(String placeId);
}
