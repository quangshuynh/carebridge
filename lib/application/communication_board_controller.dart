import 'package:flutter/foundation.dart';

import '../domain/communication_models.dart';
import '../services/speech_service.dart';

class CommunicationBoardController extends ChangeNotifier {
  CommunicationBoardController({
    required this.speechService,
    DateTime Function()? now,
    this.duplicateActivationWindow = const Duration(milliseconds: 600),
  }) : _now = now ?? DateTime.now;
  final SpeechService speechService;
  final DateTime Function() _now;
  final Duration duplicateActivationWindow;
  CommunicationChoice? _selectedChoice;
  String? _lastActivatedChoiceId;
  DateTime? _lastActivatedAt;
  final List<CommunicationEvent> _sessionEvents = [];

  CommunicationChoice? get selectedChoice => _selectedChoice;
  List<CommunicationEvent> get sessionEvents =>
      List.unmodifiable(_sessionEvents);

  Future<bool> activate(CommunicationChoice choice) async {
    if (!choice.isEnabled) return false;
    final activatedAt = _now();
    final isRapidDuplicate =
        _lastActivatedChoiceId == choice.id &&
        _lastActivatedAt != null &&
        activatedAt.difference(_lastActivatedAt!) < duplicateActivationWindow;
    if (isRapidDuplicate) return false;

    _lastActivatedChoiceId = choice.id;
    _lastActivatedAt = activatedAt;
    _selectedChoice = choice;
    _sessionEvents.add(
      CommunicationEvent(
        choiceId: choice.id,
        phrase: choice.spokenPhrase,
        occurredAt: activatedAt,
      ),
    );
    notifyListeners();
    try {
      await speechService.speak(choice.spokenPhrase);
    } catch (_) {
      // Speech is an enhancement. Visual communication remains successful
      // when a platform voice is unavailable or fails.
    }
    return true;
  }
}
