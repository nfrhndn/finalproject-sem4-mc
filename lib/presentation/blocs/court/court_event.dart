import 'package:equatable/equatable.dart';

/// Base class for all court events
abstract class CourtEvent extends Equatable {
  const CourtEvent();

  @override
  List<Object?> get props => [];
}

/// Event to fetch featured courts
class FeaturedCourtsFetchRequested extends CourtEvent {
  final int? limit;
  /// If true, skips loading state to avoid UI blink during refresh
  final bool isRefresh;

  const FeaturedCourtsFetchRequested({this.limit, this.isRefresh = false});

  @override
  List<Object?> get props => [limit, isRefresh];
}

/// Event to fetch popular courts
class PopularCourtsFetchRequested extends CourtEvent {
  final int? limit;

  const PopularCourtsFetchRequested({this.limit});

  @override
  List<Object?> get props => [limit];
}

/// Event to fetch courts with filters (paginated)
class CourtsFetchRequested extends CourtEvent {
  final int? cityId;
  final int? categoryId;
  final String? material;
  final String? search;
  final int? minPrice;
  final int? maxPrice;
  final int? perPage;
  final int? page;

  const CourtsFetchRequested({
    this.cityId,
    this.categoryId,
    this.material,
    this.search,
    this.minPrice,
    this.maxPrice,
    this.perPage,
    this.page,
  });

  @override
  List<Object?> get props => [
        cityId,
        categoryId,
        material,
        search,
        minPrice,
        maxPrice,
        perPage,
        page,
      ];
}

/// Event to fetch court details
class CourtDetailsFetchRequested extends CourtEvent {
  final int id;

  const CourtDetailsFetchRequested({required this.id});

  @override
  List<Object?> get props => [id];
}
