import 'package:equatable/equatable.dart';

import '../../domain/entities/place_category.dart';
import '../../domain/entities/safe_space.dart';
import '../../domain/entities/safety_label.dart';
import '../../domain/entities/user_location.dart';
import '../../domain/usecases/discover_spaces.dart';

/// Immutable state for the home/discovery screen.
class DiscoveryState extends Equatable {
  const DiscoveryState({
    required this.loading,
    required this.spaces,
    required this.category,
    required this.filter,
    this.location,
    this.error,
  });

  const DiscoveryState.initial()
      : loading = false,
        spaces = const [],
        category = PlaceCategory.all,
        filter = SafetyFilter.all,
        location = null,
        error = null;

  final bool loading;

  /// The full, unfiltered result from the last discovery.
  final List<SafeSpace> spaces;
  final PlaceCategory category;
  final SafetyFilter filter;
  final UserLocation? location;
  final String? error;

  /// How many nearest places to fall back to when a Safe / Not-safe filter
  /// finds nothing nearby.
  static const _fallbackLimit = 10;

  /// Spaces after applying the active Safe / Not-safe filter.
  List<SafeSpace> get visibleSpaces =>
      spaces.where(filter.matches).toList(growable: false);

  /// What the grid actually shows. Google's Nearby Search returns only the ~20
  /// nearest places (no pagination), and truly "unsafe" spots are rare — so a
  /// strict filter can legitimately match nothing. Rather than a dead-end empty
  /// screen, fall back to the nearest places of the current category.
  List<SafeSpace> get displaySpaces {
    if (filter == SafetyFilter.all) return spaces;
    final strict = visibleSpaces;
    if (strict.isNotEmpty) return strict;
    return spaces.take(_fallbackLimit).toList(growable: false);
  }

  /// True when the strict filter matched nothing and [displaySpaces] is showing
  /// the nearest-of-category fallback instead.
  bool get isFilterFallback =>
      filter != SafetyFilter.all && spaces.isNotEmpty && visibleSpaces.isEmpty;

  int get safeCount =>
      spaces.where((s) => s.safetyLabel == SafetyLabel.safe).length;

  int get unsafeCount =>
      spaces.where((s) => s.safetyLabel == SafetyLabel.notSafe).length;

  bool get hasLoadedOnce => spaces.isNotEmpty || error != null;

  DiscoveryState copyWith({
    bool? loading,
    List<SafeSpace>? spaces,
    PlaceCategory? category,
    SafetyFilter? filter,
    UserLocation? location,
    String? error,
    bool clearError = false,
  }) {
    return DiscoveryState(
      loading: loading ?? this.loading,
      spaces: spaces ?? this.spaces,
      category: category ?? this.category,
      filter: filter ?? this.filter,
      location: location ?? this.location,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [loading, spaces, category, filter, location, error];
}
