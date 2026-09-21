import 'package:flutter_tts/flutter_tts.dart';

import '../services/speech_service.dart';

class FlutterTtsSpeechService implements SpeechService {
  FlutterTtsSpeechService({FlutterTts? flutterTts})
    : _flutterTts = flutterTts ?? FlutterTts();
  final FlutterTts _flutterTts;

  @override
  Future<void> speak(String phrase) async {
    await _flutterTts.stop();
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(0.45);
    await _flutterTts.speak(phrase);
  }
}
