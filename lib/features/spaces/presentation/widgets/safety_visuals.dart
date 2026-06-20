import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/place_category.dart';
import '../../domain/entities/safety_label.dart';

/// Pure mapping helpers from domain enums to UI affordances. Keeping them here
/// means the domain layer stays free of Flutter dependencies.

Color safetyColor(SafetyLabel label) => switch (label) {
      SafetyLabel.safe => AppColors.safe,
      SafetyLabel.notSafe => AppColors.notSafe,
      SafetyLabel.neutral => AppColors.neutral,
    };

String safetyText(SafetyLabel label) => switch (label) {
      SafetyLabel.safe => 'Safe space',
      SafetyLabel.notSafe => 'Não seguro',
      SafetyLabel.neutral => 'Sinais mistos',
    };

IconData safetyIcon(SafetyLabel label) => switch (label) {
      SafetyLabel.safe => Icons.verified_rounded,
      SafetyLabel.notSafe => Icons.report_gmailerrorred_rounded,
      SafetyLabel.neutral => Icons.help_outline_rounded,
    };

IconData categoryIcon(PlaceCategory category) => switch (category) {
      PlaceCategory.all => Icons.explore_rounded,
      PlaceCategory.restaurant => Icons.restaurant_rounded,
      PlaceCategory.cafe => Icons.local_cafe_rounded,
      PlaceCategory.bar => Icons.local_bar_rounded,
      PlaceCategory.nightClub => Icons.nightlife_rounded,
      PlaceCategory.gym => Icons.fitness_center_rounded,
      PlaceCategory.store => Icons.storefront_rounded,
      PlaceCategory.hotel => Icons.hotel_rounded,
    };
