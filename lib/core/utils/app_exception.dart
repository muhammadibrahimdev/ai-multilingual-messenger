import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

/// A user-presentable error raised by the data layer.
///
/// Repositories convert every low-level failure (auth, database, edge
/// function, network) into an [AppException] so the UI never has to inspect
/// SDK exceptions.
class AppException implements Exception {
  const AppException(this.message);

  factory AppException.from(Object error) {
    if (error is AppException) return error;
    if (error is AuthException) return AppException(_fromAuth(error));
    if (error is PostgrestException) return AppException(_fromPostgrest(error));
    if (error is FunctionException) return AppException(_fromFunction(error));
    if (error is StorageException) {
      return const AppException('Could not upload the audio. Please try again.');
    }
    if (error is SocketException || _looksOffline(error.toString())) {
      return const AppException(_offline);
    }
    return const AppException(_generic);
  }

  final String message;

  static const String _generic = 'Something went wrong. Please try again.';
  static const String _offline =
      'No internet connection. Check your network and try again.';

  /// Convenience for UI code: the friendly message for any thrown object.
  static String messageOf(Object error) => AppException.from(error).message;

  static bool _looksOffline(String text) {
    final lower = text.toLowerCase();
    return lower.contains('socketexception') ||
        lower.contains('clientexception') ||
        lower.contains('failed host lookup');
  }

  static String _fromAuth(AuthException error) {
    final message = error.message.toLowerCase();
    if (message.contains('invalid login credentials')) {
      return 'Incorrect email or password.';
    }
    if (message.contains('already registered') ||
        message.contains('already been registered')) {
      return 'An account with this email already exists.';
    }
    if (message.contains('database error saving new user')) {
      return 'That username is already taken. Please choose another one.';
    }
    if (message.contains('email not confirmed')) {
      return 'Please confirm your email address before signing in.';
    }
    if (message.contains('rate limit') || message.contains('too many')) {
      return 'Too many attempts. Please wait a moment and try again.';
    }
    if (_looksOffline(message)) return _offline;
    return error.message.isEmpty ? _generic : error.message;
  }

  static String _fromPostgrest(PostgrestException error) {
    if (error.code == '23505') return 'That value is already in use.';
    if (error.code == '42501') return 'You do not have permission to do that.';
    if (error.code == 'PGRST116') return 'The requested item was not found.';
    if (error.message.toLowerCase().contains('cannot chat with yourself')) {
      return 'You cannot start a conversation with yourself.';
    }
    if (_looksOffline(error.message)) return _offline;
    return _generic;
  }

  /// Edge functions answer errors as `{"error": "<friendly message>"}`.
  static String _fromFunction(FunctionException error) {
    final details = error.details;
    if (details is Map && details['error'] is String) {
      return details['error'] as String;
    }
    if (error.status == 401) {
      return 'Your session has expired. Please sign in again.';
    }
    return _generic;
  }

  @override
  String toString() => message;
}
