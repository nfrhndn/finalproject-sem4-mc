import 'package:equatable/equatable.dart';

/// City entity - represents a city in the domain layer
class City extends Equatable {
  final int id;
  final String name;
  final String slug;
  final String? photoUrl;
  final int courtsCount;

  const City({
    required this.id,
    required this.name,
    required this.slug,
    this.photoUrl,
    required this.courtsCount,
  });

  @override
  List<Object?> get props => [id, name, slug, photoUrl, courtsCount];
}
