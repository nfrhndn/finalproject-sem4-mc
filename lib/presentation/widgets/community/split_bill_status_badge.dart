import 'package:flutter/material.dart';
import 'package:padalpro/core/theme/app_colors.dart';
import 'package:padalpro/core/theme/app_text_styles.dart';

class SplitBillStatusBadge extends StatelessWidget {
  final String status;

  const SplitBillStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'open' => AppColors.primary,
      'host' => AppColors.textPrimary,
      'full' || 'pending_payment' => Colors.orange,
      'pending' => Colors.orange,
      'paid' || 'completed' => Colors.green,
      'needs_reschedule' => Colors.deepOrange,
      'expired' || 'cancelled' || 'failed' => AppColors.error,
      _ => AppColors.textSecondary,
    };
    final label = switch (status) {
      'open' => 'Open',
      'host' => 'Host',
      'full' => 'Full',
      'pending_payment' => 'Payment',
      'pending' => 'Pending',
      'paid' => 'Paid',
      'completed' => 'Done',
      'needs_reschedule' => 'Reschedule',
      'expired' => 'Expired',
      'cancelled' => 'Cancelled',
      'failed' => 'Failed',
      _ => status,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: AppTextStyles.captionSmall.copyWith(
          color: color == AppColors.primary ? AppColors.textPrimary : color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
