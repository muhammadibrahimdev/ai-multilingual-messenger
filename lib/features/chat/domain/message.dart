import 'package:flutter/foundation.dart';

import '../../../core/constants/app_language.dart';

enum MessageType {
  text,
  voice;

  static MessageType fromName(String? name) {
    return MessageType.values.firstWhere(
      (type) => type.name == name,
      orElse: () => MessageType.text,
    );
  }
}

/// A chat message (row of `public.messages`).
@immutable
class Message {
  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.type,
    required this.createdAt,
    this.originalText,
    this.translatedText,
    this.sourceLang,
    this.targetLang,
    this.audioPath,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      senderId: json['sender_id'] as String,
      type: MessageType.fromName(json['type'] as String?),
      originalText: json['original_text'] as String?,
      translatedText: json['translated_text'] as String?,
      sourceLang: _language(json['source_lang'] as String?),
      targetLang: _language(json['target_lang'] as String?),
      audioPath: json['audio_path'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  final String id;
  final String conversationId;
  final String senderId;
  final MessageType type;
  final DateTime createdAt;
  final String? originalText;
  final String? translatedText;
  final AppLanguage? sourceLang;
  final AppLanguage? targetLang;
  final String? audioPath;

  bool isMine(String viewerId) => senderId == viewerId;

  /// Whether a translation that differs from the original exists.
  bool get hasTranslation {
    final translated = translatedText?.trim();
    return translated != null &&
        translated.isNotEmpty &&
        translated != originalText?.trim();
  }

  /// Whether this message should have a translation but does not, because
  /// the translation service failed or was unavailable when it was sent.
  bool get translationMissing {
    final source = sourceLang;
    final target = targetLang;
    if (source == null || target == null || source == target) return false;

    final translated = translatedText?.trim();
    return translated == null || translated.isEmpty;
  }

  /// The text the viewer reads first: their own words for sent messages, the
  /// translation (when available) for received ones.
  String? primaryText(String viewerId) {
    if (isMine(viewerId)) return originalText;
    return hasTranslation ? translatedText : originalText;
  }

  AppLanguage? primaryLanguage(String viewerId) {
    if (isMine(viewerId)) return sourceLang;
    return hasTranslation ? targetLang : sourceLang;
  }

  /// The "other version": what the recipient sees for sent messages, the
  /// original wording for received ones. `null` when there is no translation.
  String? secondaryText(String viewerId) {
    if (!hasTranslation) return null;
    return isMine(viewerId) ? translatedText : originalText;
  }

  AppLanguage? secondaryLanguage(String viewerId) {
    if (!hasTranslation) return null;
    return isMine(viewerId) ? targetLang : sourceLang;
  }

  static AppLanguage? _language(String? code) {
    return code == null ? null : AppLanguage.fromCode(code);
  }
}
