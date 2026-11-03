import 'package:flutter/material.dart';

import '../../application/board_choices_controller.dart';
import '../caregiver_route.dart';
import '../widgets/communication_choice_card.dart';
import 'caregiver_widgets.dart';
import 'choice_form_screen.dart';
import 'choices_editor_screen.dart';

/// One choice: a preview, then buttons that stay in the same place however
/// often they are used, so moving a choice never moves the button under the
/// caregiver's finger. What changed is described below the buttons.
class ChoiceDetailScreen extends StatelessWidget {
  const ChoiceDetailScreen({
    required this.choices,
    required this.choiceId,
    super.key,
  });
  final BoardChoicesController choices;
  final String choiceId;

  static const previewSize = 180.0;

  Future<void> _edit(BuildContext context) async {
    final choice = choices.board.byId(choiceId);
    if (choice == null) return;
    choices.clearResult();
    await Navigator.of(context).push(
      caregiverRoute<void>(
        context,
        (context) => ChoiceFormScreen(choices: choices, editing: choice),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: choices,
    builder: (context, _) {
      final board = choices.board;
      final index = board.indexOf(choiceId);
      final choice = index < 0 ? null : board.choices[index];
      final body = caregiverBodyStyle(context);
      if (choice == null) {
        return CaregiverScaffold(
          title: 'Choice',
          children: [
            Text(
              'This choice is no longer on the board.',
              key: const Key('choice-missing'),
              style: body,
            ),
            const SizedBox(height: 16),
            CaregiverButton(
              key: const Key('choice-back-to-board'),
              icon: Icons.arrow_back_rounded,
              label: 'Back to board',
              filled: true,
              onPressed: () => goBackToBoard(context),
            ),
          ],
        );
      }
      // Buttons stay enabled while a change saves, so keyboard and switch
      // focus is never lost; a request made meanwhile is ignored.
      final ready = choices.isLoaded;
      final shown = choice.isVisible;
      final place =
          'Position ${index + 1} of ${board.choices.length}. '
          '${shown ? 'On the board.' : 'Hidden from the board.'}';
      final result = choices.lastResult;
      // A saved change is described by where the choice now is.
      final message = result?.outcome == BoardEditOutcome.saved
          ? 'Saved. $place'
          : boardEditMessage(result);
      return CaregiverScaffold(
        title: choice.label,
        listKey: const Key('choice-detail-list'),
        status: message == null
            ? null
            : CaregiverStatus(
                key: const Key('choice-status'),
                message: message,
                isProblem: result?.outcome != BoardEditOutcome.saved,
              ),
        children: [
          Center(
            child: SizedBox.square(
              dimension: previewSize,
              // The preview is only a picture here; the words are below.
              child: ExcludeSemantics(
                child: IgnorePointer(
                  child: CommunicationChoiceCard(
                    key: const Key('choice-preview'),
                    choice: choice
                        .copyWith(isVisible: true)
                        .toCommunicationChoice(index),
                    isSelected: false,
                    onActivate: () {},
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          CaregiverButton(
            key: const Key('choice-edit'),
            icon: Icons.edit_rounded,
            label: 'Change words or picture',
            onPressed: ready ? () => _edit(context) : null,
          ),
          const SizedBox(height: 12),
          CaregiverButton(
            key: const Key('choice-move-earlier'),
            icon: Icons.arrow_upward_rounded,
            label: 'Move earlier',
            onPressed: ready && index > 0
                ? () => choices.move(choiceId, -1)
                : null,
          ),
          const SizedBox(height: 12),
          CaregiverButton(
            key: const Key('choice-move-later'),
            icon: Icons.arrow_downward_rounded,
            label: 'Move later',
            onPressed: ready && index < board.choices.length - 1
                ? () => choices.move(choiceId, 1)
                : null,
          ),
          const SizedBox(height: 12),
          CaregiverButton(
            key: const Key('choice-visibility'),
            icon: shown
                ? Icons.visibility_off_rounded
                : Icons.visibility_rounded,
            label: shown ? 'Hide from board' : 'Show on board',
            onPressed: ready
                ? () => choices.setVisible(choiceId, visible: !shown)
                : null,
          ),
          const SizedBox(height: 12),
          CaregiverButton(
            key: const Key('choice-back-to-board'),
            icon: Icons.arrow_back_rounded,
            label: 'Back to board',
            filled: true,
            onPressed: () => goBackToBoard(context),
          ),
          const SizedBox(height: 24),
          Text('Says: ${choice.spokenPhrase}', style: body),
          const SizedBox(height: 8),
          Text(
            place,
            key: const Key('choice-place'),
            style: body.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      );
    },
  );
}
