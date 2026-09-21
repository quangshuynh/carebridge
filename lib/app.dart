import 'package:flutter/material.dart';

import 'application/communication_board_controller.dart';
import 'domain/sample_board.dart';
import 'presentation/communication_board_screen.dart';
import 'services/speech_service.dart';

class CareBridgeApp extends StatelessWidget {
  const CareBridgeApp({required this.speechService, super.key});
  final SpeechService speechService;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'CareBridge',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF245D58)),
      scaffoldBackgroundColor: const Color(0xFFF5F7F4),
      useMaterial3: true,
    ),
    home: CommunicationBoardScreen(
      profile: sampleCommunicator,
      controller: CommunicationBoardController(speechService: speechService),
    ),
  );
}
