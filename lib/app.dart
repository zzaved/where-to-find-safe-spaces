import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/spaces/presentation/screens/onboarding_screen.dart';

/// Root widget. Wires the dark theme and the first screen.
class SafeSpacesApp extends StatelessWidget {
  const SafeSpacesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Safe Spaces',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const OnboardingScreen(),
    );
  }
}
