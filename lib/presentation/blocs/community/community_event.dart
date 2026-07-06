import 'dart:io';

import 'package:equatable/equatable.dart';

abstract class CommunityEvent extends Equatable {
  const CommunityEvent();

  @override
  List<Object?> get props => [];
}

class CommunityMatchesFetchRequested extends CommunityEvent {
  final String? status;
  final String? skillLevel;

  const CommunityMatchesFetchRequested({this.status, this.skillLevel});

  @override
  List<Object?> get props => [status, skillLevel];
}

class CommunityMatchDetailsFetchRequested extends CommunityEvent {
  final int matchId;

  const CommunityMatchDetailsFetchRequested({required this.matchId});

  @override
  List<Object?> get props => [matchId];
}

class CommunityOpenMatchCreateRequested extends CommunityEvent {
  final int courtId;
  final String date;
  final int startHour;
  final int endHour;
  final String skillLevel;
  final String? notes;

  const CommunityOpenMatchCreateRequested({
    required this.courtId,
    required this.date,
    required this.startHour,
    required this.endHour,
    required this.skillLevel,
    this.notes,
  });

  @override
  List<Object?> get props => [
    courtId,
    date,
    startHour,
    endHour,
    skillLevel,
    notes,
  ];
}

class CommunityMatchJoinRequested extends CommunityEvent {
  final int matchId;

  const CommunityMatchJoinRequested({required this.matchId});

  @override
  List<Object?> get props => [matchId];
}

class CommunitySplitBillConfirmRequested extends CommunityEvent {
  final int billId;
  final File proofOfPayment;

  const CommunitySplitBillConfirmRequested({
    required this.billId,
    required this.proofOfPayment,
  });

  @override
  List<Object?> get props => [billId, proofOfPayment.path];
}

class CommunityMatchCancelRequested extends CommunityEvent {
  final int matchId;

  const CommunityMatchCancelRequested({required this.matchId});

  @override
  List<Object?> get props => [matchId];
}
