import 'package:equatable/equatable.dart';

/// A single user review for a place, with a link back to its public source.
class Review extends Equatable {
  const Review({
    required this.author,
    required this.authorUri,
    required this.rating,
    required this.text,
    required this.relativeTime,
    required this.sourceUri,
  });

  final String author;
  final String authorUri;
  final double rating;
  final String text;
  final String relativeTime;

  /// Public URL where this review can be read in full.
  final String sourceUri;

  bool get hasSource => sourceUri.isNotEmpty;

  @override
  List<Object?> get props => [author, text, rating, sourceUri];
}
