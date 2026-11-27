import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Shown instead of the app when Supabase credentials were not provided.
class ConfigErrorApp extends StatelessWidget {
  const ConfigErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Builder(
                  builder: (context) {
                    final theme = Theme.of(context);
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: AppColors.destructive,
                          size: 28,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Supabase is not configured',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Copy dart_defines.example.json to dart_defines.json, '
                          'fill in your project URL and publishable key, then '
                          'run the app with:',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.control,
                            border: Border.all(color: AppColors.borderStrong),
                            borderRadius: BorderRadius.circular(
                              AppTheme.radius,
                            ),
                          ),
                          child: const SelectableText(
                            'flutter run --dart-define-from-file=dart_defines.json',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              color: AppColors.brand,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
