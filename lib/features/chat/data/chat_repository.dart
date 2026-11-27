import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/app_exception.dart';
import '../../profile/domain/profile.dart';
import '../domain/conversation_summary.dart';
import '../domain/message.dart';
import '../domain/recorded_audio.dart';

class ChatRepository {
  ChatRepository(this._client);

  final SupabaseClient _client;

  static const String _voiceBucket = 'voice';

  /// Loads the chat list through the `get_my_conversations()` RPC.
  Future<List<ConversationSummary>> fetchConversations() async {
    try {
      final data = await _client.rpc('get_my_conversations') as List<dynamic>;
      return data
          .cast<Map<String, dynamic>>()
          .map(ConversationSummary.fromJson)
          .toList();
    } on Object catch (error) {
      throw AppException.from(error);
    }
  }

  /// Emits the chat list now and again whenever a new message arrives.
  ///
  /// Realtime respects row level security, so only messages from the user's
  /// own conversations trigger a refresh.
  Stream<List<ConversationSummary>> watchConversations() {
    late final StreamController<List<ConversationSummary>> controller;
    RealtimeChannel? channel;

    Future<void> load() async {
      try {
        final items = await fetchConversations();
        if (!controller.isClosed) controller.add(items);
      } on Object catch (error, stackTrace) {
        if (!controller.isClosed) controller.addError(error, stackTrace);
      }
    }

    controller = StreamController<List<ConversationSummary>>(
      onListen: () {
        unawaited(load());
        channel = _client
            .channel('conversation-list-${DateTime.now().microsecondsSinceEpoch}')
            .onPostgresChanges(
              event: PostgresChangeEvent.insert,
              schema: 'public',
              table: 'messages',
              callback: (_) => unawaited(load()),
            )
            .subscribe();
      },
      onCancel: () async {
        final active = channel;
        if (active != null) await _client.removeChannel(active);
        await controller.close();
      },
    );

    return controller.stream;
  }

  /// Live, ordered messages of one conversation.
  Stream<List<Message>> watchMessages(String conversationId) {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true)
        .map((rows) => rows.map(Message.fromJson).toList());
  }

  /// Sends a text message through the `send-message` Edge Function.
  ///
  /// The function checks membership, translates the text into the
  /// recipient's language with Groq and stores the row. The new message then
  /// arrives through [watchMessages]. Languages are decided on the server
  /// from the two profiles, so the client only sends the text.
  Future<void> sendTextMessage({
    required String conversationId,
    required String text,
  }) async {
    try {
      await _client.functions.invoke(
        'send-message',
        body: {'conversation_id': conversationId, 'text': text},
      );
    } on Object catch (error) {
      throw AppException.from(error);
    }
  }

  /// Uploads a recording to the private `voice` bucket and asks the
  /// `process-voice` Edge Function to transcribe, translate and store it.
  ///
  /// The file is named `<conversation>/<user>_<time>.<ext>`; the storage
  /// policies and the function both rely on that layout. The new message
  /// arrives through [watchMessages].
  Future<void> sendVoiceMessage({
    required String conversationId,
    required String userId,
    required RecordedAudio audio,
  }) async {
    final path =
        '$conversationId/${userId}_${DateTime.now().millisecondsSinceEpoch}'
        '.${audio.extension}';

    try {
      await _client.storage
          .from(_voiceBucket)
          .uploadBinary(
            path,
            audio.bytes,
            fileOptions: FileOptions(contentType: audio.contentType),
          );
      await _client.functions.invoke(
        'process-voice',
        body: {'conversation_id': conversationId, 'audio_path': path},
      );
    } on Object catch (error) {
      throw AppException.from(error);
    }
  }

  /// A temporary link for playing a private voice recording.
  Future<String> voiceUrl(String audioPath) async {
    try {
      return await _client.storage
          .from(_voiceBucket)
          .createSignedUrl(audioPath, 60 * 60);
    } on Object catch (error) {
      throw AppException.from(error);
    }
  }

  /// Returns the id of the conversation with [otherUserId], creating it if
  /// needed (see the `get_or_create_conversation` database function).
  Future<String> getOrCreateConversation(String otherUserId) async {
    try {
      final id = await _client.rpc(
        'get_or_create_conversation',
        params: {'other_user': otherUserId},
      );
      return id as String;
    } on Object catch (error) {
      throw AppException.from(error);
    }
  }

  /// The other participant of [conversationId].
  Future<Profile> fetchPartner({
    required String conversationId,
    required String currentUserId,
  }) async {
    try {
      final conversation = await _client
          .from('conversations')
          .select('user1_id, user2_id')
          .eq('id', conversationId)
          .single();
      final user1 = conversation['user1_id'] as String;
      final user2 = conversation['user2_id'] as String;
      final partnerId = user1 == currentUserId ? user2 : user1;

      final profile = await _client
          .from('profiles')
          .select()
          .eq('id', partnerId)
          .single();
      return Profile.fromJson(profile);
    } on Object catch (error) {
      throw AppException.from(error);
    }
  }
}
