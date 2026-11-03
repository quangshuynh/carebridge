import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../application/board_choices_controller.dart';
import '../../domain/board_choices.dart';
import '../../domain/choice_visual_catalog.dart';
import '../care_bridge_theme.dart';
import '../widgets/communication_choice_card.dart';
import 'caregiver_widgets.dart';
import 'choices_editor_screen.dart';

/// Adds a choice, or changes [editing]'s words and picture. Nothing is
/// saved until Save; leaving with unsaved changes asks first.
class ChoiceFormScreen extends StatefulWidget {
  const ChoiceFormScreen({required this.choices, this.editing, super.key});
  final BoardChoicesController choices;

  /// The choice being changed; null adds a new one.
  final BoardChoice? editing;

  @override
  State<ChoiceFormScreen> createState() => _ChoiceFormScreenState();
}

class _ChoiceFormScreenState extends State<ChoiceFormScreen> {
  late final TextEditingController _label = TextEditingController(
    text: widget.editing?.label ?? '',
  );
  late final TextEditingController _phrase = TextEditingController(
    text: widget.editing?.spokenPhrase ?? '',
  );
  // A new choice has no picture until the caregiver picks one: CareBridge
  // never guesses what a choice should look like.
  late String? _iconId = widget.editing?.iconId;
  late String _colorId =
      widget.editing?.colorId ?? ChoiceVisualCatalog.colors.first.id;

  String? _labelError;
  String? _phraseError;
  String? _iconError;
  String? _saveError;
  bool _isSaving = false;
  bool _isDone = false;

  // A line break or tab, typed or pasted, becomes a space so words on
  // either side never run together.
  static final _noLineBreaks = FilteringTextInputFormatter.deny(
    RegExp(r'[\r\n\t]'),
    replacementString: ' ',
  );

  bool get _hasChanges {
    final editing = widget.editing;
    if (editing == null) {
      return _label.text.trim().isNotEmpty ||
          _phrase.text.trim().isNotEmpty ||
          _iconId != null ||
          _colorId != ChoiceVisualCatalog.colors.first.id;
    }
    return BoardText.normalize(_label.text) != editing.label ||
        BoardText.normalize(_phrase.text) != editing.spokenPhrase ||
        _iconId != editing.iconId ||
        _colorId != editing.colorId;
  }

  @override
  void initState() {
    super.initState();
    // Rebuilds the preview as the caregiver types.
    _label.addListener(_refresh);
    _phrase.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    _label.dispose();
    _phrase.dispose();
    super.dispose();
  }

  static String? _textError(BoardChoicesProblem? problem) => switch (problem) {
    null => null,
    BoardChoicesProblem.blankLabel => 'Enter the words for the button.',
    BoardChoicesProblem.labelTooLong =>
      'Use ${BoardLimits.maxLabelLength} characters or fewer.',
    BoardChoicesProblem.blankPhrase => 'Enter what CareBridge should say.',
    BoardChoicesProblem.phraseTooLong =>
      'Use ${BoardLimits.maxPhraseLength} characters or fewer.',
    _ => 'Use letters, numbers, and punctuation only.',
  };

  Future<void> _save() async {
    if (_isSaving || _isDone) return;
    final label = BoardText.normalize(_label.text);
    final phrase = BoardText.normalize(_phrase.text);
    final iconId = _iconId;
    setState(() {
      _labelError = _textError(BoardText.labelProblem(label));
      _phraseError = _textError(BoardText.phraseProblem(phrase));
      _iconError = iconId == null ? 'Choose a picture.' : null;
      _saveError = null;
    });
    if (_labelError != null || _phraseError != null || iconId == null) return;
    final draft = ChoiceDraft(
      label: label,
      spokenPhrase: phrase,
      iconId: iconId,
      colorId: _colorId,
    );
    setState(() => _isSaving = true);
    final editing = widget.editing;
    final result = editing == null
        ? await widget.choices.add(draft)
        : await widget.choices.edit(editing.id, draft);
    if (!mounted) return;
    setState(() {
      _isSaving = false;
      switch (result.outcome) {
        case BoardEditOutcome.saved:
          _isDone = true;
        case BoardEditOutcome.ignored:
          _saveError = 'Another change is still saving. Try again.';
        case BoardEditOutcome.rejected || BoardEditOutcome.saveFailed:
          _saveError = boardEditMessage(result);
      }
    });
    if (_isDone) Navigator.of(context).pop();
  }

