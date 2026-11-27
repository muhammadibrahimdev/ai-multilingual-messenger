import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_language.dart';
import '../../../../core/utils/app_exception.dart';
import '../../../../core/utils/snackbars.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/profile.dart';
import '../providers/profile_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _signingOut = false;
  bool _savingLanguage = false;

  Future<void> _changeLanguage(AppLanguage language) async {
    setState(() => _savingLanguage = true);
    try {
      await ref
          .read(currentProfileProvider.notifier)
          .updateProfile(language: language);
    } on Object catch (error) {
      if (mounted) showErrorSnackBar(context, error);
    } finally {
      if (mounted) setState(() => _savingLanguage = false);
    }
  }

  Future<void> _signOut() async {
    setState(() => _signingOut = true);
    try {
      await ref.read(authControllerProvider).signOut();
      // The router redirects to the login screen automatically.
    } on Object catch (error) {
      if (mounted) {
        setState(() => _signingOut = false);
        showErrorSnackBar(context, error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentProfileProvider);
    final email = ref.watch(authRepositoryProvider).currentUser?.email;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: profile.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => ErrorView(
                message: AppException.messageOf(error),
                onRetry: () => ref.invalidate(currentProfileProvider),
              ),
              data: (data) => data == null
                  ? const SizedBox.shrink()
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _AccountCard(profile: data, email: email),
                        const SizedBox(height: 16),
                        _LanguageCard(
                          language: data.language,
                          enabled: !_savingLanguage,
                          onChanged: _changeLanguage,
                        ),
                        const SizedBox(height: 24),
                        AppButton(
                          label: 'Sign out',
                          icon: Icons.logout,
                          variant: AppButtonVariant.secondary,
                          isLoading: _signingOut,
                          onPressed: _signOut,
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.profile, required this.email});

  final Profile profile;
  final String? email;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      child: Row(
        children: [
          AppAvatar(name: profile.displayName, size: 52),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.displayName,
                  style: theme.textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text('@${profile.username}', style: theme.textTheme.bodySmall),
                if (email != null)
                  Text(
                    email!,
                    style: theme.textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  const _LanguageCard({
    required this.language,
    required this.enabled,
    required this.onChanged,
  });

  final AppLanguage language;
  final bool enabled;
  final ValueChanged<AppLanguage> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Preferred language', style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(
            'Messages you receive are translated into this language.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          LanguageSelector(
            value: language,
            enabled: enabled,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
