import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:padalpro/domain/entities/community_match.dart';
import 'package:padalpro/domain/repositories/community_repository.dart';
import 'package:padalpro/presentation/blocs/community/community_event.dart';
import 'package:padalpro/presentation/blocs/community/community_state.dart';

class CommunityBloc extends Bloc<CommunityEvent, CommunityState> {
  final CommunityRepository _communityRepository;

  CommunityBloc({required CommunityRepository communityRepository})
    : _communityRepository = communityRepository,
      super(const CommunityInitial()) {
    on<CommunityMatchesFetchRequested>(_onMatchesFetchRequested);
    on<CommunityMatchDetailsFetchRequested>(_onMatchDetailsFetchRequested);
    on<CommunityOpenMatchCreateRequested>(_onOpenMatchCreateRequested);
    on<CommunityMatchJoinRequested>(_onMatchJoinRequested);
    on<CommunitySplitBillConfirmRequested>(_onSplitBillConfirmRequested);
    on<CommunityMatchCancelRequested>(_onMatchCancelRequested);
  }

  Future<void> _onMatchesFetchRequested(
    CommunityMatchesFetchRequested event,
    Emitter<CommunityState> emit,
  ) async {
    emit(const CommunityLoading());
    final result = await _communityRepository.getMatches(
      status: event.status,
      skillLevel: event.skillLevel,
    );
    result.fold(
      (failure) => emit(CommunityError(message: failure.message)),
      (matches) => emit(CommunityMatchesLoaded(matches: matches)),
    );
  }

  Future<void> _onMatchDetailsFetchRequested(
    CommunityMatchDetailsFetchRequested event,
    Emitter<CommunityState> emit,
  ) async {
    emit(const CommunityLoading());
    final result = await _communityRepository.getMatchDetails(event.matchId);
    result.fold(
      (failure) => emit(CommunityError(message: failure.message)),
      (match) => emit(CommunityMatchDetailsLoaded(match: match)),
    );
  }

  Future<void> _onOpenMatchCreateRequested(
    CommunityOpenMatchCreateRequested event,
    Emitter<CommunityState> emit,
  ) async {
    emit(const CommunityActionLoading());
    final result = await _communityRepository.createOpenMatch(
      courtId: event.courtId,
      date: event.date,
      startHour: event.startHour,
      endHour: event.endHour,
      skillLevel: event.skillLevel,
      notes: event.notes,
    );
    result.fold(
      (failure) => emit(CommunityError(message: failure.message)),
      (match) => emit(
        CommunityMatchDetailsLoaded(
          match: match,
          message: 'Open match created',
        ),
      ),
    );
  }

  Future<void> _onMatchJoinRequested(
    CommunityMatchJoinRequested event,
    Emitter<CommunityState> emit,
  ) async {
    final currentMatch = _currentMatch;
    emit(CommunityActionLoading(currentMatch: currentMatch));
    final result = await _communityRepository.joinMatch(event.matchId);
    result.fold(
      (failure) => emit(
        CommunityError(message: failure.message, currentMatch: currentMatch),
      ),
      (match) => emit(
        CommunityMatchDetailsLoaded(match: match, message: _joinMessage(match)),
      ),
    );
  }

  Future<void> _onSplitBillConfirmRequested(
    CommunitySplitBillConfirmRequested event,
    Emitter<CommunityState> emit,
  ) async {
    final currentMatch = _currentMatch;
    emit(CommunityActionLoading(currentMatch: currentMatch));
    final result = await _communityRepository.confirmSplitBill(
      billId: event.billId,
      proofOfPayment: event.proofOfPayment,
    );
    result.fold(
      (failure) => emit(
        CommunityError(message: failure.message, currentMatch: currentMatch),
      ),
      (match) => emit(
        CommunityMatchDetailsLoaded(
          match: match,
          message: match.status == 'paid'
              ? 'All players paid. Match is confirmed'
              : 'Payment proof submitted',
        ),
      ),
    );
  }

  Future<void> _onMatchCancelRequested(
    CommunityMatchCancelRequested event,
    Emitter<CommunityState> emit,
  ) async {
    final currentMatch = _currentMatch;
    emit(CommunityActionLoading(currentMatch: currentMatch));
    final result = await _communityRepository.cancelMatch(event.matchId);
    result.fold(
      (failure) => emit(
        CommunityError(message: failure.message, currentMatch: currentMatch),
      ),
      (match) => emit(
        CommunityMatchDetailsLoaded(match: match, message: 'Match cancelled'),
      ),
    );
  }

  CommunityMatch? get _currentMatch {
    final currentState = state;
    if (currentState is CommunityMatchDetailsLoaded) {
      return currentState.match;
    }
    if (currentState is CommunityActionLoading) {
      return currentState.currentMatch;
    }
    if (currentState is CommunityError) {
      return currentState.currentMatch;
    }
    return null;
  }

  String _joinMessage(CommunityMatch match) {
    if (match.status == 'pending_payment') {
      return 'Match is full. Split bills are ready';
    }
    if (match.status == 'needs_reschedule') {
      return 'Match is full, but the slot is no longer available';
    }
    return 'Joined match';
  }
}
