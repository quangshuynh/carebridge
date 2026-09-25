import 'package:flutter_tts/flutter_tts.dart';

import '../services/speech_service.dart';

class FlutterTtsSpeechService implements SpeechService {
  FlutterTtsSpeechService({FlutterTts? flutterTts})
    : _flutterTts = flutterTts ?? FlutterTts();
  final FlutterTts _flutterTts;
  Future<void>? _configuration;
  int _latestRequest = 0;

  @override
  Future<void> speak(String phrase) async {
    final request = ++_latestRequest;
    await (_configuration ??= _configure());
    // A newer communication or a stop supersedes this one; never speak a
    // stale phrase late or queue it behind the newer one.
    if (request != _latestRequest) return;
    await _flutterTts.stop();
    if (request != _latestRequest) return;
    await _flutterTts.speak(phrase);
  }

  @override
  Future<void> stop() async {
    _latestRequest++;
    await _flutterTts.stop();
  }

  /// Applied once. Each setting is optional: failing to apply one must not
  /// prevent speaking with the platform's default voice.
  Future<void> _configure() async {
    await _attempt(() => _flutterTts.setLanguage('en-US'));
    await _attempt(() => _flutterTts.setSpeechRate(0.45));
    // iOS only (a no-op elsewhere): the playback category keeps the
    // communicator's voice audible when the ring/silent switch is on silent.
    await _attempt(
      () => _flutterTts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        [IosTextToSpeechAudioCategoryOptions.duckOthers],
      ),
    );
  }

  static Future<void> _attempt(Future<Object?> Function() setting) async {
    try {
      await setting();
    } catch (_) {}
  }
}
