import 'package:padalpro/data/models/court_model.dart';
import 'package:padalpro/domain/entities/community_match.dart';

class CommunityMatchModel extends CommunityMatch {
  const CommunityMatchModel({
    required super.id,
    required super.hostUserId,
    super.bookingId,
    required super.matchDate,
    required super.dateFormatted,
    required super.startTime,
    required super.endTime,
    required super.timeSlot,
    required super.totalHours,
    required super.playerCapacity,
    required super.skillLevel,
    super.notes,
    required super.status,
    required super.participantCount,
    required super.shareAmount,
    required super.shareAmountFormatted,
    super.currentUserParticipantId,
    super.currentUserBillId,
    super.currentUserBillStatus,
    required super.court,
    required super.participants,
    required super.splitBills,
    super.createdAt,
  });

  factory CommunityMatchModel.fromJson(Map<String, dynamic> json) {
    return CommunityMatchModel(
      id: (json['id'] as num).toInt(),
      hostUserId: json['host_user_id'] as String,
      bookingId: (json['booking_id'] as num?)?.toInt(),
      matchDate: json['match_date'] as String,
      dateFormatted:
          json['date_formatted'] as String? ?? json['match_date'] as String,
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      timeSlot: json['time_slot'] as String,
      totalHours: (json['total_hours'] as num).toInt(),
      playerCapacity: (json['player_capacity'] as num).toInt(),
      skillLevel: json['skill_level'] as String,
      notes: json['notes'] as String?,
      status: json['status'] as String,
      participantCount: (json['participant_count'] as num?)?.toInt() ?? 0,
      shareAmount: (json['share_amount'] as num?)?.toInt() ?? 0,
      shareAmountFormatted:
          json['share_amount_formatted'] as String? ??
          _formatRupiah((json['share_amount'] as num?)?.toInt() ?? 0),
      currentUserParticipantId: (json['current_user_participant_id'] as num?)
          ?.toInt(),
      currentUserBillId: (json['current_user_bill_id'] as num?)?.toInt(),
      currentUserBillStatus: json['current_user_bill_status'] as String?,
      court: CourtModel.fromJson(json['court'] as Map<String, dynamic>),
      participants: (json['participants'] as List<dynamic>? ?? [])
          .map(
            (item) =>
                MatchParticipantModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      splitBills: (json['split_bills'] as List<dynamic>? ?? [])
          .map((item) => SplitBillModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      createdAt: json['created_at'] as String?,
    );
  }

  static String _formatRupiah(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(digits[i]);
    }
    return 'Rp $buffer';
  }
}

class MatchParticipantModel extends MatchParticipant {
  const MatchParticipantModel({
    required super.id,
    required super.userId,
    required super.role,
    required super.status,
    required super.name,
    super.photoUrl,
    super.joinedAt,
  });

  factory MatchParticipantModel.fromJson(Map<String, dynamic> json) {
    return MatchParticipantModel(
      id: (json['id'] as num).toInt(),
      userId: json['user_id'] as String,
      role: json['role'] as String,
      status: json['status'] as String,
      name: json['name'] as String? ?? 'PadalPro Player',
      photoUrl: json['photo_url'] as String?,
      joinedAt: json['joined_at'] as String?,
    );
  }
}

class SplitBillModel extends SplitBill {
  const SplitBillModel({
    required super.id,
    required super.participantId,
    required super.userId,
    required super.amount,
    required super.amountFormatted,
    required super.status,
    super.proofPath,
    super.paidAt,
    required super.name,
    super.photoUrl,
  });

  factory SplitBillModel.fromJson(Map<String, dynamic> json) {
    final amount = (json['amount'] as num?)?.toInt() ?? 0;
    return SplitBillModel(
      id: (json['id'] as num).toInt(),
      participantId: (json['participant_id'] as num).toInt(),
      userId: json['user_id'] as String,
      amount: amount,
      amountFormatted:
          json['amount_formatted'] as String? ??
          CommunityMatchModel._formatRupiah(amount),
      status: json['status'] as String,
      proofPath: json['proof_path'] as String?,
      paidAt: json['paid_at'] as String?,
      name: json['name'] as String? ?? 'PadalPro Player',
      photoUrl: json['photo_url'] as String?,
    );
  }
}
