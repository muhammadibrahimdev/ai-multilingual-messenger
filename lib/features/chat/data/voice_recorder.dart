import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../core/utils/app_exception.dart';
import '../domain/recorded_audio.dart';

/// Thin wrapper around the `record` package.
///
/// Phones record AAC in an `.m4a` file; browsers record Opus in a `.webm`
/// blob. Both formats are accepted by Groq Whisper and play back everywhere,
/// so the rest of the app only deals with [RecordedAudio].
class VoiceRecorder {
  VoiceRecorder() : _recorder = AudioRecorder();

  /// Recordings stop automatically after this long.
  static const Duration maxDuration = Duration(seconds: 60);

  /// Shorter recordings are treated as accidental taps.
  static const Duration minDuration = Duration(seconds: 1);

  final AudioRecorder _recorder;
  final Stopwatch _stopwatch = Stopwatch();

  Duration get elapsed => _stopwatch.elapsed;

  /// Asks for the microphone permission (if needed) and starts recording.
  Future<void> start() async {
    try {
      if (!await _recorder.hasPermission()) {
        throw const AppException(
          'Microphone access is needed to record voice messages. '
          'Allow it in your browser or phone settings and try again.',
        );
      }

      // The web recorder ignores the path and returns a blob URL instead.
      var path = '';
      if (!kIsWeb) {
        final directory = await getTemporaryDirectory();
        path = '${directory.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      }

      await _recorder.start(
      const  RecordConfig(
          encoder: kIsWeb ? AudioEncoder.opus : AudioEncoder.aacLc,
          bitRate: 64000,
          numChannels: 1,
        ),
        path: path,
      );
      _stopwatch
        ..reset()
        ..start();
    } on AppException {
      rethrow;
    } on Object {
      throw const AppException('Could not start recording. Please try again.');
    }
  }

  /// Stops recording and returns the audio, or `null` if nothing was saved.
  Future<RecordedAudio?> stop() async {
    _stopwatch.stop();
    final duration = _stopwatch.elapsed;

    try {
      final path = await _recorder.stop();
      if (path == null || path.isEmpty) return null;

      // Browsers return a blob: URL, phones return a file path.
      final bytes = kIsWeb
          ? await http.readBytes(Uri.parse(path))
          : await File(path).readAsBytes();
      await _deleteTempFile(path);

      return RecordedAudio(
        bytes: bytes,
        extension: kIsWeb ? 'webm' : 'm4a',
        contentType: kIsWeb ? 'audio/webm' : 'audio/mp4',
        duration: duration,
      );
    } on Object {
      throw const AppException('Could not save the recording. Please try again.');
    }
  }

  /// Stops recording and throws the audio away.
  Future<void> cancel() async {
    _stopwatch.stop();
    try {
      await _recorder.cancel();
    } on Object {
      // Nothing useful to do if cancelling fails.
    }
  }

  Future<void> dispose() async {
    try {
      await _recorder.dispose();
    } on Object {
      // The recorder is already gone.
    }
  }

  Future<void> _deleteTempFile(String path) async {
    if (kIsWeb) return;
    try {
      await File(path).delete();
    } on Object {
      // Temp files are cleaned up by the OS eventually.
    }
  }
}