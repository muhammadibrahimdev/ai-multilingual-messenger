import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

enum AppButtonVariant { primary, secondary, ghost, destructive }

/// Supabase-style button: flat, 40px tall, 6px radius, 1px border.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.expand = true,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final bool expand;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = _ButtonColors.of(variant);
    final disabledAlpha = isLoading ? 1.0 : 0.5;

    final button = FilledButton(
      onPressed: isLoading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: colors.background,
        foregroundColor: colors.foreground,
        disabledBackgroundColor: colors.background.withValues(
          alpha: disabledAlpha,
        ),
        disabledForegroundColor: colors.foreground.withValues(
          alpha: disabledAlpha,
        ),
        elevation: 0,
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radius),
          side: BorderSide(color: colors.border),
        ),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLoading)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colors.foreground,
              ),
            )
          else if (icon != null)
            Icon(icon, size: 16),
          if (isLoading || icon != null) const SizedBox(width: 8),
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

class _ButtonColors {
  const _ButtonColors(this.background, this.foreground, this.border);

  final Color background;
  final Color foreground;
  final Color border;

  static _ButtonColors of(AppButtonVariant variant) {
    return switch (variant) {
      AppButtonVariant.primary => const _ButtonColors(
        AppColors.brandButton,
        Colors.white,
        AppColors.brandButtonBorder,
      ),
      AppButtonVariant.secondary => const _ButtonColors(
        AppColors.surface,
        AppColors.textPrimary,
        AppColors.borderStrong,
      ),
      AppButtonVariant.ghost => const _ButtonColors(
        Colors.transparent,
        AppColors.textSecondary,
        Colors.transparent,
      ),
      AppButtonVariant.destructive => const _ButtonColors(
        AppColors.destructiveSubtle,
        AppColors.destructive,
        AppColors.destructiveBorder,
      ),
    };
  }
}
