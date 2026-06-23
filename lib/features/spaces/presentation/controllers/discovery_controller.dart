import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/place_category.dart';
import '../../domain/usecases/discover_spaces.dart';
import 'discovery_state.dart';

/// Drives the home screen: obtains the GPS location, runs discovery and exposes
/// category/filter selection.
class DiscoveryController extends Notifier<DiscoveryState> {
  @override
  DiscoveryState build() => const DiscoveryState.initial();

  Future<void> discover({bool forceRefresh = false}) async {
    // Stale-while-revalidate: render the device-cached result for this category
    // instantly (no spinner), then refresh from the backend below.
    if (state.spaces.isEmpty) {
      final cached =
          ref.read(spacesRepositoryProvider).cachedSpaces(state.category);
      if (cached.isNotEmpty) state = state.copyWith(spaces: cached);
    }
    state = state.copyWith(loading: true, clearError: true);
    try {
      final location = await ref.read(locationServiceProvider).getCurrentLocation();
      final spaces = await ref.read(discoverSpacesProvider).call(
            location: location,
            category: state.category,
            forceRefresh: forceRefresh,
          );

      state = state.copyWith(loading: false, spaces: spaces, location: location);
      await _notify();
    } on AppException catch (e) {
      state = state.copyWith(loading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: 'Algo deu errado. Tente novamente.',
      );
    }
  }

  /// Changing category requires a fresh backend query. Swap straight to that
  /// category's cached buffer (possibly empty) so we never show the previous
  /// category's cards while the new query runs.
  Future<void> setCategory(PlaceCategory category) async {
    if (category == state.category) return;
    final cached = ref.read(spacesRepositoryProvider).cachedSpaces(category);
    state = state.copyWith(category: category, spaces: cached);
    await discover();
  }

  /// Changing the Safe / Not-safe filter is purely client-side.
  void setFilter(SafetyFilter filter) {
    state = state.copyWith(filter: filter);
  }

  Future<void> _notify() async {
    if (state.spaces.isEmpty) return;
    await ref.read(notificationServiceProvider).showDiscoverySummary(
          total: state.spaces.length,
          safeCount: state.safeCount,
          unsafeCount: state.unsafeCount,
        );
  }
}

final discoveryControllerProvider =
    NotifierProvider<DiscoveryController, DiscoveryState>(
  DiscoveryController.new,
);
