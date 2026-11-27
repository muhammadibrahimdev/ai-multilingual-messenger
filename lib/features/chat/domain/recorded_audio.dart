import 'package:flutter/foundation.dart';

/// A finished voice recording, ready to upload.
@immutable
class RecordedAudio {
  const RecordedAudio({
    required this.bytes,
    required this.extension,
    required this.contentType,
    required this.duration,
  });

  final Uint8List bytes;

  /// File extension without the dot (`m4a` on phones, `webm` in browsers).
  final String extension;

  final String contentType;
  final Duration duration;
}
