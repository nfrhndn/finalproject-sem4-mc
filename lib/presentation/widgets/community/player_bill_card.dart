import 'package:flutter/material.dart';
import 'package:padalpro/core/theme/app_colors.dart';
import 'package:padalpro/core/theme/app_text_styles.dart';
import 'package:padalpro/domain/entities/community_match.dart';
import 'package:padalpro/presentation/widgets/community/split_bill_status_badge.dart';

class PlayerBillCard extends StatelessWidget {
  final SplitBill bill;

  const PlayerBillCard({super.key, required this.bill});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                bill.name.isNotEmpty ? bill.name[0].toUpperCase() : '?',
                style: AppTextStyles.heading5,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(bill.name, style: AppTextStyles.bodyLargeSemibold),
                Text(bill.amountFormatted, style: AppTextStyles.caption),
              ],
            ),
          ),
          SplitBillStatusBadge(status: bill.status),
        ],
      ),
    );
  }
}
