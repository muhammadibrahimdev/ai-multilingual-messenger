import 'package:ai_multilingual_messenger/core/constants/app_language.dart';
import 'package:ai_multilingual_messenger/features/chat/domain/message.dart';
import 'package:flutter_test/flutter_test.dart';

Message _message({
  AppLanguage? source,
  AppLanguage? target,
  String? translated,
}) {
  return Message(
    id: 'm1',
    conversationId: 'c1',
    senderId: 'alice',
    type: MessageType.text,
    createdAt: DateTime.utc(2026, 10, 17),
    originalText: 'Hello',
    translatedText: translated,
    sourceLang: source,
    targetLang: target,
  );
}

void main() {
  group('Message.translationMissing', () {
    test('is true when languages differ and there is no translation', () {
      final message = _message(
        source: AppLanguage.english,
        target: AppLanguage.urdu,
      );

      expect(message.translationMissing, isTrue);
    });

    test('is true when the translation is blank', () {
      final message = _message(
        source: AppLanguage.english,
        target: AppLanguage.french,
        translated: '   ',
      );

      expect(message.translationMissing, isTrue);
    });

    test('is false when a translation exists', () {
      final message = _message(
        source: AppLanguage.english,
        target: AppLanguage.spanish,
        translated: 'Hola',
      );

      expect(message.translationMissing, isFalse);
    });

    test('is false when both languages are the same', () {
      final message = _message(
        source: AppLanguage.hindi,
        target: AppLanguage.hindi,
      );

      expect(message.translationMissing, isFalse);
    });

    test('is false when a language is unknown', () {
      expect(_message().translationMissing, isFalse);
      expect(_message(source: AppLanguage.english).translationMissing, isFalse);
    });
  });
}
