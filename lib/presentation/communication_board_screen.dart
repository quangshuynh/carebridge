import 'package:flutter/material.dart';

import '../application/communication_board_controller.dart';
import '../domain/communication_models.dart';
import 'widgets/communication_choice_card.dart';

class CommunicationBoardScreen extends StatefulWidget {
  const CommunicationBoardScreen({
    required this.profile,
    required this.controller,
    super.key,
  });
  final CommunicatorProfile profile;
  final CommunicationBoardController controller;

  @override
  State<CommunicationBoardScreen> createState() =>
      _CommunicationBoardScreenState();
}

class _CommunicationBoardScreenState extends State<CommunicationBoardScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
  }

  @override
  void didUpdateWidget(CommunicationBoardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_refresh);
      widget.controller.addListener(_refresh);
    }
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final choices = widget.profile.enabledChoices;
    final selected = widget.controller.selectedChoice;
    final isWide = MediaQuery.sizeOf(context).width >= 700;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                isWide ? 32 : 16,
                16,
                isWide ? 32 : 16,
                20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.profile.displayName,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF173A37),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ConfirmationBanner(choice: selected),
                  const SizedBox(height: 16),
                  Expanded(
                    child: GridView.builder(
                      key: const Key('communication-grid'),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isWide ? 3 : 2,
                        crossAxisSpacing: isWide ? 20 : 12,
                        mainAxisSpacing: isWide ? 20 : 12,
                        childAspectRatio: isWide ? 1.18 : 0.92,
                      ),
                      itemCount: choices.length,
                      itemBuilder: (context, index) {
                        final choice = choices[index];
                        return CommunicationChoiceCard(
                          choice: choice,
                          isSelected: choice.id == selected?.id,
                          onActivate: () => widget.controller.activate(choice),
                        );
                      },
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

class _ConfirmationBanner extends StatelessWidget {
  const _ConfirmationBanner({required this.choice});
  final CommunicationChoice? choice;

  @override
  Widget build(BuildContext context) {
    final phrase = choice?.spokenPhrase ?? 'Choose what you want to say';
    return Semantics(
      liveRegion: choice != null,
      label: choice == null ? phrase : 'Selected. $phrase',
      child: AnimatedContainer(
        key: const Key('confirmation-banner'),
        duration: const Duration(milliseconds: 180),
        constraints: const BoxConstraints(minHeight: 72),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: choice == null ? Colors.white : const Color(0xFF245D58),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF245D58), width: 2),
        ),
        child: Row(
          children: [
            Icon(
              choice == null
                  ? Icons.touch_app_rounded
                  : Icons.volume_up_rounded,
              color: choice == null ? const Color(0xFF245D58) : Colors.white,
              size: 32,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                phrase,
                key: const Key('confirmation-phrase'),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: choice == null
                      ? const Color(0xFF173A37)
                      : Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
