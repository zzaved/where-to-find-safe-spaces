import '../../domain/entities/review.dart';

/// Maps the JSON review payload (camelCase, as cached by the backend) to a
/// [Review] entity.
class ReviewModel extends Review {
  const ReviewModel({
    required super.author,
    required super.authorUri,
    required super.rating,
    required super.text,
    required super.relativeTime,
    required super.sourceUri,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      author: (json['author'] as String?) ?? 'Anônimo',
      authorUri: (json['authorUri'] as String?) ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      text: (json['text'] as String?) ?? '',
      relativeTime: (json['relativeTime'] as String?) ?? '',
      sourceUri: (json['sourceUri'] as String?) ?? '',
    );
  }
}
