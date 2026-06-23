import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/safe_space.dart';
import '../models/safe_space_model.dart';

/// On-device buffer of the last discovery result per category. Lets the home
/// screen show places instantly when the app reopens, while a fresh result is
/// fetched in the background (stale-while-revalidate). Stores the raw backend
/// payload, so it round-trips through the same [SafeSpaceModel.fromJson].
class DiscoveryCache {
  DiscoveryCache(this._prefs);

  final SharedPreferences _prefs;

  static const _prefix = 'discovery_cache_';

  Future<void> save(String category, List<dynamic> rawPlaces) async {
    try {
      await _prefs.setString('$_prefix$category', jsonEncode(rawPlaces));
    } catch (_) {
      // Caching is best-effort; never let it break a discovery.
    }
  }

  List<SafeSpace> load(String category) {
    final raw = _prefs.getString('$_prefix$category');
    if (raw == null) return const [];
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded
          .whereType<Map>()
          .map((e) => SafeSpaceModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return const [];
    }
  }
}
