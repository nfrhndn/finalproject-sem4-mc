import 'package:padalpro/domain/entities/court.dart';

/// Court model - represents a court from the API
class CourtModel extends Court {
  const CourtModel({
    required super.id,
    required super.name,
    super.thumbnail,
    super.photos,
    super.about,
    super.features,
    required super.material,
    required super.pricePerHour,
    required super.pricePerHourFormatted,
    required super.address,
    super.phone,
    super.status,
    super.bookingsThisMonth,
    super.city,
    super.category,
  });

  /// Create CourtModel from JSON
  factory CourtModel.fromJson(Map<String, dynamic> json) {
    return CourtModel(
      id: json['id'] as int,
      name: json['name'] as String,
      thumbnail: json['thumbnail'] as String?,
      photos: json['photos'] != null
          ? List<String>.from(json['photos'] as List)
          : null,
      about: json['about'] as String?,
      features: json['features'] != null
          ? List<String>.from(json['features'] as List)
          : null,
      material: json['material'] as String,
      pricePerHour: _parseDouble(json['price_per_hour']),
      pricePerHourFormatted: json['price_per_hour_formatted'] as String,
      address: json['address'] as String,
      phone: json['phone'] as String?,
      status: json['status'] as String?,
      bookingsThisMonth: json['bookings_this_month'] as int?,
      city: json['city'] != null
          ? CourtCityModel.fromJson(json['city'] as Map<String, dynamic>)
          : null,
      category: json['category'] != null
          ? CourtCategoryModel.fromJson(json['category'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Parse price which can be either String or num
  static double _parseDouble(dynamic value) {
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    } else if (value is num) {
      return value.toDouble();
    }
    return 0.0;
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'thumbnail': thumbnail,
      'photos': photos,
      'about': about,
      'features': features,
      'material': material,
      'price_per_hour': pricePerHour,
      'price_per_hour_formatted': pricePerHourFormatted,
      'address': address,
      'phone': phone,
      'status': status,
      'bookings_this_month': bookingsThisMonth,
      'city': city != null
          ? {'id': city!.id, 'name': city!.name}
          : null,
      'category': category != null
          ? {'id': category!.id, 'name': category!.name}
          : null,
    };
  }
}

/// Court city model
class CourtCityModel extends CourtCity {
  const CourtCityModel({
    required super.id,
    required super.name,
  });

  factory CourtCityModel.fromJson(Map<String, dynamic> json) {
    return CourtCityModel(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}

/// Court category model
class CourtCategoryModel extends CourtCategory {
  const CourtCategoryModel({
    required super.id,
    required super.name,
  });

  factory CourtCategoryModel.fromJson(Map<String, dynamic> json) {
    return CourtCategoryModel(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}
