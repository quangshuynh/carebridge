import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/communication_models.dart';
import '../care_bridge_theme.dart';
import 'fitted_text.dart';

class CommunicationChoiceCard extends StatefulWidget {
  const CommunicationChoiceCard({
    required this.choice,
    required this.isSelected,
    required this.onActivate,
    super.key,
  });
  final CommunicationChoice choice;
  final bool isSelected;
  final VoidCallback onActivate;

  @override
  State<CommunicationChoiceCard> createState() =>
      _CommunicationChoiceCardState();
}

class _CommunicationChoiceCardState extends State<CommunicationChoiceCard> {
  bool _hasFocus = false;

  @override
  Widget build(BuildContext context) {
    final choice = widget.choice;
    final isSelected = widget.isSelected;
    final onActivate = widget.onActivate;
    final palette = CareBridgePalette.of(context);
    return Semantics(
      button: true,
      enabled: choice.isEnabled,
      selected: isSelected,
      label: choice.label,
      hint: 'Says: ${choice.spokenPhrase}',
      onTap: choice.isEnabled ? onActivate : null,
      excludeSemantics: true,
      child: Material(
        color: choice.visual.backgroundColor,
        // Selection appears at once rather than easing in.
        animationDuration: Duration.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: isSelected ? palette.outline : palette.idleBorder,
            width: isSelected
                ? palette.selectedBorderWidth
                : palette.idleBorderWidth,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: Key('choice-${choice.id}'),
          onTap: choice.isEnabled ? onActivate : null,
          onFocusChange: (hasFocus) => setState(() => _hasFocus = hasFocus),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final extent = constraints.biggest.shortestSide;
              final padding = (extent * 0.08).clamp(10.0, 24.0);
              final innerHeight = constraints.maxHeight - padding * 2;
              return Stack(
                children: [
                  Positioned.fill(
                    child: Padding(
                      padding: EdgeInsets.all(padding),
                      child: Column(
                        children: [
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, area) => Center(
                                child: Icon(
                                  choice.visual.icon,
                                  color: palette.outline,
                                  size: math.min(
                                    area.maxHeight,
                                    area.maxWidth * 0.62,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: padding * 0.5),
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight: innerHeight * 0.45,
                            ),
                            child: FittedText(
                              choice.label,
                              style: TextStyle(
                                color: palette.ink,
                                fontSize: (extent * 0.15).clamp(22.0, 40.0),
                                fontWeight: FontWeight.w800,
                                height: 1.1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (isSelected)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: _SelectedBadge(
                        size: (extent * 0.2).clamp(34.0, 52.0),
                        palette: palette,
                      ),
                    ),
                  // An inset ring, distinct in shape from the selected border
                  // and badge, shows where keyboard or switch focus is.
                  if (_hasFocus)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Padding(
                          padding: EdgeInsets.all(
                            palette.selectedBorderWidth + 2,
                          ),
                          child: DecoratedBox(
                            key: const Key('choice-focus-ring'),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: palette.focus,
                                width: 4,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SelectedBadge extends StatelessWidget {
  const _SelectedBadge({required this.size, required this.palette});
  final double size;
  final CareBridgePalette palette;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: palette.outline,
        shape: BoxShape.circle,
        // In high contrast a white ring keeps the black badge distinct from
        // the black selected border.
        border: palette.isHighContrast
            ? Border.all(color: palette.onSelectedSurface, width: 2)
            : null,
      ),
      child: Icon(
        Icons.check_rounded,
        key: const Key('selected-check'),
        color: palette.onSelectedSurface,
        size: size * 0.72,
      ),
    ),
  );
}
