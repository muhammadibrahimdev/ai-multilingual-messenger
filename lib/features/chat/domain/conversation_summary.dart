import 'package:flutter/foundation.dart';

import '../../profile/domain/profile.dart';
import 'message.dart';

/// One row of the chat list: the other participant plus the latest message.
/// Produced by the `get_my_conversations()` database function.
@immutable
class ConversationSummary {
  const ConversationSummary({
    required this.id,
    required this.partner,
    required this.createdAt,
    this.lastMessageText,
    this.lastMessageType,
    this.lastMessageAt,
  });

  factory ConversationSummary.fromJson(Map<String, dynamic> json) {
    final lastType = json['last_message_type'] as String?;
    final lastAt = json['last_message_at'] as String?;

    return ConversationSummary(
      id: json['conversation_id'] as String,
      partner: Profile.build(
        id: json['other_user_id'] as String,
        username: json['other_username'] as String,
        displayName: json['other_display_name'] as String?,
        languageCode: json['other_language'] as String?,
      ),
      createdAt: DateTime.parse(json['conversation_created_at'] as String),
      lastMessageText: json['last_message_text'] as String?,
      lastMessageType: lastType == null ? null : MessageType.fromName(lastType),
      lastMessageAt: lastAt == null ? null : DateTime.parse(lastAt),
    );
  }

  final String id;
  final Profile partner;
  final DateTime createdAt;
  final String? lastMessageText;
  final MessageType? lastMessageType;
  final DateTime? lastMessageAt;

  bool get hasMessages => lastMessageAt != null;

  /// Timestamp used for ordering and display.
  DateTime get sortAt => lastMessageAt ?? createdAt;

  String get previewText {
    final text = lastMessageText?.trim();
    if (text != null && text.isNotEmpty) return text;
    if (lastMessageType == MessageType.voice) return 'Voice message';
    return 'No messages yet';
  }
}
