import 'package:equatable/equatable.dart';
import 'package:padalpro/domain/entities/community_match.dart';

abstract class CommunityState extends Equatable {
  const CommunityState();

  @override
  List<Object?> get props => [];
}

class CommunityInitial extends CommunityState {
  const CommunityInitial();
}

class CommunityLoading extends CommunityState {
  const CommunityLoading();
}

class CommunityActionLoading extends CommunityState {
  final CommunityMatch? currentMatch;

  const CommunityActionLoading({this.currentMatch});

  @override
  List<Object?> get props => [currentMatch];
}

class CommunityMatchesLoaded extends CommunityState {
  final List<CommunityMatch> matches;

  const CommunityMatchesLoaded({required this.matches});

  @override
  List<Object?> get props => [matches];
}

class CommunityMatchDetailsLoaded extends CommunityState {
  final CommunityMatch match;
  final String? message;

  const CommunityMatchDetailsLoaded({required this.match, this.message});

  @override
  List<Object?> get props => [match, message];
}

class CommunityError extends CommunityState {
  final String message;
  final CommunityMatch? currentMatch;

  const CommunityError({required this.message, this.currentMatch});

  @override
  List<Object?> get props => [message, currentMatch];
}
