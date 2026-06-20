import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/spaces/data/datasources/spaces_remote_datasource.dart';
import '../../features/spaces/data/repositories/spaces_repository_impl.dart';
import '../../features/spaces/domain/repositories/spaces_repository.dart';
import '../../features/spaces/domain/usecases/discover_spaces.dart';
import '../../features/spaces/domain/usecases/get_space_details.dart';
import '../../features/spaces/domain/usecases/manage_favorites.dart';
import '../services/device_service.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import '../services/share_service.dart';

/// Overridden in `main()` once SharedPreferences has loaded.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (_) => throw UnimplementedError('sharedPreferencesProvider not initialized'),
);

// --- Infrastructure ---------------------------------------------------------

final supabaseClientProvider =
    Provider<SupabaseClient>((_) => Supabase.instance.client);

final deviceServiceProvider = Provider<DeviceService>(
  (ref) => DeviceService(ref.watch(sharedPreferencesProvider)),
);

final locationServiceProvider =
    Provider<LocationService>((_) => const LocationService());

final notificationServiceProvider =
    Provider<NotificationService>((_) => NotificationService());

final shareServiceProvider = Provider<ShareService>((_) => const ShareService());

// --- Data -------------------------------------------------------------------

final spacesRemoteDataSourceProvider = Provider<SpacesRemoteDataSource>(
  (ref) => SpacesRemoteDataSource(
    ref.watch(supabaseClientProvider),
    ref.watch(deviceServiceProvider),
  ),
);

final spacesRepositoryProvider = Provider<SpacesRepository>(
  (ref) => SpacesRepositoryImpl(ref.watch(spacesRemoteDataSourceProvider)),
);

// --- Use cases --------------------------------------------------------------

final discoverSpacesProvider = Provider<DiscoverSpaces>(
  (ref) => DiscoverSpaces(ref.watch(spacesRepositoryProvider)),
);

final getSpaceDetailsProvider = Provider<GetSpaceDetails>(
  (ref) => GetSpaceDetails(ref.watch(spacesRepositoryProvider)),
);

final getFavoritesProvider = Provider<GetFavorites>(
  (ref) => GetFavorites(ref.watch(spacesRepositoryProvider)),
);

final toggleFavoriteProvider = Provider<ToggleFavorite>(
  (ref) => ToggleFavorite(ref.watch(spacesRepositoryProvider)),
);
