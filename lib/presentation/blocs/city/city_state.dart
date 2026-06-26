import 'package:equatable/equatable.dart';
import 'package:padalpro/domain/entities/city.dart';

/// Base class for all city states
abstract class CityState extends Equatable {
  const CityState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class CityInitial extends CityState {
  const CityInitial();
}

/// Loading state
class CityLoading extends CityState {
  const CityLoading();
}

/// Cities loaded successfully
class CitiesLoaded extends CityState {
  final List<City> cities;

  const CitiesLoaded({required this.cities});

  @override
  List<Object?> get props => [cities];
}

/// Single city loaded successfully
class CityLoaded extends CityState {
  final City city;

  const CityLoaded({required this.city});

  @override
  List<Object?> get props => [city];
}

/// Error state
class CityError extends CityState {
  final String message;

  const CityError({required this.message});

  @override
  List<Object?> get props => [message];
}
