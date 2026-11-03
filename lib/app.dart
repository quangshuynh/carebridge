import 'package:flutter/material.dart';

import 'application/communication_board_controller.dart';
import 'application/display_preferences_controller.dart';
import 'domain/communication_models.dart';
import 'domain/sample_board.dart';
import 'presentation/care_bridge_theme.dart';
import 'presentation/communication_board_screen.dart';
import 'services/display_preferences_store.dart';
import 'services/speech_service.dart';
import 'services/tactile_feedback.dart';

class CareBridgeApp extends StatefulWidget {
  const CareBridgeApp({
    required this.speechService,
    this.tactileFeedback,
    this.displayPreferencesStore,
    this.profile = sampleCommunicator,
    this.now,
    super.key,
  });
  final SpeechService speechService;
  final TactileFeedback? tactileFeedback;

  /// Where display preferences are kept. Null keeps them in memory only.
  final DisplayPreferencesStore? displayPreferencesStore;
  final CommunicatorProfile profile;

  /// The clock for communication events and the duplicate window; tests
  /// inject a fake one.
  final DateTime Function()? now;

  @override
  State<CareBridgeApp> createState() => _CareBridgeAppState();
}

class _CareBridgeAppState extends State<CareBridgeApp> {
  late final CommunicationBoardController _controller =
      CommunicationBoardController(
        speechService: widget.speechService,
        tactileFeedback: widget.tactileFeedback,
        now: widget.now,
      );
  late final DisplayPreferencesController _displayPreferences =
      DisplayPreferencesController(store: widget.displayPreferencesStore);

  // Speech stops when CareBridge leaves the screen so it cannot resume or
  // play late after returning. What was communicated stays selected.
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onHide: _controller.stopSpeech);
    // Not awaited: the board is usable at once in the standard display.
    _displayPreferences.load();
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _controller.dispose();
    _displayPreferences.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _displayPreferences,
    builder: (context, _) => MaterialApp(
      title: 'CareBridge',
      debugShowCheckedModeBanner: false,
      theme: buildCareBridgeTheme(
        highContrast: _displayPreferences.highContrast,
      ),
      // Used whenever the device itself asks for more contrast (iOS
      // Increase Contrast), whatever the CareBridge setting.
      highContrastTheme: buildCareBridgeTheme(highContrast: true),
      // Contrast changes take effect at once, never as a fade.
      themeAnimationDuration: Duration.zero,
      home: CommunicationBoardScreen(
        profile: widget.profile,
        controller: _controller,
        displayPreferences: _displayPreferences,
      ),
    ),
  );
}
