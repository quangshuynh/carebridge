import 'package:flutter/material.dart';

import '../../application/board_choices_controller.dart';
import '../../domain/board_choices.dart';
import '../care_bridge_theme.dart';
import '../caregiver_route.dart';
import 'caregiver_widgets.dart';
import 'choice_detail_screen.dart';
import 'choice_form_screen.dart';

/// What the caregiver is told after a change. Null when nothing is said.
String? boardEditMessage(BoardEditResult? result) {
  switch (result?.outcome) {
    case null || BoardEditOutcome.ignored:
      return null;
    case BoardEditOutcome.saved:
      return 'Saved. The board shows this change.';
    case BoardEditOutcome.saveFailed:
      return 'This change could not be saved. Nothing changed. Try again.';
    case BoardEditOutcome.rejected:
      return switch (result!.problem) {
        BoardChoicesProblem.noneVisible =>
          'At least one choice must stay on the board. Nothing changed.',
        BoardChoicesProblem.tooMany =>
          'The board already has the most choices it can hold '
              '(${BoardLimits.maxChoices}). Nothing changed.',
        BoardChoicesProblem.unknownChoice =>
          'That choice is no longer on the board. Nothing changed.',
        _ => 'That change is not allowed. Nothing changed.',
      };
  }
}

bool _isProblem(BoardEditResult? result) =>
    result != null && result.outcome != BoardEditOutcome.saved;

/// Every choice on the board, shown or hidden, in board order. Each opens
/// its own page; nothing here moves or changes on a single tap.
class ChoicesEditorScreen extends StatelessWidget {
  const ChoicesEditorScreen({required this.choices, super.key});
  final BoardChoicesController choices;

  Future<void> _open(BuildContext context, String id) async {
    choices.clearResult();
    await Navigator.of(context).push(
      caregiverRoute<void>(
        context,
        (context) => ChoiceDetailScreen(choices: choices, choiceId: id),
      ),
    );
  }

  Future<void> _add(BuildContext context) async {
    choices.clearResult();
    await Navigator.of(context).push(
      caregiverRoute<void>(
        context,
        (context) => ChoiceFormScreen(choices: choices),
      ),
    );
  }

