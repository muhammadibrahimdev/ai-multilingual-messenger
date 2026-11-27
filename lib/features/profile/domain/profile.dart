import 'package:flutter/foundation.dart';

import '../../../core/constants/app_language.dart';

/// A user's public profile (row of `public.profiles`).
@immutable
class Profile {
  const Profile({
    required this.id,
    required this.username,
    required this.displayName,
    required this.language,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile.build(
      id: json['id'] as String,
      username: json['username'] as String,
      displayName: json['display_name'] as String?,
      languageCode: json['preferred_language'] as String?,
    );
  }

  /// Builds a profile from loosely-typed column values, falling back to the
  /// username when no display name was set.
  factory Profile.build({
    required String id,
    required String username,
    required String? displayName,
    required String? languageCode,
  }) {
    final name = displayName?.trim();
    return Profile(
      id: id,
      username: username,
      displayName: (name == null || name.isEmpty) ? username : name,
      language: AppLanguage.fromCode(languageCode),
    );
  }

  final String id;
  final String username;
  final String displayName;
  final AppLanguage language;

  @override
  bool operator ==(Object other) {
    return other is Profile &&
        other.id == id &&
        other.username == username &&
        other.displayName == displayName &&
        other.language == language;
  }

  @override
  int get hashCode => Object.hash(id, username, displayName, language);
}
