import 'package:ai_multilingual_messenger/core/utils/app_exception.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('AppException.from', () {
    test('returns an existing AppException unchanged', () {
      const original = AppException('boom');
      expect(identical(AppException.from(original), original), isTrue);
    });

    test('maps invalid credentials to a friendly message', () {
      final error = AppException.from(
        const AuthException('Invalid login credentials'),
      );
      expect(error.message, 'Incorrect email or password.');
    });

    test('maps the signup trigger failure to a username message', () {
      final error = AppException.from(
        const AuthException('Database error saving new user'),
      );
      expect(error.message, contains('username'));
    });

    test('falls back to a generic message for unknown errors', () {
      final error = AppException.from(StateError('unexpected'));
      expect(error.message, contains('Something went wrong'));
    });
  });
}
