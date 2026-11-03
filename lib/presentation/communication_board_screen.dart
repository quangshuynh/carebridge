import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../application/board_backup_controller.dart';
import '../application/board_choices_controller.dart';
import '../application/communication_board_controller.dart';
import '../application/display_preferences_controller.dart';
import '../domain/communication_models.dart';
import 'board_grid_layout.dart';
import 'caregiver_route.dart';
import 'settings_screen.dart';
import 'widgets/communication_choice_card.dart';
import 'widgets/communication_confirmation.dart';
import 'widgets/settings_hold_button.dart';

class CommunicationBoardScreen extends StatelessWidget {
  const CommunicationBoardScreen({
    required this.controller,
    this.profile,
    this.choices,
    required this.displayPreferences,
    this.backup,
    super.key,
  });

  /// A fixed board. When null, the board shows [choices].
  final CommunicatorProfile? profile;

  /// The caregiver's choices, editable from settings. One of [profile] or
  /// [choices] is given.
  final BoardChoicesController? choices;
  final CommunicationBoardController controller;
  final DisplayPreferencesController displayPreferences;

  /// Export and import in settings. Null leaves them out.
  final BoardBackupController? backup;

  /// Below this height a landscape screen moves confirmation beside the
  /// board, leaving the full height for the choices.
  static const sidePanelMaxHeight = 560.0;

  /// Leaving the board stops speech, like leaving the app, so a phrase never
  /// plays over settings or late after returning. The selection is kept.
  /// A repeated request while settings is already opening is ignored.
  Future<void> _openSettings(BuildContext context) async {
    if (ModalRoute.of(context)?.isCurrent == false) return;
    controller.stopSpeech();
    backup?.clearOutcome();
    choices?.clearResult();
    await Navigator.of(context).push(
      caregiverRoute<void>(
        context,
        (context) => SettingsScreen(
          preferences: displayPreferences,
          choices: choices,
          backup: backup,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.sizeOf(context).shortestSide >= 600;
    final gutter = isTablet ? 24.0 : 16.0;
    final spacing = isTablet ? 20.0 : 12.0;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Padding(
                padding: EdgeInsets.all(gutter),
                child: ListenableBuilder(
                  listenable: Listenable.merge([controller, choices]),
                  builder: (context, _) => LayoutBuilder(
                    builder: (context, constraints) => _BoardLayout(
                      area: constraints.biggest,
                      spacing: spacing,
                      confirmation: (direction) => CommunicationConfirmation(
                        choice: controller.selectedChoice,
                        direction: direction,
                      ),
                      settings: SettingsHoldButton(
                        onOpen: () => _openSettings(context),
                      ),
                      grid: _ChoiceGrid(
                        choices: (profile ?? choices!.profile).enabledChoices,
                        selectedId: controller.selectedChoice?.id,
                        spacing: spacing,
                        onActivate: controller.activate,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Places the confirmation above the board, or beside it when a landscape
/// screen is short, at a size that never depends on the phrase shown. The
/// settings button sits at the end of the confirmation band, away from the
/// choices.
class _BoardLayout extends StatelessWidget {
  const _BoardLayout({
    required this.area,
    required this.spacing,
    required this.confirmation,
    required this.settings,
    required this.grid,
  });
  final Size area;
  final double spacing;
  final Widget Function(Axis direction) confirmation;
  final Widget settings;
  final Widget grid;

  @override
  Widget build(BuildContext context) {
    final useSidePanel =
        area.width > area.height &&
        area.height < CommunicationBoardScreen.sidePanelMaxHeight;
    if (useSidePanel) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: (area.width * 0.28).clamp(140.0, 280.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: confirmation(Axis.vertical)),
                SizedBox(height: spacing),
                Center(child: settings),
              ],
            ),
          ),
          SizedBox(width: spacing),
          Expanded(child: grid),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: (area.height * 0.14).clamp(80.0, 136.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: confirmation(Axis.horizontal)),
              SizedBox(width: spacing),
              Center(child: settings),
            ],
          ),
        ),
        SizedBox(height: spacing),
        Expanded(child: grid),
      ],
    );
  }
}

class _ChoiceGrid extends StatelessWidget {
  const _ChoiceGrid({
    required this.choices,
    required this.selectedId,
    required this.spacing,
    required this.onActivate,
  });
  final List<CommunicationChoice> choices;
  final String? selectedId;
  final double spacing;
  final void Function(CommunicationChoice choice) onActivate;

  static const minCellExtent = 110.0;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final layout = BoardGridLayout.resolve(
        itemCount: choices.length,
        area: constraints.biggest,
        spacing: spacing,
        minCellExtent: minCellExtent,
      );
      return GridView.builder(
        key: const Key('communication-grid'),
        padding: EdgeInsets.zero,
        // A board that fits never scrolls, so a drag cannot shift targets.
        physics: layout.scrolls
            ? const ClampingScrollPhysics()
            : const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: layout.columns,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          mainAxisExtent: layout.cellSize.height,
        ),
        itemCount: choices.length,
        itemBuilder: (context, index) {
          final choice = choices[index];
          return CommunicationChoiceCard(
            choice: choice,
            isSelected: choice.id == selectedId,
            onActivate: () => onActivate(choice),
          );
        },
      );
    },
  );
}
