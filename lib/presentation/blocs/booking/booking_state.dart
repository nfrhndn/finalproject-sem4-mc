import 'package:equatable/equatable.dart';
import 'package:padbro/domain/entities/booking.dart';

/// Base class for all booking states
abstract class BookingState extends Equatable {
  const BookingState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class BookingInitial extends BookingState {
  const BookingInitial();
}

/// Loading state
class BookingLoading extends BookingState {
  const BookingLoading();
}

/// Next booking loaded successfully (can be null if no booking)
class NextBookingLoaded extends BookingState {
  final Booking? booking;

  const NextBookingLoaded({this.booking});

  @override
  List<Object?> get props => [booking];
}

/// My bookings loaded successfully
class MyBookingsLoaded extends BookingState {
  final List<Booking> bookings;

  const MyBookingsLoaded({required this.bookings});

  @override
  List<Object?> get props => [bookings];
}

/// Error state
class BookingError extends BookingState {
  final String message;

  const BookingError({required this.message});

  @override
  List<Object?> get props => [message];
}
