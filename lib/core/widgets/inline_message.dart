import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

enum InlineMessageType { error, info }

/// Bordered alert box for form-level errors and notices.
class InlineMessage extends StatelessWidget {
  const InlineMessage({
    super.key,
    required this.message,
    this.type = InlineMessageType.error,
  });

  final String message;
  final InlineMessageType type;

  @override
  Widget build(BuildContext context) {
    final isError = type == InlineMessageType.error;
    final foreground = isError ? AppColors.destructive : AppColors.brand;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isError ? AppColors.destructiveSubtle : AppColors.brandSubtle,
        border: Border.all(
          color: isError
              ? AppColors.destructiveBorder
              : AppColors.brandSubtleBorder,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            size: 18,
            color: foreground,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: foreground),
            ),
          ),
        ],
      ),
    );
  }
}
