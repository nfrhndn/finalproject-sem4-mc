import 'package:equatable/equatable.dart';
import 'package:padalpro/domain/entities/court.dart';

class CommunityMatch extends Equatable {
  final int id;
  final String hostUserId;
  final int? bookingId;
  final String matchDate;
  final String dateFormatted;
  final String startTime;
  final String endTime;
  final String timeSlot;
  final int totalHours;
  final int playerCapacity;
  final String skillLevel;
  final String? notes;
  final String status;
  final int participantCount;
  final int shareAmount;
  final String shareAmountFormatted;
  final int? currentUserParticipantId;
  final int? currentUserBillId;
  final String? currentUserBillStatus;
  final Court court;
  final List<MatchParticipant> participants;
  final List<SplitBill> splitBills;
  final String? createdAt;

  const CommunityMatch({
    required this.id,
    required this.hostUserId,
    this.bookingId,
    required this.matchDate,
    required this.dateFormatted,
    required this.startTime,
    required this.endTime,
    required this.timeSlot,
    required this.totalHours,
    required this.playerCapacity,
    required this.skillLevel,
    this.notes,
    required this.status,
    required this.participantCount,
    required this.shareAmount,
    required this.shareAmountFormatted,
    this.currentUserParticipantId,
    this.currentUserBillId,
    this.currentUserBillStatus,
    required this.court,
    required this.participants,
    required this.splitBills,
    this.createdAt,
  });

  bool get isCurrentUserJoined => currentUserParticipantId != null;
  bool get isCurrentUserPaid => currentUserBillStatus == 'paid';
  bool get isFull => participantCount >= playerCapacity;
  bool get canJoin => status == 'open' && !isFull && !isCurrentUserJoined;
  bool get canPay =>
      status == 'pending_payment' &&
      currentUserBillId != null &&
      currentUserBillStatus == 'pending';
  bool get canOpenScoreboard => status == 'paid' || status == 'completed';

  @override
  List<Object?> get props => [
    id,
    hostUserId,
    bookingId,
    matchDate,
    dateFormatted,
    startTime,
    endTime,
    timeSlot,
    totalHours,
    playerCapacity,
    skillLevel,
    notes,
    status,
    participantCount,
    shareAmount,
    shareAmountFormatted,
    currentUserParticipantId,
    currentUserBillId,
    currentUserBillStatus,
    court,
    participants,
    splitBills,
    createdAt,
  ];
}

class MatchParticipant extends Equatable {
  final int id;
  final String userId;
  final String role;
  final String status;
  final String name;
  final String? photoUrl;
  final String? joinedAt;

  const MatchParticipant({
    required this.id,
    required this.userId,
    required this.role,
    required this.status,
    required this.name,
    this.photoUrl,
    this.joinedAt,
  });

  @override
  List<Object?> get props => [
    id,
    userId,
    role,
    status,
    name,
    photoUrl,
    joinedAt,
  ];
}

class SplitBill extends Equatable {
  final int id;
  final int participantId;
  final String userId;
  final int amount;
  final String amountFormatted;
  final String status;
  final String? proofPath;
  final String? paidAt;
  final String name;
  final String? photoUrl;

  const SplitBill({
    required this.id,
    required this.participantId,
    required this.userId,
    required this.amount,
    required this.amountFormatted,
    required this.status,
    this.proofPath,
    this.paidAt,
    required this.name,
    this.photoUrl,
  });

  @override
  List<Object?> get props => [
    id,
    participantId,
    userId,
    amount,
    amountFormatted,
    status,
    proofPath,
    paidAt,
    name,
    photoUrl,
  ];
}
