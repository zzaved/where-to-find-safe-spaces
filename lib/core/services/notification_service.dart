import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Local notifications. Used to alert the user after a discovery completes
/// (e.g. how many safe spaces were found nearby) and when a nearby place is
/// flagged as not safe.
class NotificationService {
  NotificationService();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(
      const InitializationSettings(iOS: darwin, android: android),
    );
    _initialized = true;
  }

  /// Requests OS permission to display notifications (iOS prompt).
  Future<bool> requestPermission() async {
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    final granted = await ios?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    return granted ?? true;
  }

  Future<void> showDiscoverySummary({
    required int total,
    required int safeCount,
    required int unsafeCount,
  }) async {
    await init();
    final body = safeCount > 0
        ? 'Encontramos $safeCount espaço(s) seguro(s) entre $total locais perto de você.'
        : 'Analisamos $total locais perto de você. Toque para conferir.';
    await _plugin.show(
      1001,
      'Busca concluída',
      body,
      _details(),
    );
  }

  Future<void> showUnsafeNearby(String placeName) async {
    await init();
    await _plugin.show(
      1002,
      'Atenção por perto',
      '$placeName foi sinalizado como possível espaço não seguro.',
      _details(),
    );
  }

  NotificationDetails _details() {
    return const NotificationDetails(
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBanner: true,
        presentSound: true,
        presentBadge: true,
      ),
      android: AndroidNotificationDetails(
        'discovery',
        'Descobertas',
        channelDescription: 'Resultados de busca de espaços seguros',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );
  }
}
