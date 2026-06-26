import 'package:equatable/equatable.dart';
import 'package:padalpro/data/datasources/court_remote_datasource.dart';
import 'package:padalpro/domain/entities/court.dart';

/// Base class for all court states
abstract class CourtState extends Equatable {
  const CourtState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class CourtInitial extends CourtState {
  const CourtInitial();
}

/// Loading state
class CourtLoading extends CourtState {
  const CourtLoading();
}

/// Featured courts loaded successfully
class FeaturedCourtsLoaded extends CourtState {
  final List<Court> courts;

  const FeaturedCourtsLoaded({required this.courts});

  @override
  List<Object?> get props => [courts];
}

/// Popular courts loaded successfully
class PopularCourtsLoaded extends CourtState {
  final List<Court> courts;

  const PopularCourtsLoaded({required this.courts});

  @override
  List<Object?> get props => [courts];
}

/// Courts list loaded successfully (with pagination)
class CourtsLoaded extends CourtState {
  final List<Court> courts;
  final PaginationInfo pagination;

  const CourtsLoaded({
    required this.courts,
    required this.pagination,
  });

  bool get hasMorePages => pagination.hasMorePages;

  @override
  List<Object?> get props => [courts, pagination];
}

/// Court details loaded successfully
class CourtDetailsLoaded extends CourtState {
  final Court court;

  const CourtDetailsLoaded({required this.court});

  @override
  List<Object?> get props => [court];
}

/// Error state
class CourtError extends CourtState {
  final String message;

  const CourtError({required this.message});

  @override
  List<Object?> get props => [message];
}
