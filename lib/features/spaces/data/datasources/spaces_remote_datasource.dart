import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/services/device_service.dart';
import '../../domain/entities/safe_space.dart';
import '../models/safe_space_model.dart';
import 'discovery_cache.dart';

/// Talks to Supabase: the `spaces` edge function for discovery/details and the
/// `favorites` table for per-device persistence.
class SpacesRemoteDataSource {
  SpacesRemoteDataSource(this._client, this._deviceService, this._cache);

  final SupabaseClient _client;
  final DeviceService _deviceService;
  final DiscoveryCache _cache;

  Future<List<SafeSpaceModel>> discover({
    required double lat,
    required double lng,
    required String category,
    required int radius,
    required bool forceRefresh,
  }) async {
    final data = await _invokeSpaces({
      'action': 'discover',
      'lat': lat,
      'lng': lng,
      'category': category,
      'radius': radius,
      'forceRefresh': forceRefresh,
      'deviceId': _deviceService.deviceId,
    });
    final places = (data['places'] as List?) ?? const [];
    await _cache.save(category, places);
    return places
        .map((e) => SafeSpaceModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Last discovery for [category] from the on-device buffer (empty if none).
  List<SafeSpace> cachedDiscover(String category) => _cache.load(category);

  Future<SafeSpaceModel> details({
    required String googlePlaceId,
    required bool forceRefresh,
  }) async {
    final data = await _invokeSpaces({
      'action': 'details',
      'googlePlaceId': googlePlaceId,
      'forceRefresh': forceRefresh,
    });
    final place = data['place'];
    if (place == null) {
      throw const ServerException('Local não encontrado.');
    }
    return SafeSpaceModel.fromJson(Map<String, dynamic>.from(place as Map));
  }

  Future<List<SafeSpaceModel>> favorites() async {
    try {
      final rows = await _client
          .from('favorites')
          .select('created_at, places(*)')
          .eq('device_id', _deviceService.deviceId)
          .order('created_at', ascending: false);
      return (rows as List)
          .where((row) => row['places'] != null)
          .map((row) =>
              SafeSpaceModel.fromJson(Map<String, dynamic>.from(row['places'])))
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  Future<Set<String>> favoriteIds() async {
    try {
      final rows = await _client
          .from('favorites')
          .select('place_id')
          .eq('device_id', _deviceService.deviceId);
      return (rows as List).map((row) => row['place_id'] as String).toSet();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  Future<void> addFavorite(String placeId) async {
    try {
      await _client.from('favorites').upsert(
        {'device_id': _deviceService.deviceId, 'place_id': placeId},
        onConflict: 'device_id,place_id',
      );
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  Future<void> removeFavorite(String placeId) async {
    try {
      await _client
          .from('favorites')
          .delete()
          .eq('device_id', _deviceService.deviceId)
          .eq('place_id', placeId);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  Future<Map<String, dynamic>> _invokeSpaces(Map<String, dynamic> body) async {
    try {
      final response = await _client.functions.invoke('spaces', body: body);
      final data = response.data;
      if (data is! Map) {
        throw const ParsingException('Resposta inesperada do servidor.');
      }
      if (data['error'] != null) {
        throw ServerException(data['error'].toString());
      }
      return Map<String, dynamic>.from(data);
    } on FunctionException catch (e) {
      throw ServerException(_functionError(e));
    }
  }

  String _functionError(FunctionException e) {
    final details = e.details;
    if (details is Map && details['error'] != null) {
      return details['error'].toString();
    }
    return 'Falha ao falar com o servidor (${e.status}).';
  }
}
