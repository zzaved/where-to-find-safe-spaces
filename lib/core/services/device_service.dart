import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

/// Provides a stable anonymous identifier for this device, used to scope
/// favorites and search history without requiring a login.
class DeviceService {
  DeviceService(this._prefs);

  final SharedPreferences _prefs;
  static const _key = 'device_id';

  String get deviceId {
    final existing = _prefs.getString(_key);
    if (existing != null) return existing;
    final generated = _generate();
    _prefs.setString(_key, generated);
    return generated;
  }

  String _generate() {
    final random = Random();
    final timestamp = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
    final suffix = List.generate(
      8,
      (_) => random.nextInt(16).toRadixString(16),
    ).join();
    return 'dev_${timestamp}_$suffix';
  }
}