  Future<void> _restore(BuildContext context) async {
    final added = choices.board.choices
        .where((choice) => BoardChoices.original.byId(choice.id) == null)
        .length;
    final confirmed = await confirmCaregiverAction(
      context,
      dialogKey: const Key('restore-original-confirmation'),
      title: 'Restore the original six choices?',
      message:
          'Food, Drink, Drive, Help, Rest, and Finished come back with '
          'their original words, pictures, and order. '
          '${added == 0 ? 'Changes' : 'The $added added ${added == 1 ? 'choice' : 'choices'} and changes'} '
          'you made are removed. Export a backup first to keep them.',
      cancelLabel: 'Keep my choices',
      confirmLabel: 'Restore original',
      cancelKey: const Key('restore-original-cancel'),
      confirmKey: const Key('restore-original-confirm'),
    );
    if (confirmed) await choices.restoreOriginal();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: choices,
    builder: (context, _) {
      final board = choices.board.choices;
      // Buttons stay enabled while a change saves, so keyboard and switch
      // focus is never lost; a request made meanwhile is ignored.
      final ready = choices.isLoaded;
      final message = boardEditMessage(choices.lastResult);
      return CaregiverScaffold(
        title: 'Choices',
        listKey: const Key('choices-editor-list'),
        status: message == null
            ? null
            : CaregiverStatus(
                key: const Key('choices-status'),
                message: message,
                isProblem: _isProblem(choices.lastResult),
              ),
        children: [
          CaregiverButton(
            key: const Key('choices-back-to-board'),
            icon: Icons.arrow_back_rounded,
            label: 'Back to board',
            filled: true,
            onPressed: () => goBackToBoard(context),
          ),
          const SizedBox(height: 16),
          Text(
            'Choose a choice to change its words, picture, place, or '
            'whether it is shown. Changes are saved at once.',
            style: caregiverBodyStyle(context),
          ),
          if (choices.loadFailed) ...[
            const SizedBox(height: 12),
            Text(
              'Saved choices could not be read, so the original choices are '
              'shown. Changing a choice replaces what was saved.',
              key: const Key('choices-load-problem'),
              style: caregiverBodyStyle(context)
                  .copyWith(fontWeight: FontWeight.w700),
            ),
          ],
          const SizedBox(height: 16),
          for (var i = 0; i < board.length; i++) ...[
            _ChoiceRow(
              choice: board[i],
              position: i + 1,
              count: board.length,
              onOpen: ready ? () => _open(context, board[i].id) : null,
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 12),
          CaregiverButton(
            key: const Key('choices-add'),
            icon: Icons.add_rounded,
            label: 'Add a choice',
            onPressed: ready && !choices.board.isFull
                ? () => _add(context)
                : null,
          ),
          if (choices.board.isFull) ...[
            const SizedBox(height: 8),
            Text(
              'The board holds at most ${BoardLimits.maxChoices} choices. '
              'Hide a choice or restore the original six to make room.',
              key: const Key('choices-full'),
              style: caregiverBodyStyle(context),
            ),
          ],
          const SizedBox(height: 32),
          CaregiverButton(
            key: const Key('choices-restore-original'),
            icon: Icons.settings_backup_restore_rounded,
            label: 'Restore original six choices',
            onPressed: ready ? () => _restore(context) : null,
          ),
        ],
      );
    },
  );
}

/// One choice as a large button: its picture, words, and whether it is
/// shown, read by screen readers as one sentence.
class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({
    required this.choice,
    required this.position,
    required this.count,
    required this.onOpen,
  });
  final BoardChoice choice;
  final int position;
  final int count;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final palette = CareBridgePalette.of(context);
    final shown = choice.isVisible;
    return Semantics(
      button: true,
      enabled: onOpen != null,
      label:
          '${choice.label}. Says: ${_asSentence(choice.spokenPhrase)} '
          '${shown ? 'On the board' : 'Hidden from the board'}. '
          'Position $position of $count.',
      onTapHint: 'change this choice',
      onTap: onOpen,
      excludeSemantics: true,
      child: Material(
        color: palette.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: palette.isHighContrast
                ? palette.outline
                : palette.idleBorder,
            width: palette.idleBorderWidth,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: Key('choices-row-${choice.id}'),
          onTap: onOpen,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 96),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  ChoiceSwatch(choice: choice, size: 72),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(choice.label, style: caregiverTitleStyle(context)),
                        Text(
                          choice.spokenPhrase,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: caregiverBodyStyle(context),
                        ),
                        if (!shown)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.visibility_off_rounded,
                                  color: palette.ink,
                                  size: 24,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'Hidden',
                                    key: Key('choices-hidden-${choice.id}'),
                                    style: caregiverBodyStyle(context)
                                        .copyWith(fontWeight: FontWeight.w800),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: palette.ink,
                    size: 36,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// [text] ending in a full stop unless it already ends a sentence, so it
/// is read with a natural pause.
String _asSentence(String text) =>
    RegExp(r'[.!?。！？]$').hasMatch(text) ? text : '$text.';

/// A choice's picture on its color, as on the board.
class ChoiceSwatch extends StatelessWidget {
  const ChoiceSwatch({required this.choice, required this.size, super.key});
  final BoardChoice choice;
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = CareBridgePalette.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: choice.colorOption.color,
        borderRadius: BorderRadius.circular(size * 0.22),
        border: Border.all(
          color: palette.isHighContrast ? palette.outline : palette.idleBorder,
          width: palette.idleBorderWidth,
        ),
      ),
      child: Icon(
        choice.iconOption.icon,
        color: palette.outline,
        size: size * 0.6,
      ),
    );
  }
}
