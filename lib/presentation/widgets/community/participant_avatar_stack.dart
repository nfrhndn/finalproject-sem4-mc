import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:padalpro/core/theme/app_colors.dart';
import 'package:padalpro/core/theme/app_text_styles.dart';
import 'package:padalpro/domain/entities/community_match.dart';

class ParticipantAvatarStack extends StatelessWidget {
  final List<MatchParticipant> participants;
  final int capacity;

  const ParticipantAvatarStack({
    super.key,
    required this.participants,
    required this.capacity,
  });

  @override
  Widget build(BuildContext context) {
    final visible = participants.take(4).toList();
    return SizedBox(
      width: 92,
      height: 32,
      child: Stack(
        children: [
          for (var i = 0; i < visible.length; i++)
            Positioned(
              left: i * 20,
              child: _Avatar(participant: visible[i]),
            ),
          for (var i = visible.length; i < capacity && i < 4; i++)
            Positioned(left: i * 20, child: const _EmptyAvatar()),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final MatchParticipant participant;

  const _Avatar({required this.participant});

  @override
  Widget build(BuildContext context) {
    final initial = participant.name.isNotEmpty
        ? participant.name[0].toUpperCase()
        : '?';
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: participant.photoUrl != null
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: participant.photoUrl!,
                fit: BoxFit.cover,
              ),
            )
          : Center(child: Text(initial, style: AppTextStyles.captionSemibold)),
    );
  }
}

class _EmptyAvatar extends StatelessWidget {
  const _EmptyAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.background,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: const Icon(
        Icons.person_add_alt_1_rounded,
        size: 14,
        color: AppColors.textSecondary,
      ),
    );
  }
}
