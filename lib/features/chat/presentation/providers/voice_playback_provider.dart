import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'chat_providers.dart';

/// What the single shared audio player is doing right now.
@immutable
class VoicePlaybackState {
  const VoicePlaybackState({
    this.messageId,
    this.isLoading = false,
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
  });

  /// The message whose audio is loaded, or `null` when idle.
  final String? messageId;
  final bool isLoading;
  final bool isPlaying;
  final Duration position;
  final Duration duration;

  VoicePlaybackState copyWith({
    bool? isLoading,
    bool? isPlaying,
    Duration? position,
    Duration? duration,
  }) {
    return VoicePlaybackState(
      messageId: messageId,
      isLoading: isLoading ?? this.isLoading,
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: duration ?? this.duration,
    );
  }
}

/// Plays one voice message at a time. Starting another message stops the
/// current one, like every messenger.
class VoicePlaybackNotifier extends Notifier<VoicePlaybackState> {
  final AudioPlayer _player = AudioPlayer();
  final List<StreamSubscription<void>> _subscriptions = [];

  String? _url;
  bool _completed = false;

  @override
  VoicePlaybackState build() {
    _subscriptions.addAll([
      _player.onPositionChanged.listen(
        (position) => state = state.copyWith(position: position),
      ),
      _player.onDurationChanged.listen(
        (duration) => state = state.copyWith(duration: duration),
      ),
      _player.onPlayerStateChanged.listen((playerState) {
        final playing = playerState == PlayerState.playing;
        state = state.copyWith(
          isPlaying: playing,
          isLoading: playing ? false : state.isLoading,
        );
      }),
      _player.onPlayerComplete.listen((_) {
        _completed = true;
        state = state.copyWith(isPlaying: false, position: Duration.zero);
      }),
    ]);

    ref.onDispose(() {
      for (final subscription in _subscriptions) {
        unawaited(subscription.cancel());
      }
      unawaited(_player.dispose());
    });

    return const VoicePlaybackState();
  }

  /// Plays, pauses or restarts the audio of [messageId]. Throws
  /// `AppException` when the recording cannot be loaded.
  Future<void> toggle({
    required String messageId,
    required String audioPath,
  }) async {
    if (state.messageId == messageId && _url != null) {
      if (state.isPlaying) {
        await _player.pause();
      } else if (_completed) {
        _completed = false;
        await _player.play(UrlSource(_url!));
      } else {
        await _player.resume();
      }
      return;
    }

    await _player.stop();
    _completed = false;
    _url = null;
    state = VoicePlaybackState(messageId: messageId, isLoading: true);

    try {
      final url = await ref.read(chatRepositoryProvider).voiceUrl(audioPath);
      _url = url;
      await _player.play(UrlSource(url));
    } on Object {
      state = const VoicePlaybackState();
      rethrow;
    }
  }
}

final voicePlaybackProvider =
    NotifierProvider<VoicePlaybackNotifier, VoicePlaybackState>(
      VoicePlaybackNotifier.new,
    );
