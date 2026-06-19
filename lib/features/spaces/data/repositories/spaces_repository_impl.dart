import '../../domain/entities/place_category.dart';
import '../../domain/entities/safe_space.dart';
import '../../domain/entities/user_location.dart';
import '../../domain/repositories/spaces_repository.dart';
import '../datasources/spaces_remote_datasource.dart';

/// Default [SpacesRepository] backed by Supabase.
class SpacesRepositoryImpl implements SpacesRepository {
  const SpacesRepositoryImpl(this._remote);

  final SpacesRemoteDataSource _remote;

  @override
  Future<List<SafeSpace>> discover({
    required UserLocation location,
    required PlaceCategory category,
    int radius = 2000,
    bool forceRefresh = false,
  }) {
    return _remote.discover(
      lat: location.latitude,
      lng: location.longitude,
      category: category.apiValue,
      radius: radius,
      forceRefresh: forceRefresh,
    );
  }

  @override
  Future<SafeSpace> details({
    required String googlePlaceId,
    bool forceRefresh = false,
  }) {
    return _remote.details(
      googlePlaceId: googlePlaceId,
      forceRefresh: forceRefresh,
    );
  }

  @override
  Future<List<SafeSpace>> favorites() => _remote.favorites();

  @override
  Future<Set<String>> favoriteIds() => _remote.favoriteIds();

  @override
  Future<void> addFavorite(String placeId) => _remote.addFavorite(placeId);

  @override
  Future<void> removeFavorite(String placeId) => _remote.removeFavorite(placeId);
}
