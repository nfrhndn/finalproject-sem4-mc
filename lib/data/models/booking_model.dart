import 'package:padalpro/domain/entities/booking.dart';

/// Booking model - represents a booking from the API
class BookingModel extends Booking {
  const BookingModel({
    required super.id,
    required super.date,
    required super.dateFormatted,
    required super.startTime,
    required super.endTime,
    required super.timeSlot,
    required super.totalHours,
    required super.pricePerHour,
    required super.subTotal,
    required super.taxAmount,
    required super.grandTotal,
    required super.grandTotalFormatted,
    required super.status,
    required super.court,
    required super.createdAt,
  });

  /// Create BookingModel from JSON
  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: (json['id'] as num).toInt(),
      date: json['date'] as String,
      dateFormatted: json['date_formatted'] as String,
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      timeSlot: json['time_slot'] as String,
      totalHours: (json['total_hours'] as num).toInt(),
      pricePerHour: (json['price_per_hour'] as num).toInt(),
      subTotal: (json['sub_total'] as num).toInt(),
      taxAmount: (json['tax_amount'] as num).toInt(),
      grandTotal: (json['grand_total'] as num).toInt(),
      grandTotalFormatted: json['grand_total_formatted'] as String,
      status: json['status'] as String,
      court: BookingCourtModel.fromJson(json['court'] as Map<String, dynamic>),
      createdAt: json['created_at'] as String,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'date_formatted': dateFormatted,
      'start_time': startTime,
      'end_time': endTime,
      'time_slot': timeSlot,
      'total_hours': totalHours,
      'price_per_hour': pricePerHour,
      'sub_total': subTotal,
      'tax_amount': taxAmount,
      'grand_total': grandTotal,
      'grand_total_formatted': grandTotalFormatted,
      'status': status,
      'court': {
        'id': court.id,
        'name': court.name,
        'thumbnail': court.thumbnail,
        'material': court.material,
        'address': court.address,
        'phone': court.phone,
        'city': court.city != null
            ? {'id': court.city!.id, 'name': court.city!.name}
            : null,
        'category': court.category != null
            ? {'id': court.category!.id, 'name': court.category!.name}
            : null,
      },
      'created_at': createdAt,
    };
  }
}

/// Booking court model
class BookingCourtModel extends BookingCourt {
  const BookingCourtModel({
    required super.id,
    required super.name,
    super.thumbnail,
    required super.material,
    required super.address,
    super.phone,
    super.city,
    super.category,
  });

  factory BookingCourtModel.fromJson(Map<String, dynamic> json) {
    return BookingCourtModel(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      thumbnail: json['thumbnail'] as String?,
      material: json['material'] as String,
      address: json['address'] as String,
      phone: json['phone'] as String?,
      city: json['city'] != null
          ? BookingCourtCityModel.fromJson(json['city'] as Map<String, dynamic>)
          : null,
      category: json['category'] != null
          ? BookingCourtCategoryModel.fromJson(json['category'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Booking court city model
class BookingCourtCityModel extends BookingCourtCity {
  const BookingCourtCityModel({
    required super.id,
    required super.name,
  });

  factory BookingCourtCityModel.fromJson(Map<String, dynamic> json) {
    return BookingCourtCityModel(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
    );
  }
}

/// Booking court category model
class BookingCourtCategoryModel extends BookingCourtCategory {
  const BookingCourtCategoryModel({
    required super.id,
    required super.name,
  });

  factory BookingCourtCategoryModel.fromJson(Map<String, dynamic> json) {
    return BookingCourtCategoryModel(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
    );
  }
}
