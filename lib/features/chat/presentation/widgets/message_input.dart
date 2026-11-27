import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/snackbars.dart';
import '../../../../core/utils/text_utils.dart';
import '../../data/voice_recorder.dart';
import '../../domain/recorded_audio.dart';

enum _Mode { idle, recording, sending }

/// Bottom composer: a multi-line text field with a send button, which turns
/// into a microphone button while the field is empty. Tap the microphone to
/// record, then send or cancel.
///
/// [onSend] and [onSendVoice] resolve to `true` when the message was sent.
/// For text, a `false` result restores what was typed so nothing is lost.
class MessageInput extends StatefulWidget {
  const MessageInput({
    super.key,
    required this.onSend,
    required this.onSendVoice,
    this.enabled = true,
  });

  final Future<bool> Function(String text) onSend;
  final Future<bool> Function(RecordedAudio audio) onSendVoice;
  final bool enabled;

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final _controller = TextEditingController();
  final _recorder = VoiceRecorder();

  _Mode _mode = _Mode.idle;
  Duration _elapsed = Duration.zero;
  Timer? _ticker;

  @override
  void dispose() {
    _ticker?.cancel();
    unawaited(_recorder.dispose());
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submitText() async {
    final text = _controller.text.trim();
    if (text.isEmpty || !widget.enabled) return;

    _controller.clear();
    final sent = await widget.onSend(text);
    if (!sent && mounted && _controller.text.isEmpty) {
      _controller.text = text;
    }
  }

  Future<void> _startRecording() async {
    if (_mode != _Mode.idle || !widget.enabled) return;

    try {
      await _recorder.start();
    } on Object catch (error) {
      if (mounted) showErrorSnackBar(context, error);
      return;
    }

    if (!mounted) {
      await _recorder.cancel();
      return;
    }

    setState(() {
      _mode = _Mode.recording;
      _elapsed = Duration.zero;
    });

    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) {
      final elapsed = _recorder.elapsed;
      if (elapsed >= VoiceRecorder.maxDuration) {
        unawaited(_finishRecording());
        return;
      }
      if (mounted) setState(() => _elapsed = elapsed);
    });
  }

  Future<void> _finishRecording() async {
    if (_mode != _Mode.recording) return;
    _ticker?.cancel();
    setState(() => _mode = _Mode.sending);

    final RecordedAudio? audio;
    try {
      audio = await _recorder.stop();
    } on Object catch (error) {
      _reset();
      if (mounted) showErrorSnackBar(context, error);
      return;
    }

    if (audio == null || audio.duration < VoiceRecorder.minDuration) {
      _reset();
      if (mounted) {
        showInfoSnackBar(
          context,
          'Recording too short. Tap the microphone and speak for a moment.',
        );
      }
      return;
    }

    // The caller shows its own error message when sending fails.
    await widget.onSendVoice(audio);
    _reset();
  }

  Future<void> _cancelRecording() async {
    if (_mode != _Mode.recording) return;
    _ticker?.cancel();
    await _recorder.cancel();
    _reset();
  }

  void _reset() {
    if (!mounted) return;
    setState(() {
      _mode = _Mode.idle;
      _elapsed = Duration.zero;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: switch (_mode) {
            _Mode.idle => _buildComposer(),
            _Mode.recording => _buildRecordingBar(),
            _Mode.sending => const _StatusBar(
              icon: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              label: 'Sending voice message...',
            ),
          },
        ),
      ),
    );
  }

  Widget _buildComposer() {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _controller,
      builder: (context, value, _) {
        final hasText = value.text.trim().isNotEmpty;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                enabled: widget.enabled,
                minLines: 1,
                maxLines: 5,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                textDirection: TextUtils.directionFor(value.text),
                decoration: const InputDecoration(hintText: 'Message'),
              ),
            ),
            const SizedBox(width: 8),
            if (hasText)
              _ActionButton(
                icon: Icons.arrow_upward_rounded,
                tooltip: 'Send',
                style: _ActionStyle.primary,
                onPressed: widget.enabled ? _submitText : null,
              )
            else
              _ActionButton(
                icon: Icons.mic_none_rounded,
                tooltip: 'Record voice message',
                style: _ActionStyle.neutral,
                onPressed: widget.enabled ? _startRecording : null,
              ),
          ],
        );
      },
    );
  }

  Widget _buildRecordingBar() {
    return Row(
      children: [
        _ActionButton(
          icon: Icons.delete_outline_rounded,
          tooltip: 'Cancel recording',
          style: _ActionStyle.destructive,
          onPressed: _cancelRecording,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatusBar(
            icon: const Icon(
              Icons.fiber_manual_record,
              size: 14,
              color: AppColors.destructive,
            ),
            label: 'Recording  ${_format(_elapsed)}',
          ),
        ),
        const SizedBox(width: 8),
        _ActionButton(
          icon: Icons.arrow_upward_rounded,
          tooltip: 'Send voice message',
          style: _ActionStyle.primary,
          onPressed: _finishRecording,
        ),
      ],
    );
  }

  static String _format(Duration value) {
    final minutes = value.inMinutes;
    final seconds = (value.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

/// A bordered bar with an icon and a label, styled like the text field.
class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.icon, required this.label});

  final Widget icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.control,
        border: Border.all(color: AppColors.borderStrong),
        borderRadius: BorderRadius.circular(AppTheme.radius),
      ),
      child: Row(
        children: [
          icon,
          const SizedBox(width: 10),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

enum _ActionStyle { primary, neutral, destructive }

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.tooltip,
    required this.style,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final _ActionStyle style;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppTheme.radius);
    final enabled = onPressed != null;

    final (Color fill, Color border, Color foreground) = switch (style) {
      _ActionStyle.primary => (
        AppColors.brandButton,
        AppColors.brandButtonBorder,
        Colors.white,
      ),
      _ActionStyle.destructive => (
        AppColors.destructiveSubtle,
        AppColors.destructiveBorder,
        AppColors.destructive,
      ),
      _ActionStyle.neutral => (
        AppColors.surface,
        AppColors.borderStrong,
        AppColors.textPrimary,
      ),
    };

    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: 42,
        height: 42,
        child: Material(
          color: enabled ? fill : AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: BorderSide(color: enabled ? border : AppColors.borderStrong),
          ),
          child: InkWell(
            borderRadius: radius,
            onTap: onPressed,
            child: Icon(
              icon,
              size: 20,
              color: enabled ? foreground : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}
