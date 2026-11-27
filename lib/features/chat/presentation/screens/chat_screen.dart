import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/app_exception.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/snackbars.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../profile/domain/profile.dart';
import '../../domain/message.dart';
import '../../domain/recorded_audio.dart';
import '../providers/chat_providers.dart';
import '../widgets/date_divider.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_input.dart';

class ChatScreen extends ConsumerWidget {
  const ChatScreen({super.key, required this.conversationId});

  final String conversationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partner = ref.watch(chatPartnerProvider(conversationId));
    final messages = ref.watch(messagesProvider(conversationId));
    final viewerId = ref.watch(currentUserIdProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: _PartnerHeader(partner: partner),
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => ErrorView(
                message: AppException.messageOf(error),
                onRetry: () =>
                    ref.invalidate(messagesProvider(conversationId)),
              ),
              data: (items) => viewerId == null
                  ? const SizedBox.shrink()
                  : _MessageList(messages: items, viewerId: viewerId),
            ),
          ),
          MessageInput(
            onSend: (text) => _send(context, ref, text),
            onSendVoice: (audio) => _sendVoice(context, ref, audio),
          ),
        ],
      ),
    );
  }

  Future<bool> _send(BuildContext context, WidgetRef ref, String text) async {
    try {
      await ref
          .read(chatControllerProvider)
          .sendText(conversationId: conversationId, text: text);
      return true;
    } on Object catch (error) {
      if (context.mounted) showErrorSnackBar(context, error);
      return false;
    }
  }

  Future<bool> _sendVoice(
    BuildContext context,
    WidgetRef ref,
    RecordedAudio audio,
  ) async {
    try {
      await ref
          .read(chatControllerProvider)
          .sendVoice(conversationId: conversationId, audio: audio);
      return true;
    } on Object catch (error) {
      if (context.mounted) showErrorSnackBar(context, error);
      return false;
    }
  }
}

class _PartnerHeader extends StatelessWidget {
  const _PartnerHeader({required this.partner});

  final AsyncValue<Profile> partner;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return partner.when(
      loading: () => const Text('Chat'),
      error: (error, stackTrace) => const Text('Chat'),
      data: (profile) => Row(
        children: [
          AppAvatar(name: profile.displayName, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  profile.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall,
                ),
                Text(
                  '${profile.language.name} · @${profile.username}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageList extends StatelessWidget {
  const _MessageList({required this.messages, required this.viewerId});

  final List<Message> messages;
  final String viewerId;

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return const EmptyState(
        icon: Icons.chat_bubble_outline,
        title: 'No messages yet',
        description: 'Say hello! Messages are translated automatically.',
      );
    }

    // Newest first so the reversed list starts anchored at the bottom.
    final newestFirst = messages.reversed.toList();

    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: newestFirst.length,
      itemBuilder: (context, index) {
        final message = newestFirst[index];
        final older = index + 1 < newestFirst.length
            ? newestFirst[index + 1]
            : null;
        final startsNewDay =
            older == null ||
            !DateFormatter.isSameDay(older.createdAt, message.createdAt);

        return Column(
          key: ValueKey(message.id),
          children: [
            if (startsNewDay) DateDivider(date: message.createdAt),
            MessageBubble(message: message, viewerId: viewerId),
          ],
        );
      },
    );
  }
}
