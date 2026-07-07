import 'package:padalpro/core/errors/exceptions.dart';
import 'package:padalpro/core/storage/storage_upload.dart';
import 'package:padalpro/data/models/community_match_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

abstract class CommunityRemoteDataSource {
  Future<List<CommunityMatchModel>> getMatches({
    String? status,
    String? skillLevel,
  });

  Future<CommunityMatchModel> getMatchDetails(int matchId);

  Future<CommunityMatchModel> createOpenMatch({
    required int courtId,
    required String date,
    required int startHour,
    required int endHour,
    required String skillLevel,
    String? notes,
  });

  Future<CommunityMatchModel> joinMatch(int matchId);

  Future<CommunityMatchModel> confirmSplitBill({
    required int billId,
    required XFile proofOfPayment,
  });

  Future<CommunityMatchModel> cancelMatch(int matchId);
}

class CommunityRemoteDataSourceImpl implements CommunityRemoteDataSource {
  final SupabaseClient _supabaseClient;

  CommunityRemoteDataSourceImpl({required SupabaseClient supabaseClient})
    : _supabaseClient = supabaseClient;

  @override
  Future<List<CommunityMatchModel>> getMatches({
    String? status,
    String? skillLevel,
  }) async {
    try {
      final params = <String, dynamic>{
        'p_status': ?status,
        'p_skill_level': ?skillLevel,
      };
      final data = params.isEmpty
          ? await _supabaseClient.rpc('get_community_matches')
          : await _supabaseClient.rpc('get_community_matches', params: params);

      return _asList(data)
          .map((json) => CommunityMatchModel.fromJson(_asStringKeyMap(json)))
          .toList();
    } catch (e) {
      throw _communityException(
        error: e,
        fallback: 'Failed to load community matches',
      );
    }
  }

  @override
  Future<CommunityMatchModel> getMatchDetails(int matchId) async {
    try {
      final data = await _supabaseClient.rpc(
        'get_community_match_detail',
        params: {'p_match_id': matchId},
      );
      return CommunityMatchModel.fromJson(_asStringKeyMap(data));
    } catch (e) {
      throw _communityException(
        error: e,
        fallback: 'Failed to load match details',
      );
    }
  }

  @override
  Future<CommunityMatchModel> createOpenMatch({
    required int courtId,
    required String date,
    required int startHour,
    required int endHour,
    required String skillLevel,
    String? notes,
  }) async {
    if (_supabaseClient.auth.currentUser == null) {
      throw const AuthException(message: 'Please sign in to create a match');
    }

    try {
      final data = await _supabaseClient.rpc(
        'create_open_match',
        params: {
          'p_court_id': courtId,
          'p_match_date': date,
          'p_start_hour': startHour,
          'p_end_hour': endHour,
          'p_skill_level': skillLevel,
          'p_notes': notes,
        },
      );
      return CommunityMatchModel.fromJson(_asStringKeyMap(data));
    } on AuthException {
      rethrow;
    } catch (e) {
      throw _communityException(
        error: e,
        fallback: 'Failed to create open match',
      );
    }
  }

  @override
  Future<CommunityMatchModel> joinMatch(int matchId) async {
    if (_supabaseClient.auth.currentUser == null) {
      throw const AuthException(message: 'Please sign in to join this match');
    }

    try {
      final data = await _supabaseClient.rpc(
        'join_open_match',
        params: {'p_match_id': matchId},
      );
      return CommunityMatchModel.fromJson(_asStringKeyMap(data));
    } on AuthException {
      rethrow;
    } catch (e) {
      throw _communityException(error: e, fallback: 'Failed to join match');
    }
  }

  @override
  Future<CommunityMatchModel> confirmSplitBill({
    required int billId,
    required XFile proofOfPayment,
  }) async {
    final userId = _supabaseClient.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthException(message: 'Please sign in to pay your share');
    }

    try {
      final extension = pickedFileExtension(proofOfPayment);
      final objectPath =
          '$userId/split-$billId-${DateTime.now().millisecondsSinceEpoch}.$extension';
      await uploadPickedFile(
        client: _supabaseClient,
        bucket: 'payment-proofs',
        objectPath: objectPath,
        file: proofOfPayment,
      );

      final data = await _supabaseClient.rpc(
        'confirm_split_bill',
        params: {'p_bill_id': billId, 'p_proof_path': objectPath},
      );
      return CommunityMatchModel.fromJson(_asStringKeyMap(data));
    } on AuthException {
      rethrow;
    } catch (e) {
      throw _communityException(
        error: e,
        fallback: 'Failed to confirm split bill',
      );
    }
  }

  @override
  Future<CommunityMatchModel> cancelMatch(int matchId) async {
    if (_supabaseClient.auth.currentUser == null) {
      throw const AuthException(message: 'Please sign in to cancel this match');
    }

    try {
      final data = await _supabaseClient.rpc(
        'cancel_community_match',
        params: {'p_match_id': matchId},
      );
      return CommunityMatchModel.fromJson(_asStringKeyMap(data));
    } on AuthException {
      rethrow;
    } catch (e) {
      throw _communityException(error: e, fallback: 'Failed to cancel match');
    }
  }

  ServerException _communityException({
    required Object error,
    required String fallback,
  }) {
    if (error is PostgrestException && error.code == 'PGRST202') {
      return const ServerException(
        message:
            'Community backend belum tersedia. Jalankan migration supabase/migrations/202607060001_community_open_match_split_bill.sql di Supabase SQL Editor, lalu tunggu schema refresh dan buka ulang aplikasi.',
      );
    }
    return ServerException(message: '$fallback: $error');
  }

  Map<String, dynamic> _asStringKeyMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    throw ServerException(message: 'Unexpected Supabase response: $value');
  }

  List<dynamic> _asList(dynamic value) {
    if (value is List<dynamic>) return value;
    if (value is List) return List<dynamic>.from(value);
    throw ServerException(message: 'Unexpected Supabase response: $value');
  }
}
