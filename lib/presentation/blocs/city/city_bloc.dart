import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:padbro/domain/repositories/city_repository.dart';
import 'package:padbro/presentation/blocs/city/city_event.dart';
import 'package:padbro/presentation/blocs/city/city_state.dart';

/// BLoC for managing city state
class CityBloc extends Bloc<CityEvent, CityState> {
  final CityRepository _cityRepository;

  CityBloc({required CityRepository cityRepository})
      : _cityRepository = cityRepository,
        super(const CityInitial()) {
    on<CitiesFetchRequested>(_onCitiesFetchRequested);
    on<CityFetchRequested>(_onCityFetchRequested);
  }

  /// Handle fetching all cities
  Future<void> _onCitiesFetchRequested(
    CitiesFetchRequested event,
    Emitter<CityState> emit,
  ) async {
    // Skip loading state during refresh to avoid UI blink
    if (!event.isRefresh) {
      emit(const CityLoading());
    }

    final result = await _cityRepository.getCities();

    result.fold(
      (failure) => emit(CityError(message: failure.message)),
      (cities) => emit(CitiesLoaded(cities: cities)),
    );
  }

  /// Handle fetching a single city
  Future<void> _onCityFetchRequested(
    CityFetchRequested event,
    Emitter<CityState> emit,
  ) async {
    emit(const CityLoading());

    final result = await _cityRepository.getCity(event.identifier);

    result.fold(
      (failure) => emit(CityError(message: failure.message)),
      (city) => emit(CityLoaded(city: city)),
    );
  }
}