  Future<void> _confirmLeave() async {
    final discard = await confirmCaregiverAction(
      context,
      dialogKey: const Key('discard-confirmation'),
      title: 'Leave without saving?',
      message: 'The changes on this page will be lost.',
      cancelLabel: 'Keep editing',
      confirmLabel: 'Leave without saving',
      cancelKey: const Key('discard-cancel'),
      confirmKey: const Key('discard-confirm'),
    );
    if (!discard || !mounted) return;
    _isDone = true;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final palette = CareBridgePalette.of(context);
    final title = caregiverTitleStyle(context);
    final body = caregiverBodyStyle(context);
    final fieldStyle = TextStyle(color: palette.ink, fontSize: 22);
    final adding = widget.editing == null;
    final missing =
        _labelError != null || _phraseError != null || _iconError != null;
    final status =
        _saveError ??
        (missing
            ? 'Some details need attention. See the messages above.'
            : null);
    return PopScope(
      canPop: _isDone || !_hasChanges,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: CaregiverScaffold(
        title: adding ? 'New choice' : 'Change choice',
        listKey: const Key('choice-form-list'),
        status: status == null
            ? null
            : CaregiverStatus(
                key: const Key('choice-save-error'),
                message: status,
                isProblem: true,
              ),
        children: [
          Center(
            child: _Preview(
              label: _label.text,
              iconId: _iconId,
              colorId: _colorId,
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            key: const Key('choice-label-field'),
            controller: _label,
            style: fieldStyle,
            maxLength: BoardLimits.maxLabelLength,
            inputFormatters: [_noLineBreaks],
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'Words on the button',
              labelStyle: body,
              errorText: _labelError,
              errorStyle: body.copyWith(fontWeight: FontWeight.w700),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('choice-phrase-field'),
            controller: _phrase,
            style: fieldStyle,
            minLines: 2,
            maxLines: 4,
            maxLength: BoardLimits.maxPhraseLength,
            keyboardType: TextInputType.text,
            inputFormatters: [_noLineBreaks],
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: 'What CareBridge says',
              labelStyle: body,
              helperText: 'Spoken exactly as written.',
              helperStyle: body,
              errorText: _phraseError,
              errorStyle: body.copyWith(fontWeight: FontWeight.w700),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          Semantics(header: true, child: Text('Picture', style: title)),
          if (_iconError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _iconError!,
                key: const Key('choice-icon-error'),
                style: body.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in ChoiceVisualCatalog.icons)
                _IconOptionButton(
                  option: option,
                  selected: option.id == _iconId,
                  onSelect: () => setState(() {
                    _iconId = option.id;
                    _iconError = null;
                  }),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Semantics(header: true, child: Text('Color', style: title)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in ChoiceVisualCatalog.colors)
                _ColorOptionButton(
                  option: option,
                  selected: option.id == _colorId,
                  onSelect: () => setState(() => _colorId = option.id),
                ),
            ],
          ),
          const SizedBox(height: 32),
          CaregiverButton(
            key: const Key('choice-save'),
            icon: Icons.check_rounded,
            label: adding ? 'Add to board' : 'Save changes',
            filled: true,
            onPressed: _isSaving ? null : _save,
          ),
          const SizedBox(height: 12),
          CaregiverButton(
            key: const Key('choice-cancel'),
            icon: Icons.close_rounded,
            label: 'Cancel',
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
    );
  }
}

/// The button as it will look on the board, at a fixed size.
class _Preview extends StatelessWidget {
  const _Preview({
    required this.label,
    required this.iconId,
    required this.colorId,
  });
  final String label;
  final String? iconId;
  final String colorId;

  static const size = 160.0;

  @override
  Widget build(BuildContext context) {
    final icon = iconId == null ? null : ChoiceVisualCatalog.iconById(iconId!);
    final shownLabel = BoardText.normalize(label);
    final Widget preview;
    if (icon == null) {
      final palette = CareBridgePalette.of(context);
      preview = DecoratedBox(
        decoration: BoxDecoration(
          color: ChoiceVisualCatalog.colorById(colorId)!.color,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: palette.idleBorder, width: 2),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'Choose a picture below',
              textAlign: TextAlign.center,
              style: caregiverBodyStyle(context),
            ),
          ),
        ),
      );
    } else {
      preview = CommunicationChoiceCard(
        choice: BoardChoice(
          id: 'preview',
          label: shownLabel,
          spokenPhrase: '',
          iconId: icon.id,
          colorId: colorId,
        ).toCommunicationChoice(0),
        isSelected: false,
        onActivate: () {},
      );
    }
    return SizedBox.square(
      key: const Key('choice-form-preview'),
      dimension: size,
      child: ExcludeSemantics(child: IgnorePointer(child: preview)),
    );
  }
}

class _IconOptionButton extends StatelessWidget {
  const _IconOptionButton({
    required this.option,
    required this.selected,
    required this.onSelect,
  });
  final ChoiceIconOption option;
  final bool selected;
  final VoidCallback onSelect;

  static const size = 72.0;

  @override
  Widget build(BuildContext context) {
    final palette = CareBridgePalette.of(context);
    return Semantics(
      button: true,
      inMutuallyExclusiveGroup: true,
      selected: selected,
      label: option.name,
      onTap: onSelect,
      excludeSemantics: true,
      child: Material(
        color: selected ? palette.selectedSurface : palette.surface,
        animationDuration: Duration.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selected || palette.isHighContrast
                ? palette.outline
                : palette.idleBorder,
            width: selected ? 4 : palette.idleBorderWidth,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: Key('choice-icon-${option.id}'),
          onTap: onSelect,
          child: SizedBox.square(
            dimension: size,
            child: Icon(
              option.icon,
              size: size * 0.6,
              color: selected ? palette.onSelectedSurface : palette.ink,
            ),
          ),
        ),
      ),
    );
  }
}

class _ColorOptionButton extends StatelessWidget {
  const _ColorOptionButton({
    required this.option,
    required this.selected,
    required this.onSelect,
  });
  final ChoiceColorOption option;
  final bool selected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final palette = CareBridgePalette.of(context);
    return Semantics(
      button: true,
      inMutuallyExclusiveGroup: true,
      selected: selected,
      label: option.name,
      onTap: onSelect,
      excludeSemantics: true,
      child: Material(
        color: palette.surface,
        animationDuration: Duration.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selected || palette.isHighContrast
                ? palette.outline
                : palette.idleBorder,
            width: selected ? 4 : palette.idleBorderWidth,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: Key('choice-color-${option.id}'),
          onTap: onSelect,
          child: SizedBox(
            width: 96,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: option.color,
                      shape: BoxShape.circle,
                      border: Border.all(color: palette.outline, width: 2),
                    ),
                    // The selected color is marked by more than its border.
                    child: selected
                        ? Icon(
                            Icons.check_rounded,
                            color: palette.outline,
                            size: 32,
                          )
                        : null,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    option.name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: palette.ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
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
