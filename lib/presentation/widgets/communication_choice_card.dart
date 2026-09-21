import 'package:flutter/material.dart';

import '../../domain/communication_models.dart';

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
      elevation: isSelected ? 8 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: isSelected ? const Color(0xFF173A37) : const Color(0x40173A37),
          width: isSelected ? 5 : 2,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: Key('choice-${choice.id}'),
        onTap: choice.isEnabled ? onActivate : null,
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: Icon(
                          choice.visual.icon,
                          color: const Color(0xFF173A37),
                          size: 96,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      choice.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: const Color(0xFF102B29),
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            if (isSelected)
              const Positioned(
                right: 10,
                top: 10,
                child: ExcludeSemantics(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Color(0xFF173A37),
                      shape: BoxShape.circle,
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(5),
                      child: Icon(
                        Icons.check_rounded,
                        key: Key('selected-check'),
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
