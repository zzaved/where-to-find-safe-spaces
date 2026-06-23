// Screenshot harness: drives the real app through every screen by tapping
// widgets in the tree (reliable, no synthetic mouse events) and prints a
// `SHOT::<name>` marker on each screen. An external capturer watches the test
// log for those markers and grabs the device screen with `simctl`, so even
// system UI (notification banner, share sheet) is captured.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:safe_spaces/app.dart';
import 'package:safe_spaces/core/config/env.dart';
import 'package:safe_spaces/core/di/providers.dart';
import 'package:safe_spaces/core/services/location_service.dart';
import 'package:safe_spaces/core/services/notification_service.dart';
import 'package:safe_spaces/core/theme/app_theme.dart';
import 'package:safe_spaces/features/spaces/domain/entities/user_location.dart';
import 'package:safe_spaces/features/spaces/presentation/screens/home_screen.dart';
import 'package:safe_spaces/features/spaces/presentation/widgets/space_card.dart';

/// Returns a fixed location (Av. Paulista, São Paulo) so the run is
/// deterministic and never raises the native GPS permission dialog — which a
/// widget test cannot dismiss and which reinstalling the app keeps resetting.
class FakeLocationService implements LocationService {
  @override
  Future<UserLocation> getCurrentLocation() async =>
      const UserLocation(latitude: -23.561414, longitude: -46.655881);
}

/// No-op notifications: avoids the native permission dialog (which would
/// overlay later screenshots). The in-app "Notificação enviada!" confirmation
/// still appears, documenting the feature.
class FakeNotificationService implements NotificationService {
  @override
  Future<void> init() async {}
  @override
  Future<bool> requestPermission() async => true;
  @override
  Future<void> showDiscoverySummary({
    required int total,
    required int safeCount,
    required int unsafeCount,
  }) async {}
  @override
  Future<void> showUnsafeNearby(String placeName) async {}
}

List<Override> _overrides(prefs) => [
      sharedPreferencesProvider.overrideWithValue(prefs),
      locationServiceProvider.overrideWithValue(FakeLocationService()),
      notificationServiceProvider.overrideWithValue(FakeNotificationService()),
    ];

/// Dwell on the current frame and signal the capturer to take the shot.
Future<void> shot(String name) async {
  debugPrint('SHOT::$name');
  await Future<void>.delayed(const Duration(milliseconds: 3500));
}

/// Pump in a loop (real time) until [finder] matches or the timeout elapses.
/// Used instead of pumpAndSettle because loading spinners never settle.
Future<bool> pumpUntil(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 80),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 400));
    if (finder.evaluate().isNotEmpty) return true;
  }
  return false;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('capture all screens', (tester) async {
    await dotenv.load(fileName: '.env');
    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
    );
    final prefs = await SharedPreferences.getInstance();
    final overrides = _overrides(prefs);

    // --- 1) Onboarding -----------------------------------------------------
    await tester.pumpWidget(
      ProviderScope(overrides: overrides, child: const SafeSpacesApp()),
    );
    await tester.pump(const Duration(seconds: 1));
    await shot('01_onboarding');

    // --- 2) Home -----------------------------------------------------------
    // Pump HomeScreen directly: avoids the notification permission dialog that
    // tapping "Começar" would raise (which a widget test can't dismiss).
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark,
          home: HomeScreen(),
        ),
      ),
    );
    await pumpUntil(tester, find.byType(SpaceCard));
    await tester.pump(const Duration(seconds: 6)); // let card photos load
    await shot('02_home');

    // --- 3) Detail ---------------------------------------------------------
    await tester.tap(find.byType(SpaceCard).first);
    await pumpUntil(tester, find.text('Reputação na web'));
    await tester.pump(const Duration(seconds: 4)); // let the web check load
    await shot('03_detail');

    // Scroll for signals / citations / reviews.
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -520));
    await tester.pump(const Duration(seconds: 1));
    await shot('03b_detail_signals');

    // Back to Home.
    await tester.pageBack();
    await pumpUntil(tester, find.byType(SpaceCard));
    await tester.pump(const Duration(seconds: 1));

    // --- 4) Favorites ------------------------------------------------------
    // Favorite the first card, then open the Favorites screen.
    final heart = find.byIcon(Icons.favorite_border_rounded);
    if (heart.evaluate().isNotEmpty) {
      await tester.tap(heart.first);
      await tester.pump(const Duration(seconds: 1));
    }
    await tester.tap(find.byTooltip('Favoritos'));
    await pumpUntil(tester, find.byType(SpaceCard));
    await tester.pump(const Duration(seconds: 1));
    await shot('04_favorites');
    await tester.pageBack();
    await tester.pump(const Duration(seconds: 1));

    // --- 5) History --------------------------------------------------------
    await tester.tap(find.byTooltip('Histórico'));
    await tester.pump(const Duration(seconds: 3));
    await shot('05_history');
    await tester.pageBack();
    await tester.pump(const Duration(seconds: 1));

    // --- 6) Settings -------------------------------------------------------
    await tester.tap(find.byTooltip('Ajustes'));
    await pumpUntil(tester, find.text('Testar notificação local'));
    await tester.pump(const Duration(seconds: 1));
    await shot('06_settings');

    // --- 7) Notification ---------------------------------------------------
    // Fires a local notification; the banner is captured by simctl.
    await tester.tap(find.text('Testar notificação local'));
    await tester.pump(const Duration(seconds: 2));
    await shot('07_notification');
    debugPrint('SHOT::DONE');
  });

  // Share sheet is a system modal that blocks further taps and the share_plus
  // method channel can throw under the test harness — isolate it so a failure
  // here never affects the screens captured above.
  testWidgets('capture share sheet', (tester) async {
    await dotenv.load(fileName: '.env');
    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
    );
    final prefs = await SharedPreferences.getInstance();
    final overrides = _overrides(prefs);

    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark,
          home: HomeScreen(),
        ),
      ),
    );
    await pumpUntil(tester, find.byType(SpaceCard));
    await tester.tap(find.byType(SpaceCard).first);
    await pumpUntil(tester, find.byIcon(Icons.ios_share_rounded));
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.byIcon(Icons.ios_share_rounded));
    // Marker first so the sheet is captured even if share_plus throws after.
    await shot('08_share');
  });
}
