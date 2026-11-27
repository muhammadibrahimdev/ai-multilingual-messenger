import 'package:flutter/material.dart';

import '../constants/app_language.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';

/// Two-column grid for choosing one of the supported languages.
class LanguageSelector extends StatelessWidget {
  const LanguageSelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final AppLanguage value;
  final ValueChanged<AppLanguage> onChanged;
  final bool enabled;

  static const double _spacing = 8;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - _spacing) / 2;

        return Wrap(
          spacing: _spacing,
          runSpacing: _spacing,
          children: [
            for (final language in AppLanguage.values)
              SizedBox(
                width: width,
                child: _LanguageOption(
                  language: language,
                  selected: language == value,
                  enabled: enabled,
                  onTap: () => onChanged(language),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.language,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final AppLanguage language;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(AppTheme.radius);
    final color = selected ? AppColors.brand : AppColors.textPrimary;
    final caption = language.isBeta ? '${language.name} · beta' : language.name;

    return Material(
      color: selected ? AppColors.brandSubtle : AppColors.control,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(
          color: selected ? AppColors.brand : AppColors.borderStrong,
        ),
      ),
      child: InkWell(
        borderRadius: radius,
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                language.nativeName,
                style: AppTextStyles.nativeLabel(language, color: color),
              ),
              Text(caption, style: theme.textTheme.labelSmall),
            ],
          ),
        ),
      ),
    );
  }
}
