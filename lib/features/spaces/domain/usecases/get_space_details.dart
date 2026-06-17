import '../entities/safe_space.dart';
import '../repositories/spaces_repository.dart';

/// Fetches full details for a place, optionally forcing a fresh web check.
class GetSpaceDetails {
  const GetSpaceDetails(this._repository);

  final SpacesRepository _repository;

  Future<SafeSpace> call(String googlePlaceId, {bool forceRefresh = false}) {
    return _repository.details(
      googlePlaceId: googlePlaceId,
      forceRefresh: forceRefresh,
    );
  }
}
