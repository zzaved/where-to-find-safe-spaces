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

  /// Changing category requires a fresh backend query.
  Future<void> setCategory(PlaceCategory category) async {
    if (category == state.category) return;
    state = state.copyWith(category: category);
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
