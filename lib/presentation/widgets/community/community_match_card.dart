import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:padalpro/core/theme/app_colors.dart';
import 'package:padalpro/core/theme/app_text_styles.dart';
import 'package:padalpro/domain/entities/community_match.dart';
import 'package:padalpro/presentation/widgets/community/participant_avatar_stack.dart';
import 'package:padalpro/presentation/widgets/community/split_bill_status_badge.dart';

class CommunityMatchCard extends StatelessWidget {
  final CommunityMatch match;
  final VoidCallback onTap;

  const CommunityMatchCard({
    super.key,
    required this.match,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final thumbnail = match.court.thumbnail;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: thumbnail != null
                  ? CachedNetworkImage(
                      imageUrl: thumbnail,
                      width: 98,
                      height: 118,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 98,
                      height: 118,
                      color: AppColors.background,
                      child: const Icon(Icons.sports_tennis_rounded),
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          match.court.name,
                          style: AppTextStyles.heading4,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SplitBillStatusBadge(status: match.status),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    match.court.city?.name ?? 'Unknown city',
                    style: AppTextStyles.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${match.dateFormatted} | ${match.timeSlot}',
                          style: AppTextStyles.captionSemibold,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ParticipantAvatarStack(
                        participants: match.participants,
                        capacity: match.playerCapacity,
                      ),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${match.participantCount}/${match.playerCapacity} joined',
                            style: AppTextStyles.captionSemibold,
                          ),
                          Text(
                            match.shareAmount > 0
                                ? '${match.shareAmountFormatted}/player'
                                : 'Split bill ready',
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
