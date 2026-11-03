import 'package:flutter/material.dart';

import 'application/board_backup_controller.dart';
import 'application/board_choices_controller.dart';
import 'application/communication_board_controller.dart';
import 'application/display_preferences_controller.dart';
import 'domain/communication_models.dart';
import 'presentation/care_bridge_theme.dart';
import 'presentation/communication_board_screen.dart';
import 'services/backup_files.dart';
import 'services/board_choices_store.dart';
import 'services/display_preferences_store.dart';
import 'services/speech_service.dart';
import 'services/tactile_feedback.dart';

class CareBridgeApp extends StatefulWidget {
  const CareBridgeApp({
    required this.speechService,
    this.tactileFeedback,
    this.displayPreferencesStore,
    this.backupFiles,
    this.boardChoicesStore,
    this.profile,
    this.now,
    super.key,
  });
  final SpeechService speechService;
  final TactileFeedback? tactileFeedback;

  /// Where display preferences are kept. Null keeps them in memory only.
  final DisplayPreferencesStore? displayPreferencesStore;

  /// Where caregivers save and open backups. Null leaves backup out of
  /// settings.
  final BackupFiles? backupFiles;

  /// Where the caregiver's choices are kept. Null keeps them in memory only.
  final BoardChoicesStore? boardChoicesStore;

  /// A fixed board shown instead of the caregiver's choices, which cannot
  /// be changed or backed up. Null, the default, shows the caregiver's
  /// choices: the original six until they are changed.
  final CommunicatorProfile? profile;

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
  late final BoardChoicesController? _choices = widget.profile == null
      ? BoardChoicesController(store: widget.boardChoicesStore)
      : null;
  late final BoardBackupController? _backup = switch ((
    widget.backupFiles,
    _choices,
  )) {
    (final files?, final choices?) => BoardBackupController(
      files: files,
      preferences: _displayPreferences,
      choices: choices,
      now: widget.now,
    ),
    _ => null,
  };

  // Speech stops when CareBridge leaves the screen so it cannot resume or
  // play late after returning. What was communicated stays selected.
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onHide: _controller.stopSpeech);
    // Not awaited: the board is usable at once in the standard display,
    // with the original choices until saved ones are read.
    _displayPreferences.load();
    _choices?.addListener(_onBoardChanged);
    _choices?.load();
  }

  void _onBoardChanged() {
    final choices = _choices;
    if (choices == null) return;
    _controller.retainSelectionIn(choices.profile.enabledChoices);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _controller.dispose();
    _backup?.dispose();
    _choices?.removeListener(_onBoardChanged);
    _choices?.dispose();
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
        choices: _choices,
        controller: _controller,
        displayPreferences: _displayPreferences,
        backup: _backup,
      ),
    ),
  );
}
