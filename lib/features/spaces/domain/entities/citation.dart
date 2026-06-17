import 'package:equatable/equatable.dart';

/// A web source returned by the Perplexity reputation check.
class Citation extends Equatable {
  const Citation({required this.title, required this.url});

  final String title;
  final String url;

  @override
  List<Object?> get props => [title, url];
}
