import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';

/// Pill showing the day ("Today", "Yesterday", "Oct 12, 2026") between
/// messages from different days.
class DateDivider extends StatelessWidget {
  const DateDivider({super.key, required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          DateFormatter.dayLabel(date),
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ),
    );
  }
}
