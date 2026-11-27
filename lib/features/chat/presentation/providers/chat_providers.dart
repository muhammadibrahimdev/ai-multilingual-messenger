import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/supabase_provider.dart';
import '../../../../core/utils/app_exception.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../profile/domain/profile.dart';
import '../../data/chat_repository.dart';
import '../../domain/conversation_summary.dart';
import '../../domain/message.dart';
import '../../domain/recorded_audio.dart';

final chatRepositoryProvider = Provider<ChatRepository>(
  (ref) => ChatRepository(ref.watch(supabaseClientProvider)),
);

/// The chat list, kept fresh by realtime events.
final conversationsProvider =
    StreamProvider.autoDispose<List<ConversationSummary>>((ref) {
      ref.watch(currentUserIdProvider);
      return ref.watch(chatRepositoryProvider).watchConversations();
    });

/// Live messages of a single conversation.
final messagesProvider = StreamProvider.autoDispose.family<List<Message>, String>(
  (ref, conversationId) {
    return ref.watch(chatRepositoryProvider).watchMessages(conversationId);
  },
);

/// The other participant of a conversation.
final chatPartnerProvider = FutureProvider.autoDispose.family<Profile, String>(
  (ref, conversationId) async {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) throw const AppException('You are not signed in.');
    return ref
        .watch(chatRepositoryProvider)
        .fetchPartner(conversationId: conversationId, currentUserId: userId);
  },
);

/// Application-layer actions for the chat feature.
class ChatController {
  ChatController(this._ref);

  final Ref _ref;

  /// Sends [text] to the conversation. Translation into the recipient's
  /// language happens on the server. Throws `AppException` on failure.
  Future<void> sendText({
    required String conversationId,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    if (_ref.read(currentUserIdProvider) == null) {
      throw const AppException('You are not signed in.');
    }

    await _ref
        .read(chatRepositoryProvider)
        .sendTextMessage(conversationId: conversationId, text: trimmed);
  }

  /// Uploads [audio] and has the server transcribe and translate it.
  /// Throws `AppException` on failure.
  Future<void> sendVoice({
    required String conversationId,
    required RecordedAudio audio,
  }) async {
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) throw const AppException('You are not signed in.');

    await _ref
        .read(chatRepositoryProvider)
        .sendVoiceMessage(
          conversationId: conversationId,
          userId: userId,
          audio: audio,
        );
  }

  /// Opens (or creates) the conversation with [otherUserId] and returns its id.
  Future<String> startConversation(String otherUserId) async {
    final id = await _ref
        .read(chatRepositoryProvider)
        .getOrCreateConversation(otherUserId);
    _ref.invalidate(conversationsProvider);
    return id;
  }
}

final chatControllerProvider = Provider<ChatController>(
  (ref) => ChatController(ref),
);
