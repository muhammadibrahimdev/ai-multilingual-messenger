import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_exception.dart';
import '../../../../core/widgets/widgets.dart';
import '../providers/chat_providers.dart';
import '../widgets/conversation_tile.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversations = ref.watch(conversationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(AppRoutes.settings),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: conversations.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorView(
          message: AppException.messageOf(error),
          onRetry: () => ref.invalidate(conversationsProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return EmptyState(
              icon: Icons.chat_bubble_outline,
              title: 'No conversations yet',
              description:
                  'Find someone by username and chat in your own language.',
              action: AppButton(
                label: 'New chat',
                icon: Icons.add,
                expand: false,
                onPressed: () => context.push(AppRoutes.newChat),
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.brand,
            backgroundColor: AppColors.surface,
            onRefresh: () async {
              ref.invalidate(conversationsProvider);
              await ref.read(conversationsProvider.future);
            },
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (context, index) =>
                  const Divider(indent: 72),
              itemBuilder: (context, index) {
                final conversation = items[index];
                return ConversationTile(
                  conversation: conversation,
                  onTap: () =>
                      context.push(AppRoutes.chatPath(conversation.id)),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.newChat),
        icon: const Icon(Icons.add, size: 18),
        label: const Text('New chat'),
        backgroundColor: AppColors.brandButton,
        foregroundColor: Colors.white,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radius),
          side: const BorderSide(color: AppColors.brandButtonBorder),
        ),
      ),
    );
  }
}
