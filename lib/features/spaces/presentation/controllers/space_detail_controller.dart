import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../domain/entities/safe_space.dart';

/// Loads full details for one place. On first open this triggers the deep
/// Perplexity web-reputation check (run lazily by the backend).
class SpaceDetailController extends FamilyAsyncNotifier<SafeSpace, String> {
  @override
  Future<SafeSpace> build(String googlePlaceId) {
    return ref.read(getSpaceDetailsProvider).call(googlePlaceId);
  }

  /// Force a fresh web-reputation check.
  Future<void> refreshDeep() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(getSpaceDetailsProvider).call(arg, forceRefresh: true),
    );
  }
}

final spaceDetailControllerProvider =
    AsyncNotifierProvider.family<SpaceDetailController, SafeSpace, String>(
  SpaceDetailController.new,
);
