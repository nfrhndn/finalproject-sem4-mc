import 'package:padalpro/domain/entities/city.dart';

/// City model - represents a city from the API
class CityModel extends City {
  const CityModel({
    required super.id,
    required super.name,
    required super.slug,
    super.photoUrl,
    required super.courtsCount,
  });

  /// Create CityModel from JSON
  factory CityModel.fromJson(Map<String, dynamic> json) {
    return CityModel(
      id: json['id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String,
      photoUrl: json['photo_url'] as String?,
      courtsCount: json['courts_count'] as int? ?? 0,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'photo_url': photoUrl,
      'courts_count': courtsCount,
    };
  }
}
