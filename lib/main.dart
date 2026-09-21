import 'package:flutter/material.dart';

import 'app.dart';
import 'infrastructure/flutter_tts_speech_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(CareBridgeApp(speechService: FlutterTtsSpeechService()));
}
