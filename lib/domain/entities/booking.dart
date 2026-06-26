import 'package:equatable/equatable.dart';

/// Booking entity - represents a booking in the domain layer
class Booking extends Equatable {
  final int id;
  final String date;
  final String dateFormatted;
  final String startTime;
  final String endTime;
  final String timeSlot;
  final int totalHours;
  final int pricePerHour;
  final int subTotal;
  final int taxAmount;
  final int grandTotal;
  final String grandTotalFormatted;
  final String status;
  final BookingCourt court;
  final String createdAt;

  const Booking({
    required this.id,
    required this.date,
    required this.dateFormatted,
    required this.startTime,
    required this.endTime,
    required this.timeSlot,
    required this.totalHours,
    required this.pricePerHour,
    required this.subTotal,
    required this.taxAmount,
    required this.grandTotal,
    required this.grandTotalFormatted,
    required this.status,
    required this.court,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        date,
        dateFormatted,
        startTime,
        endTime,
        timeSlot,
        totalHours,
        pricePerHour,
        subTotal,
        taxAmount,
        grandTotal,
        grandTotalFormatted,
        status,
        court,
        createdAt,
      ];
}

/// Nested court object for booking
class BookingCourt extends Equatable {
  final int id;
  final String name;
  final String? thumbnail;
  final String material;
  final String address;
  final String? phone;
  final BookingCourtCity? city;
  final BookingCourtCategory? category;

  const BookingCourt({
    required this.id,
    required this.name,
    this.thumbnail,
    required this.material,
    required this.address,
    this.phone,
    this.city,
    this.category,
  });

  @override
  List<Object?> get props => [id, name, thumbnail, material, address, phone, city, category];
}

/// Nested city object for booking court
class BookingCourtCity extends Equatable {
  final int id;
  final String name;

  const BookingCourtCity({
    required this.id,
    required this.name,
  });

  @override
  List<Object?> get props => [id, name];
}

/// Nested category object for booking court
class BookingCourtCategory extends Equatable {
  final int id;
  final String name;

  const BookingCourtCategory({
    required this.id,
    required this.name,
  });

  @override
  List<Object?> get props => [id, name];
}
