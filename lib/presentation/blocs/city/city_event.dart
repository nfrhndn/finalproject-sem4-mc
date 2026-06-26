import 'package:equatable/equatable.dart';

/// Base class for all city events
abstract class CityEvent extends Equatable {
  const CityEvent();

  @override
  List<Object?> get props => [];
}

/// Event to fetch all cities
class CitiesFetchRequested extends CityEvent {
  /// If true, skips loading state to avoid UI blink during refresh
  final bool isRefresh;

  const CitiesFetchRequested({this.isRefresh = false});

  @override
  List<Object?> get props => [isRefresh];
}

/// Event to fetch a single city
class CityFetchRequested extends CityEvent {
  final String identifier;

  const CityFetchRequested({required this.identifier});

  @override
  List<Object?> get props => [identifier];
}
