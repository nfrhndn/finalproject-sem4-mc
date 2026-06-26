import 'package:equatable/equatable.dart';

/// Court entity - represents a court in the domain layer
class Court extends Equatable {
  final int id;
  final String name;
  final String? thumbnail;
  final List<String>? photos;
  final String? about;
  final List<String>? features;
  final String material;
  final double pricePerHour;
  final String pricePerHourFormatted;
  final String address;
  final String? phone;
  final String? status;
  final int? bookingsThisMonth;
  final CourtCity? city;
  final CourtCategory? category;

  const Court({
    required this.id,
    required this.name,
    this.thumbnail,
    this.photos,
    this.about,
    this.features,
    required this.material,
    required this.pricePerHour,
    required this.pricePerHourFormatted,
    required this.address,
    this.phone,
    this.status,
    this.bookingsThisMonth,
    this.city,
    this.category,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        thumbnail,
        photos,
        about,
        features,
        material,
        pricePerHour,
        pricePerHourFormatted,
        address,
        phone,
        status,
        bookingsThisMonth,
        city,
        category,
      ];
}

/// Nested city object for court
class CourtCity extends Equatable {
  final int id;
  final String name;

  const CourtCity({
    required this.id,
    required this.name,
  });

  @override
  List<Object?> get props => [id, name];
}

/// Nested category object for court
class CourtCategory extends Equatable {
  final int id;
  final String name;

  const CourtCategory({
    required this.id,
    required this.name,
  });

  @override
  List<Object?> get props => [id, name];
}
