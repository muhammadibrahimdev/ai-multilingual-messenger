import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/snackbars.dart';
import '../../domain/message.dart';
import '../providers/voice_playback_provider.dart';

/// Play / pause button with a progress bar for one voice message.
class VoiceMessagePlayer extends ConsumerWidget {
  const VoiceMessagePlayer({super.key, required this.message});

  final Message message;

  static const double _width = 210;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioPath = message.audioPath;
    if (audioPath == null) return const SizedBox.shrink();

    // Only rebuild when this message's playback changes.
    final playback = ref.watch(
      voicePlaybackProvider.select(
        (state) => state.messageId == message.id ? state : null,
      ),
    );

    final isLoading = playback?.isLoading ?? false;
    final isPlaying = playback?.isPlaying ?? false;
    final position = playback?.position ?? Duration.zero;
    final duration = playback?.duration ?? Duration.zero;
    final progress = duration.inMilliseconds > 0
        ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;
    final label = duration > Duration.zero
        ? '${_format(position)} / ${_format(duration)}'
        : 'Voice message';

    return SizedBox(
      width: _width,
      child: Row(
        children: [
          _PlayButton(
            isPlaying: isPlaying,
            isLoading: isLoading,
            onPressed: () => _toggle(context, ref, audioPath),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 3,
                    backgroundColor: AppColors.borderStronger,
                  ),
                ),
                const SizedBox(height: 6),
                Text(label, style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggle(
    BuildContext context,
    WidgetRef ref,
    String audioPath,
  ) async {
    try {
      await ref
          .read(voicePlaybackProvider.notifier)
          .toggle(messageId: message.id, audioPath: audioPath);
    } on Object catch (error) {
      if (context.mounted) showErrorSnackBar(context, error);
    }
  }

  static String _format(Duration value) {
    final minutes = value.inMinutes;
    final seconds = (value.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({
    required this.isPlaying,
    required this.isLoading,
    required this.onPressed,
  });

  final bool isPlaying;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: Material(
        color: AppColors.brandButton,
        shape: const CircleBorder(
          side: BorderSide(color: AppColors.brandButtonBorder),
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: isLoading ? null : onPressed,
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    size: 22,
                    color: Colors.white,
                  ),
          ),
        ),
      ),
    );
  }
}
