import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_exception.dart';
import '../../../../core/utils/snackbars.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../profile/domain/profile.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../providers/chat_providers.dart';

class NewChatScreen extends ConsumerStatefulWidget {
  const NewChatScreen({super.key});

  @override
  ConsumerState<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends ConsumerState<NewChatScreen> {
  static const _debounce = Duration(milliseconds: 350);

  final _searchController = TextEditingController();
  Timer? _debounceTimer;
  String _query = '';
  String? _startingUserId;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounce, () {
      if (mounted) setState(() => _query = value.trim());
    });
  }

  Future<void> _startChat(Profile profile) async {
    if (_startingUserId != null) return;
    setState(() => _startingUserId = profile.id);

    try {
      final conversationId = await ref
          .read(chatControllerProvider)
          .startConversation(profile.id);
      if (!mounted) return;
      context.pushReplacement(AppRoutes.chatPath(conversationId));
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _startingUserId = null);
      showErrorSnackBar(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New chat')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onChanged: _onChanged,
              decoration: const InputDecoration(
                hintText: 'Search by username or name',
                prefixIcon: Icon(Icons.search, size: 18),
              ),
            ),
          ),
          const Divider(),
          Expanded(child: _buildResults()),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_query.isEmpty) {
      return const EmptyState(
        icon: Icons.person_search_outlined,
        title: 'Find someone to chat with',
        description: 'Type a username or name to search registered users.',
      );
    }

    final results = ref.watch(userSearchProvider(_query));

    return results.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => ErrorView(
        message: AppException.messageOf(error),
        onRetry: () => ref.invalidate(userSearchProvider(_query)),
      ),
      data: (profiles) {
        if (profiles.isEmpty) {
          return EmptyState(
            icon: Icons.search_off,
            title: 'No users found',
            description: 'Nobody matches "$_query". Check the spelling.',
          );
        }

        return ListView.separated(
          itemCount: profiles.length,
          separatorBuilder: (context, index) => const Divider(indent: 72),
          itemBuilder: (context, index) {
            final profile = profiles[index];
            return _UserTile(
              profile: profile,
              isLoading: _startingUserId == profile.id,
              onTap: () => _startChat(profile),
            );
          },
        );
      },
    );
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile({
    required this.profile,
    required this.isLoading,
    required this.onTap,
  });

  final Profile profile;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            AppAvatar(name: profile.displayName, size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text('@${profile.username}', style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isLoading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.borderStrong),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  profile.language.name,
                  style: theme.textTheme.labelSmall,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
