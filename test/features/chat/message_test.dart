import 'package:ai_multilingual_messenger/core/constants/app_language.dart';
import 'package:ai_multilingual_messenger/features/chat/domain/message.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _json({String? translated = 'ہیلو'}) => {
  'id': 'm1',
  'conversation_id': 'c1',
  'sender_id': 'alice',
  'type': 'text',
  'original_text': 'Hello',
  'translated_text': translated,
  'source_lang': 'en',
  'target_lang': 'ur',
  'audio_path': null,
  'created_at': '2026-10-15T10:00:00+00:00',
};

void main() {
  group('Message.fromJson', () {
    test('parses all fields', () {
      final message = Message.fromJson(_json());
      expect(message.id, 'm1');
      expect(message.type, MessageType.text);
      expect(message.sourceLang, AppLanguage.english);
      expect(message.targetLang, AppLanguage.urdu);
      expect(message.hasTranslation, isTrue);
    });
  });

  group('sender view', () {
    final message = Message.fromJson(_json());

    test('shows own words first and the translation second', () {
      expect(message.primaryText('alice'), 'Hello');
      expect(message.primaryLanguage('alice'), AppLanguage.english);
      expect(message.secondaryText('alice'), 'ہیلو');
      expect(message.secondaryLanguage('alice'), AppLanguage.urdu);
    });
  });

  group('recipient view', () {
    final message = Message.fromJson(_json());

    test('shows the translation first and the original second', () {
      expect(message.primaryText('bob'), 'ہیلو');
      expect(message.primaryLanguage('bob'), AppLanguage.urdu);
      expect(message.secondaryText('bob'), 'Hello');
      expect(message.secondaryLanguage('bob'), AppLanguage.english);
    });
  });

  group('without a translation', () {
    final message = Message.fromJson(_json(translated: null));

    test('falls back to the original text and hides the second line', () {
      expect(message.hasTranslation, isFalse);
      expect(message.primaryText('bob'), 'Hello');
      expect(message.secondaryText('bob'), isNull);
      expect(message.secondaryText('alice'), isNull);
    });
  });
}
