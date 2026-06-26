import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:padalpro/domain/repositories/court_repository.dart';
import 'package:padalpro/presentation/blocs/court/court_event.dart';
import 'package:padalpro/presentation/blocs/court/court_state.dart';

/// BLoC for managing court state
class CourtBloc extends Bloc<CourtEvent, CourtState> {
  final CourtRepository _courtRepository;

  CourtBloc({required CourtRepository courtRepository})
      : _courtRepository = courtRepository,
        super(const CourtInitial()) {
    on<FeaturedCourtsFetchRequested>(_onFeaturedCourtsFetchRequested);
    on<PopularCourtsFetchRequested>(_onPopularCourtsFetchRequested);
    on<CourtsFetchRequested>(_onCourtsFetchRequested);
    on<CourtDetailsFetchRequested>(_onCourtDetailsFetchRequested);
  }

  /// Handle fetching featured courts
  Future<void> _onFeaturedCourtsFetchRequested(
    FeaturedCourtsFetchRequested event,
    Emitter<CourtState> emit,
  ) async {
    // Skip loading state during refresh to avoid UI blink
    if (!event.isRefresh) {
      emit(const CourtLoading());
    }

    final result = await _courtRepository.getFeaturedCourts(limit: event.limit);

    result.fold(
      (failure) => emit(CourtError(message: failure.message)),
      (courts) => emit(FeaturedCourtsLoaded(courts: courts)),
    );
  }

  /// Handle fetching popular courts
  Future<void> _onPopularCourtsFetchRequested(
    PopularCourtsFetchRequested event,
    Emitter<CourtState> emit,
  ) async {
    emit(const CourtLoading());

    final result = await _courtRepository.getPopularCourts(limit: event.limit);

    result.fold(
      (failure) => emit(CourtError(message: failure.message)),
      (courts) => emit(PopularCourtsLoaded(courts: courts)),
    );
  }

  /// Handle fetching courts with filters (paginated)
  Future<void> _onCourtsFetchRequested(
    CourtsFetchRequested event,
    Emitter<CourtState> emit,
  ) async {
    emit(const CourtLoading());

    final result = await _courtRepository.getCourts(
      cityId: event.cityId,
      categoryId: event.categoryId,
      material: event.material,
      search: event.search,
      minPrice: event.minPrice,
      maxPrice: event.maxPrice,
      perPage: event.perPage,
      page: event.page,
    );

    result.fold(
      (failure) => emit(CourtError(message: failure.message)),
      (response) => emit(CourtsLoaded(
        courts: response.courts,
        pagination: response.pagination,
      )),
    );
  }

  /// Handle fetching court details
  Future<void> _onCourtDetailsFetchRequested(
    CourtDetailsFetchRequested event,
    Emitter<CourtState> emit,
  ) async {
    emit(const CourtLoading());

    final result = await _courtRepository.getCourtDetails(event.id);

    result.fold(
      (failure) => emit(CourtError(message: failure.message)),
      (court) => emit(CourtDetailsLoaded(court: court)),
    );
  }
}
