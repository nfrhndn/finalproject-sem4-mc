import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:padalpro/core/injection/injection_container.dart';
import 'package:padalpro/core/theme/app_colors.dart';
import 'package:padalpro/core/theme/app_text_styles.dart';
import 'package:padalpro/domain/entities/community_match.dart';
import 'package:padalpro/presentation/blocs/auth/auth.dart';
import 'package:padalpro/presentation/blocs/community/community.dart';
import 'package:padalpro/presentation/pages/auth/sign_in_page.dart';
import 'package:padalpro/presentation/pages/scoreboard/scoreboard_page.dart';
import 'package:padalpro/presentation/widgets/community/participant_avatar_stack.dart';
import 'package:padalpro/presentation/widgets/community/player_bill_card.dart';
import 'package:padalpro/presentation/widgets/community/split_bill_status_badge.dart';

class CommunityMatchDetailsPage extends StatefulWidget {
  final int matchId;

  const CommunityMatchDetailsPage({super.key, required this.matchId});

  @override
  State<CommunityMatchDetailsPage> createState() =>
      _CommunityMatchDetailsPageState();
}

class _CommunityMatchDetailsPageState extends State<CommunityMatchDetailsPage> {
  late final CommunityBloc _communityBloc;
  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _communityBloc = sl<CommunityBloc>();
    _communityBloc.add(
      CommunityMatchDetailsFetchRequested(matchId: widget.matchId),
    );
  }

  @override
  void dispose() {
    _communityBloc.close();
    super.dispose();
  }

  bool _isAuthenticated() {
    return context.read<AuthBloc>().state is AuthAuthenticated;
  }

  String? _currentUserId() {
    final state = context.read<AuthBloc>().state;
    return state is AuthAuthenticated ? state.user.id : null;
  }

  Future<bool> _requireLogin() async {
    if (_isAuthenticated()) return true;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SignInPage()),
    );
    return _isAuthenticated();
  }

  Future<void> _joinMatch(CommunityMatch match) async {
    if (!await _requireLogin()) return;
    if (!mounted) return;
    _communityBloc.add(CommunityMatchJoinRequested(matchId: match.id));
  }

  Future<void> _payShare(CommunityMatch match) async {
    if (!await _requireLogin()) return;
    if (!mounted) return;
    final billId = match.currentUserBillId;
    if (billId == null) return;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPickerTile(
                icon: Icons.photo_library_outlined,
                title: 'Choose from gallery',
                source: ImageSource.gallery,
              ),
              _buildPickerTile(
                icon: Icons.photo_camera_outlined,
                title: 'Take a photo',
                source: ImageSource.camera,
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;
    final pickedFile = await _imagePicker.pickImage(
      source: source,
      imageQuality: 80,
    );
    if (pickedFile == null) return;

    _communityBloc.add(
      CommunitySplitBillConfirmRequested(
        billId: billId,
        proofOfPayment: File(pickedFile.path),
      ),
    );
  }

  Widget _buildPickerTile({
    required IconData icon,
    required String title,
    required ImageSource source,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textPrimary),
      title: Text(title, style: AppTextStyles.bodyLargeSemibold),
      onTap: () => Navigator.pop(context, source),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _communityBloc,
      child: BlocConsumer<CommunityBloc, CommunityState>(
        listener: (context, state) {
          if (state is CommunityError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
          if (state is CommunityMatchDetailsLoaded && state.message != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message!)));
          }
        },
        builder: (context, state) {
          final match = _matchFromState(state);
          final isActionLoading = state is CommunityActionLoading;

          return Scaffold(
            backgroundColor: AppColors.background,
            body: match == null
                ? _buildLoadingOrError(state)
                : Stack(
                    children: [
                      SingleChildScrollView(
                        padding: const EdgeInsets.only(bottom: 132),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHero(match),
                            const SizedBox(height: 16),
                            _buildSummary(match),
                            const SizedBox(height: 16),
                            _buildPlayers(match),
                            const SizedBox(height: 16),
                            _buildSplitBills(match),
                          ],
                        ),
                      ),
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 28,
                        child: _buildBottomAction(match, isActionLoading),
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }

  CommunityMatch? _matchFromState(CommunityState state) {
    if (state is CommunityMatchDetailsLoaded) return state.match;
    if (state is CommunityActionLoading) return state.currentMatch;
    if (state is CommunityError) return state.currentMatch;
    return null;
  }

  Widget _buildLoadingOrError(CommunityState state) {
    if (state is CommunityError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 52,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 16),
              Text(
                state.message,
                style: AppTextStyles.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              GestureDetector(
                onTap: () => _communityBloc.add(
                  CommunityMatchDetailsFetchRequested(matchId: widget.matchId),
                ),
                child: Text('Retry', style: AppTextStyles.link),
              ),
            ],
          ),
        ),
      );
    }

    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildHero(CommunityMatch match) {
    final image = match.court.thumbnail;
    return SizedBox(
      height: 360,
      child: Stack(
        fit: StackFit.expand,
        children: [
          image != null
              ? CachedNetworkImage(imageUrl: image, fit: BoxFit.cover)
              : Container(color: AppColors.textPrimary),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.44),
                  Colors.black.withValues(alpha: 0.08),
                  Colors.black.withValues(alpha: 0.62),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_back_rounded),
                        ),
                      ),
                      const Spacer(),
                      SplitBillStatusBadge(status: match.status),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    match.court.name,
                    style: AppTextStyles.white(AppTextStyles.heading1),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${match.court.city?.name ?? 'Unknown city'} | ${match.dateFormatted} | ${match.timeSlot}',
                    style: AppTextStyles.white(AppTextStyles.bodyLarge),
                  ),
                  const SizedBox(height: 14),
                  ParticipantAvatarStack(
                    participants: match.participants,
                    capacity: match.playerCapacity,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(CommunityMatch match) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'Players',
                    '${match.participantCount}/${match.playerCapacity}',
                  ),
                ),
                Expanded(
                  child: _buildInfoItem('Level', _titleCase(match.skillLevel)),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Share',
                    match.shareAmount > 0
                        ? match.shareAmountFormatted
                        : 'After full',
                  ),
                ),
              ],
            ),
            if (match.notes != null && match.notes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Notes', style: AppTextStyles.heading5),
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  match.notes!,
                  style: AppTextStyles.bodyLarge.copyWith(height: 1.45),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.bodyLargeSemibold,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildPlayers(CommunityMatch match) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Players', style: AppTextStyles.heading4),
          const SizedBox(height: 10),
          ...match.participants.map(_buildParticipantRow),
          for (var i = match.participantCount; i < match.playerCapacity; i++)
            _buildEmptyPlayerRow(i + 1),
        ],
      ),
    );
  }

  Widget _buildParticipantRow(MatchParticipant participant) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary,
            backgroundImage: participant.photoUrl == null
                ? null
                : CachedNetworkImageProvider(participant.photoUrl!),
            child: participant.photoUrl == null
                ? Text(
                    participant.name.isNotEmpty
                        ? participant.name[0].toUpperCase()
                        : '?',
                    style: AppTextStyles.heading5,
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              participant.name,
              style: AppTextStyles.bodyLargeSemibold,
            ),
          ),
          if (participant.role == 'host') SplitBillStatusBadge(status: 'host'),
        ],
      ),
    );
  }

  Widget _buildEmptyPlayerRow(int playerNumber) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.background,
            child: Icon(Icons.person_add_alt_1_rounded, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Player $playerNumber slot',
              style: AppTextStyles.bodyLarge,
            ),
          ),
          Text('Open', style: AppTextStyles.captionSemibold),
        ],
      ),
    );
  }

  Widget _buildSplitBills(CommunityMatch match) {
    if (match.splitBills.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            match.status == 'needs_reschedule'
                ? 'This slot is no longer available. The host can cancel and create a new match time.'
                : 'Split bills will appear after the match reaches 4 players.',
            style: AppTextStyles.bodyLarge,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Split Bill', style: AppTextStyles.heading4),
              const Spacer(),
              Text(
                '${match.splitBills.where((bill) => bill.status == 'paid').length}/${match.splitBills.length} paid',
                style: AppTextStyles.captionSemibold,
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...match.splitBills.map((bill) => PlayerBillCard(bill: bill)),
        ],
      ),
    );
  }

  Widget _buildBottomAction(CommunityMatch match, bool isActionLoading) {
    final currentUserId = _currentUserId();
    final isHost = currentUserId != null && currentUserId == match.hostUserId;

    if (isActionLoading) {
      return _buildPrimaryAction(
        label: 'Processing...',
        icon: Icons.hourglass_top_rounded,
        onTap: null,
      );
    }

    if (match.canJoin) {
      return _buildPrimaryAction(
        label: 'Join Match',
        icon: Icons.group_add_outlined,
        onTap: () => _joinMatch(match),
      );
    }

    if (match.canPay) {
      return _buildPrimaryAction(
        label: 'Pay Your Share',
        icon: Icons.upload_file_outlined,
        onTap: () => _payShare(match),
      );
    }

    if (match.canOpenScoreboard) {
      return _buildPrimaryAction(
        label: 'Open Scoreboard',
        icon: Icons.scoreboard_outlined,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ScoreboardPage()),
          );
        },
      );
    }

    if (isHost &&
        (match.status == 'open' ||
            match.status == 'pending_payment' ||
            match.status == 'needs_reschedule')) {
      return _buildPrimaryAction(
        label: 'Cancel Match',
        icon: Icons.cancel_outlined,
        onTap: () => _communityBloc.add(
          CommunityMatchCancelRequested(matchId: match.id),
        ),
      );
    }

    return _buildPrimaryAction(
      label: match.isCurrentUserJoined
          ? 'Waiting for players'
          : 'Login to join or pay',
      icon: Icons.lock_outline_rounded,
      onTap: match.isCurrentUserJoined ? null : () => _requireLogin(),
    );
  }

  Widget _buildPrimaryAction({
    required String label,
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: onTap == null ? AppColors.textSecondary : AppColors.primary,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.textPrimary),
            const SizedBox(width: 10),
            Text(label, style: AppTextStyles.buttonLarge),
          ],
        ),
      ),
    );
  }

  String _titleCase(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }
}
