import 'package:flutter/material.dart';

import '../../../../core/constants/app_language.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/text_utils.dart';
import '../../domain/message.dart';
import 'voice_message_player.dart';

/// A single chat bubble: an optional voice player, the primary text, the
/// other-language version (when a translation exists) and the time.
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.viewerId,
  });

  final Message message;
  final String viewerId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMine = message.isMine(viewerId);
    final primary = message.primaryText(viewerId);
    final secondary = message.secondaryText(viewerId);
    final secondaryLanguage = message.secondaryLanguage(viewerId);
    final maxWidth = MediaQuery.sizeOf(context).width * 0.78;
    final primaryText =
        primary != null && primary.trim().isNotEmpty ? primary : null;
    final isVoice =
        message.type == MessageType.voice && message.audioPath != null;

    const large = Radius.circular(12);
    const small = Radius.circular(4);

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
          decoration: BoxDecoration(
            color: isMine ? AppColors.brandSubtle : AppColors.surface,
            border: Border.all(
              color: isMine ? AppColors.brandSubtleBorder : AppColors.border,
            ),
            borderRadius: BorderRadius.only(
              topLeft: large,
              topRight: large,
              bottomLeft: isMine ? large : small,
              bottomRight: isMine ? small : large,
            ),
          ),
          child: IntrinsicWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isVoice) VoiceMessagePlayer(message: message),
                if (isVoice && primaryText != null) const SizedBox(height: 8),
                if (primaryText != null)
                  _BubbleText(
                    text: primaryText,
                    language: message.primaryLanguage(viewerId),
                  ),
                if (secondary != null) ...[
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 6),
                  Text(
                    isMine
                        ? _label('Translation', secondaryLanguage)
                        : _label('Original', secondaryLanguage),
                    style: theme.textTheme.labelSmall,
                  ),
                  const SizedBox(height: 2),
                  _BubbleText(
                    text: secondary,
                    language: secondaryLanguage,
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ],
                if (message.translationMissing) ...[
                  const SizedBox(height: 6),
                  const _TranslationNotice(),
                ],
                const SizedBox(height: 4),
                Text(
                  DateFormatter.messageTime(message.createdAt),
                  textAlign: TextAlign.end,
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _label(String prefix, AppLanguage? language) {
    return language == null ? prefix : '$prefix · ${language.name}';
  }
}

class _BubbleText extends StatelessWidget {
  const _BubbleText({
    required this.text,
    required this.language,
    this.color = AppColors.textPrimary,
    this.fontSize = 15,
  });

  final String text;
  final AppLanguage? language;
  final Color color;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextUtils.directionFor(text, language: language),
      child: Text(
        text,
        textAlign: TextAlign.start,
        style: AppTextStyles.message(
          language: TextUtils.resolveLanguage(text, language),
          color: color,
          fontSize: fontSize,
        ),
      ),
    );
  }
}

/// Shown when a message was saved but could not be translated.
class _TranslationNotice extends StatelessWidget {
  const _TranslationNotice();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.translate_rounded,
          size: 13,
          color: AppColors.textMuted,
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            'Translation unavailable',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ),
      ],
    );
  }
}
