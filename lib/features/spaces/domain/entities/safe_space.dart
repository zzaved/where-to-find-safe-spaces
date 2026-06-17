import 'package:equatable/equatable.dart';

import 'citation.dart';
import 'review.dart';
import 'safety_label.dart';

/// A place near the user, enriched with its safe-space classification.
class SafeSpace extends Equatable {
  const SafeSpace({
    required this.id,
    required this.googlePlaceId,
    required this.name,
    required this.types,
    required this.lat,
    required this.lng,
    required this.googleRatingsTotal,
    required this.safetyScore,
    required this.safetyLabel,
    required this.positiveSignals,
    required this.negativeSignals,
    required this.webCitations,
    required this.reviews,
    required this.deepChecked,
    this.primaryType,
    this.address,
    this.googleRating,
    this.priceLevel,
    this.website,
    this.googleMapsUri,
    this.phone,
    this.photoName,
    this.classificationSummary,
    this.distanceMeters,
  });

  final String id;
  final String googlePlaceId;
  final String name;
  final String? primaryType;
  final List<String> types;
  final String? address;
  final double lat;
  final double lng;
  final double? googleRating;
  final int googleRatingsTotal;
  final int? priceLevel;
  final String? website;
  final String? googleMapsUri;
  final String? phone;
  final String? photoName;

  final int safetyScore;
  final SafetyLabel safetyLabel;
  final String? classificationSummary;
  final List<String> positiveSignals;
  final List<String> negativeSignals;
  final List<Citation> webCitations;
  final List<Review> reviews;

  /// Whether a deep web-reputation check (Perplexity) has been run yet.
  final bool deepChecked;

  /// Distance from the user, in meters, when this came from a discovery query.
  final int? distanceMeters;

  bool get hasPhoto => photoName != null && photoName!.isNotEmpty;

  /// Human friendly distance, e.g. "120 m" or "1,4 km".
  String? get distanceLabel {
    final meters = distanceMeters;
    if (meters == null) return null;
    if (meters < 1000) return '$meters m';
    final km = (meters / 1000).toStringAsFixed(1).replaceAll('.', ',');
    return '$km km';
  }

  String get categoryLabel {
    final type = primaryType ?? (types.isNotEmpty ? types.first : '');
    return type.replaceAll('_', ' ');
  }

  @override
  List<Object?> get props => [id, googlePlaceId, safetyScore, distanceMeters];
}
