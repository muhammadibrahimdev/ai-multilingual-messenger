import 'package:ai_multilingual_messenger/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators.email', () {
    test('accepts a normal address', () {
      expect(Validators.email('user@example.com'), isNull);
    });

    test('rejects empty and malformed input', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email(null), isNotNull);
      expect(Validators.email('no-at-sign'), isNotNull);
      expect(Validators.email('a@b'), isNotNull);
    });
  });

  group('Validators.password', () {
    test('requires the minimum length', () {
      expect(Validators.password('short'), isNotNull);
      expect(Validators.password('longenough1'), isNull);
    });
  });

  group('Validators.username', () {
    test('accepts letters, numbers and underscores', () {
      expect(Validators.username('ibrahim_20'), isNull);
      expect(Validators.username('Ibrahim_20'), isNull);
    });

    test('rejects too short, too long and invalid characters', () {
      expect(Validators.username('ab'), isNotNull);
      expect(Validators.username('a' * 21), isNotNull);
      expect(Validators.username('has space'), isNotNull);
      expect(Validators.username('dash-name'), isNotNull);
    });
  });

  group('Validators.displayName', () {
    test('requires a non-empty name within the limit', () {
      expect(Validators.displayName('  '), isNotNull);
      expect(Validators.displayName('Ayesha Khan'), isNull);
      expect(Validators.displayName('x' * 41), isNotNull);
    });
  });
}
