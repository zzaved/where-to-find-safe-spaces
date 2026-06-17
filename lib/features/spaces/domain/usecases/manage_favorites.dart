import '../entities/safe_space.dart';
import '../repositories/spaces_repository.dart';

/// Reads the device's favorite places.
class GetFavorites {
  const GetFavorites(this._repository);

  final SpacesRepository _repository;

  Future<List<SafeSpace>> call() => _repository.favorites();

  Future<Set<String>> ids() => _repository.favoriteIds();
}

/// Adds or removes a place from favorites and returns the new state.
class ToggleFavorite {
  const ToggleFavorite(this._repository);

  final SpacesRepository _repository;

  Future<bool> call({required String placeId, required bool isFavorite}) async {
    if (isFavorite) {
      await _repository.removeFavorite(placeId);
      return false;
    }
    await _repository.addFavorite(placeId);
    return true;
  }
}
