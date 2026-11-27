import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_language.dart';
import '../../../core/utils/app_exception.dart';
import '../domain/profile.dart';

class ProfileRepository {
  ProfileRepository(this._client);

  final SupabaseClient _client;

  static const String _table = 'profiles';

  Future<Profile> fetchProfile(String userId) async {
    try {
      final data = await _client.from(_table).select().eq('id', userId).single();
      return Profile.fromJson(data);
    } on Object catch (error) {
      throw AppException.from(error);
    }
  }

  /// Finds other users whose username or display name contains [query].
  ///
  /// Email search is intentionally not offered: emails live in `auth.users`
  /// and exposing them to every signed-in user would be a privacy leak.
  Future<List<Profile>> searchUsers({
    required String query,
    required String excludeUserId,
  }) async {
    // Strip characters that have special meaning in PostgREST filters.
    final term = query.replaceAll(RegExp(r'[,()%*\\]'), '').trim();
    if (term.isEmpty) return const [];

    try {
      final data = await _client
          .from(_table)
          .select()
          .neq('id', excludeUserId)
          .or('username.ilike.%$term%,display_name.ilike.%$term%')
          .order('username')
          .limit(20);
      return data.map(Profile.fromJson).toList();
    } on Object catch (error) {
      throw AppException.from(error);
    }
  }

  Future<Profile> updateProfile({
    required String userId,
    String? displayName,
    AppLanguage? language,
  }) async {
    final updates = <String, dynamic>{
      if (displayName != null) 'display_name': displayName.trim(),
      if (language != null) 'preferred_language': language.code,
    };

    try {
      final data = await _client
          .from(_table)
          .update(updates)
          .eq('id', userId)
          .select()
          .single();
      return Profile.fromJson(data);
    } on Object catch (error) {
      throw AppException.from(error);
    }
  }
}
