import '../../domain/entities/safe_space.dart';
import '../../domain/entities/safety_label.dart';
import 'citation_model.dart';
import 'review_model.dart';

/// Maps a `places` row (as returned by the `spaces` edge function) to a
/// [SafeSpace] entity.
class SafeSpaceModel extends SafeSpace {
  const SafeSpaceModel({
    required super.id,
    required super.googlePlaceId,
    required super.name,
    required super.types,
    required super.lat,
    required super.lng,
    required super.googleRatingsTotal,
    required super.safetyScore,
    required super.safetyLabel,
    required super.positiveSignals,
    required super.negativeSignals,
    required super.webCitations,
    required super.reviews,
    required super.deepChecked,
    super.primaryType,
    super.address,
    super.googleRating,
    super.priceLevel,
    super.website,
    super.googleMapsUri,
    super.phone,
    super.photoName,
    super.classificationSummary,
    super.distanceMeters,
  });

  factory SafeSpaceModel.fromJson(Map<String, dynamic> json) {
    return SafeSpaceModel(
      id: json['id'] as String,
      googlePlaceId: json['google_place_id'] as String,
      name: (json['name'] as String?) ?? 'Local sem nome',
      primaryType: json['primary_type'] as String?,
      types: _stringList(json['types']),
      address: json['address'] as String?,
      lat: (json['lat'] as num?)?.toDouble() ?? 0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0,
      googleRating: (json['google_rating'] as num?)?.toDouble(),
      googleRatingsTotal: (json['google_ratings_total'] as num?)?.toInt() ?? 0,
      priceLevel: (json['price_level'] as num?)?.toInt(),
      website: json['website'] as String?,
      googleMapsUri: json['google_maps_uri'] as String?,
      phone: json['phone'] as String?,
      photoName: json['photo_name'] as String?,
      safetyScore: (json['safety_score'] as num?)?.toInt() ?? 50,
      safetyLabel: SafetyLabel.fromApi(json['safety_label'] as String?),
      classificationSummary: json['classification_summary'] as String?,
      positiveSignals: _stringList(json['positive_signals']),
      negativeSignals: _stringList(json['negative_signals']),
      webCitations: _citations(json['web_citations']),
      reviews: _reviews(json['reviews']),
      deepChecked: (json['deep_checked'] as bool?) ?? false,
      distanceMeters: (json['distance_m'] as num?)?.toInt(),
    );
  }

  static List<String> _stringList(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return const [];
  }

  static List<CitationModel> _citations(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map((e) => CitationModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return const [];
  }

  static List<ReviewModel> _reviews(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map((e) => ReviewModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return const [];
  }
}
