import 'package:flutter/foundation.dart';

import '../domain/communication_models.dart';
import '../services/speech_service.dart';

class CommunicationBoardController extends ChangeNotifier {
  CommunicationBoardController({
    required this.speechService,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;
  final SpeechService speechService;
  final DateTime Function() _now;
  CommunicationChoice? _selectedChoice;
  bool _isActivating = false;
  final List<CommunicationEvent> _sessionEvents = [];

  CommunicationChoice? get selectedChoice => _selectedChoice;
  List<CommunicationEvent> get sessionEvents =>
      List.unmodifiable(_sessionEvents);

  Future<bool> activate(CommunicationChoice choice) async {
    if (!choice.isEnabled || _isActivating) return false;
    _isActivating = true;
    _selectedChoice = choice;
    _sessionEvents.add(
      CommunicationEvent(
        choiceId: choice.id,
        phrase: choice.spokenPhrase,
        occurredAt: _now(),
      ),
    );
    notifyListeners();
    try {
      await speechService.speak(choice.spokenPhrase);
    } finally {
      _isActivating = false;
    }
    return true;
  }
}
