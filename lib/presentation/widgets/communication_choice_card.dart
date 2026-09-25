import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/communication_models.dart';
import '../care_bridge_theme.dart';
import 'fitted_text.dart';

class CommunicationChoiceCard extends StatelessWidget {
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
  Widget build(BuildContext context) => Semantics(
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
          color: isSelected
              ? CareBridgeColors.outline
              : CareBridgeColors.outline.withAlpha(0x33),
          width: isSelected ? 6 : 2,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: Key('choice-${choice.id}'),
        onTap: choice.isEnabled ? onActivate : null,
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
                                color: CareBridgeColors.outline,
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
                              color: CareBridgeColors.ink,
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

class _SelectedBadge extends StatelessWidget {
  const _SelectedBadge({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: CareBridgeColors.outline,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.check_rounded,
        key: const Key('selected-check'),
        color: Colors.white,
        size: size * 0.72,
      ),
    ),
  );
}
