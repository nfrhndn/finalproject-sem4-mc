import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:padbro/domain/entities/booking.dart';
import 'package:padbro/domain/repositories/booking_repository.dart';
import 'package:padbro/presentation/blocs/booking/booking_event.dart';
import 'package:padbro/presentation/blocs/booking/booking_state.dart';

/// BLoC for managing booking state
class BookingBloc extends Bloc<BookingEvent, BookingState> {
  final BookingRepository _bookingRepository;

  /// Cached list of bookings for quick access (e.g., from details page)
  List<Booking> _cachedBookings = [];

  BookingBloc({required BookingRepository bookingRepository})
      : _bookingRepository = bookingRepository,
        super(const BookingInitial()) {
    on<NextBookingFetchRequested>(_onNextBookingFetchRequested);
    on<MyBookingsFetchRequested>(_onMyBookingsFetchRequested);
    on<BookingReset>(_onBookingReset);
  }

  /// Find a booking by ID from the cached list
  /// Returns null if not found
  Booking? findById(int id) {
    try {
      return _cachedBookings.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Handle resetting booking state
  void _onBookingReset(
    BookingReset event,
    Emitter<BookingState> emit,
  ) {
    _cachedBookings = [];
    emit(const BookingInitial());
  }

  /// Handle fetching the next booking
  Future<void> _onNextBookingFetchRequested(
    NextBookingFetchRequested event,
    Emitter<BookingState> emit,
  ) async {
    // Skip loading state during refresh to avoid UI blink
    if (!event.isRefresh) {
      emit(const BookingLoading());
    }

    final result = await _bookingRepository.getNextBooking();

    result.fold(
      (failure) => emit(BookingError(message: failure.message)),
      (booking) {
        // Cache the next booking for quick access from details page
        if (booking != null) {
          // Add to cache if not already present
          if (!_cachedBookings.any((b) => b.id == booking.id)) {
            _cachedBookings = [..._cachedBookings, booking];
          }
        }
        emit(NextBookingLoaded(booking: booking));
      },
    );
  }

  /// Handle fetching user's bookings
  Future<void> _onMyBookingsFetchRequested(
    MyBookingsFetchRequested event,
    Emitter<BookingState> emit,
  ) async {
    emit(const BookingLoading());

    final result = await _bookingRepository.getMyBookings(status: event.status);

    result.fold(
      (failure) => emit(BookingError(message: failure.message)),
      (bookings) {
        // Cache the bookings for quick access from details page
        _cachedBookings = bookings;
        emit(MyBookingsLoaded(bookings: bookings));
      },
    );
  }
}
