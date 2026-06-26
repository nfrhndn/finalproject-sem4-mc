import 'package:equatable/equatable.dart';

/// Base class for all booking events
abstract class BookingEvent extends Equatable {
  const BookingEvent();

  @override
  List<Object?> get props => [];
}

/// Event to fetch the next upcoming booking
class NextBookingFetchRequested extends BookingEvent {
  /// If true, skips loading state to avoid UI blink during refresh
  final bool isRefresh;

  const NextBookingFetchRequested({this.isRefresh = false});

  @override
  List<Object?> get props => [isRefresh];
}

/// Event to fetch user's bookings with optional status filter
class MyBookingsFetchRequested extends BookingEvent {
  final String? status;

  const MyBookingsFetchRequested({this.status});

  @override
  List<Object?> get props => [status];
}

/// Event to reset booking state (e.g., on logout)
class BookingReset extends BookingEvent {
  const BookingReset();
}
