import '../../domain/entities/citation.dart';

/// Maps a `{title, url}` JSON object to a [Citation] entity.
class CitationModel extends Citation {
  const CitationModel({required super.title, required super.url});

  factory CitationModel.fromJson(Map<String, dynamic> json) {
    final url = (json['url'] as String?) ?? '';
    return CitationModel(
      title: (json['title'] as String?)?.trim().isNotEmpty == true
          ? json['title'] as String
          : url,
      url: url,
    );
  }
}
