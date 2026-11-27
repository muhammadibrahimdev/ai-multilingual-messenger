import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_language.dart';
import '../../data/auth_repository.dart';

/// Application-layer entry point for auth actions used by the UI.
///
/// Methods throw `AppException` on failure; screens own their loading and
/// error state so unrelated screens never share it.
class AuthController {
  AuthController(this._repository);

  final AuthRepository _repository;

  Future<void> signIn({required String email, required String password}) {
    return _repository.signIn(email: email, password: password);
  }

  Future<SignUpOutcome> signUp({
    required String email,
    required String password,
    required String username,
    required String displayName,
    required AppLanguage language,
  }) {
    return _repository.signUp(
      email: email,
      password: password,
      username: username,
      displayName: displayName,
      language: language,
    );
  }

  Future<void> signOut() => _repository.signOut();
}

final authControllerProvider = Provider<AuthController>(
  (ref) => AuthController(ref.watch(authRepositoryProvider)),
);
