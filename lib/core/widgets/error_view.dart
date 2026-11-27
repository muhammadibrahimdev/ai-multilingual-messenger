import 'package:flutter/material.dart';

import 'app_button.dart';
import 'empty_state.dart';

/// Full-area error with an optional retry button.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.error_outline,
      title: 'Something went wrong',
      description: message,
      action: onRetry == null
          ? null
          : AppButton(
              label: 'Try again',
              icon: Icons.refresh,
              variant: AppButtonVariant.secondary,
              expand: false,
              onPressed: onRetry,
            ),
    );
  }
}
