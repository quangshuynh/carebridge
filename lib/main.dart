import 'package:flutter/material.dart';

import 'app.dart';
import 'infrastructure/flutter_tts_speech_service.dart';
import 'infrastructure/platform_tactile_feedback.dart';
import 'infrastructure/shared_preferences_display_preferences_store.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Nothing is awaited before the first frame: speech configures itself on
  // first use and display preferences load in the background, so the board
  // never waits for, or depends on, a voice or storage.
  runApp(
    CareBridgeApp(
      speechService: FlutterTtsSpeechService(),
      tactileFeedback: const PlatformTactileFeedback(),
      displayPreferencesStore: SharedPreferencesDisplayPreferencesStore(),
    ),
  );
}
