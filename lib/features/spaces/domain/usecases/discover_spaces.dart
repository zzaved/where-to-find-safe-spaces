import '../entities/place_category.dart';
import '../entities/safe_space.dart';
import '../entities/safety_label.dart';
import '../entities/user_location.dart';
import '../repositories/spaces_repository.dart';

/// Discovers nearby places and applies the active safety filter.
class DiscoverSpaces {
  const DiscoverSpaces(this._repository);

  final SpacesRepository _repository;

  Future<List<SafeSpace>> call({
    required UserLocation location,
    required PlaceCategory category,
    SafetyFilter filter = SafetyFilter.all,
    int radius = 2000,
    bool forceRefresh = false,
  }) async {
    final spaces = await _repository.discover(
      location: location,
      category: category,
      radius: radius,
      forceRefresh: forceRefresh,
    );
    return spaces.where(filter.matches).toList();
  }
}

/// The Safe / Not-safe toggles on top of the home screen.
enum SafetyFilter {
  all,
  safe,
  notSafe;

  bool matches(SafeSpace space) {
    return switch (this) {
      SafetyFilter.all => true,
      SafetyFilter.safe => space.safetyLabel == SafetyLabel.safe,
      SafetyFilter.notSafe => space.safetyLabel == SafetyLabel.notSafe,
    };
  }
}
