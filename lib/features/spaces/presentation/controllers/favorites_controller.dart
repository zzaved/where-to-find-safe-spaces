import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../domain/entities/safe_space.dart';

/// Loads and mutates the device's favorite places.
class FavoritesController extends AsyncNotifier<List<SafeSpace>> {
  @override
  Future<List<SafeSpace>> build() {
    return ref.read(getFavoritesProvider).call();
  }

  Future<void> toggle(SafeSpace space) async {
    final current = state.valueOrNull ?? const [];
    final isFavorite = current.any((s) => s.id == space.id);

    await ref.read(toggleFavoriteProvider).call(
          placeId: space.id,
          isFavorite: isFavorite,
        );

    // Optimistically update, then reconcile with the backend.
    if (isFavorite) {
      state = AsyncData(current.where((s) => s.id != space.id).toList());
    } else {
      state = AsyncData([space, ...current]);
    }
    ref.invalidateSelf();
  }
}

final favoritesControllerProvider =
    AsyncNotifierProvider<FavoritesController, List<SafeSpace>>(
  FavoritesController.new,
);

/// Convenience view of which place ids are currently favorited.
final favoriteIdsProvider = Provider<Set<String>>((ref) {
  final favorites = ref.watch(favoritesControllerProvider);
  return favorites.maybeWhen(
    data: (list) => list.map((s) => s.id).toSet(),
    orElse: () => const {},
  );
});
