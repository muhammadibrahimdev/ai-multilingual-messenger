import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_language.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../core/utils/app_exception.dart';

enum SignUpOutcome { signedIn, emailConfirmationRequired }

/// Thin wrapper around Supabase Auth. Every failure is rethrown as an
/// [AppException] with a user-presentable message.
class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;

  GoTrueClient get _auth => _client.auth;

  User? get currentUser => _auth.currentUser;

  bool get isSignedIn => _auth.currentSession != null;

  Stream<AuthState> get authStateChanges => _auth.onAuthStateChange;

  Future<void> signIn({required String email, required String password}) async {
    try {
      await _auth.signInWithPassword(email: email.trim(), password: password);
    } on Object catch (error) {
      throw AppException.from(error);
    }
  }

  /// Registers a user. The database trigger `handle_new_user` reads the
  /// metadata passed here to create the matching `profiles` row.
  Future<SignUpOutcome> signUp({
    required String email,
    required String password,
    required String username,
    required String displayName,
    required AppLanguage language,
  }) async {
    try {
      final response = await _auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'username': username.trim().toLowerCase(),
          'display_name': displayName.trim(),
          'preferred_language': language.code,
        },
      );
      return response.session != null
          ? SignUpOutcome.signedIn
          : SignUpOutcome.emailConfirmationRequired;
    } on Object catch (error) {
      throw AppException.from(error);
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on Object catch (error) {
      throw AppException.from(error);
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(supabaseClientProvider)),
);

/// Emits on every auth event (sign in, sign out, token refresh, ...).
final authStateProvider = StreamProvider<AuthState>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges,
);

/// The signed-in user's id, or `null`. Providers that hold per-user data
/// watch this so they rebuild when the account changes.
final currentUserIdProvider = Provider<String?>((ref) {
  ref.watch(authStateProvider);
  return ref.watch(authRepositoryProvider).currentUser?.id;
});
