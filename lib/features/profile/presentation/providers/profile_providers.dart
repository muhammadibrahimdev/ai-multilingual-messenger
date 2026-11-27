import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_language.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../auth/data/auth_repository.dart';
import '../../data/profile_repository.dart';
import '../../domain/profile.dart';

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(supabaseClientProvider)),
);

/// The signed-in user's profile. Rebuilds when the account changes.
class CurrentProfileNotifier extends AsyncNotifier<Profile?> {
  @override
  Future<Profile?> build() async {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return null;
    return ref.watch(profileRepositoryProvider).fetchProfile(userId);
  }

  /// Saves changes and publishes the updated profile. Throws `AppException`.
  Future<void> updateProfile({String? displayName, AppLanguage? language}) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final updated = await ref
        .read(profileRepositoryProvider)
        .updateProfile(
          userId: current.id,
          displayName: displayName,
          language: language,
        );
    state = AsyncData(updated);
  }
}

final currentProfileProvider =
    AsyncNotifierProvider<CurrentProfileNotifier, Profile?>(
      CurrentProfileNotifier.new,
    );

/// Search results for the "new chat" screen, keyed by the search term.
final userSearchProvider = FutureProvider.autoDispose
    .family<List<Profile>, String>((ref, query) async {
      final userId = ref.watch(currentUserIdProvider);
      if (userId == null) return const <Profile>[];
      return ref
          .watch(profileRepositoryProvider)
          .searchUsers(query: query, excludeUserId: userId);
    });
