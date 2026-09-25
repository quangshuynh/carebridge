import 'package:flutter/material.dart';

import 'application/communication_board_controller.dart';
import 'domain/communication_models.dart';
import 'domain/sample_board.dart';
import 'presentation/care_bridge_theme.dart';
import 'presentation/communication_board_screen.dart';
import 'services/speech_service.dart';
import 'services/tactile_feedback.dart';

class CareBridgeApp extends StatefulWidget {
  const CareBridgeApp({
    required this.speechService,
    this.tactileFeedback,
    this.profile = sampleCommunicator,
    super.key,
  });
  final SpeechService speechService;
  final TactileFeedback? tactileFeedback;
  final CommunicatorProfile profile;

  @override
  State<CareBridgeApp> createState() => _CareBridgeAppState();
}

class _CareBridgeAppState extends State<CareBridgeApp> {
  late final CommunicationBoardController _controller =
      CommunicationBoardController(
        speechService: widget.speechService,
        tactileFeedback: widget.tactileFeedback,
      );

  // Speech stops when CareBridge leaves the screen so it cannot resume or
  // play late after returning. What was communicated stays selected.
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onHide: _controller.stopSpeech);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'CareBridge',
    debugShowCheckedModeBanner: false,
    theme: buildCareBridgeTheme(),
    home: CommunicationBoardScreen(
      profile: widget.profile,
      controller: _controller,
    ),
  );
}
