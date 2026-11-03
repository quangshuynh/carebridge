import 'package:flutter/material.dart';

import '../application/board_backup_controller.dart';
import '../domain/board_backup.dart';
import '../domain/display_preferences.dart';
import 'care_bridge_theme.dart';

/// The words shown for each backup outcome. Every failure says that nothing
/// changed, because nothing does.
String backupOutcomeMessage(
  BackupOutcome outcome,
  BoardBackupProblem? problem,
) {
  switch (outcome) {
    case BackupOutcome.exported:
      return 'Backup saved. Your settings are unchanged.';
    case BackupOutcome.exportCancelled:
      return 'Export cancelled. No file was saved.';
    case BackupOutcome.exportFailed:
      return 'The backup could not be saved there. Try another place. '
          'Your settings are unchanged.';
    case BackupOutcome.imported:
      return 'Backup imported. Your settings were replaced.';
    case BackupOutcome.importCancelled:
      return 'Import cancelled. Nothing was changed.';
    case BackupOutcome.importUnreadable:
      return 'That file could not be opened. Nothing was changed.';
    case BackupOutcome.importFailed:
      return 'The backup could not be applied. Your previous settings are '
          'kept.';
    case BackupOutcome.importRejected:
      return switch (problem) {
        BoardBackupProblem.tooLarge =>
          'That file is too large to be a CareBridge backup. '
              'Nothing was changed.',
        BoardBackupProblem.newerVersion =>
          'That backup is from a newer version of CareBridge. Update '
              'CareBridge, then try again. Nothing was changed.',
        BoardBackupProblem.invalidContent =>
          'That backup is damaged or has settings CareBridge does not '
              'support. Nothing was changed.',
        BoardBackupProblem.notBackup ||
        null => 'That file is not a CareBridge backup. Nothing was changed.',
      };
  }
}

/// Export and import for caregivers, below the other settings. Only shown in
/// settings, never on the board.
class BackupSettingsSection extends StatelessWidget {
  const BackupSettingsSection({
    required this.controller,
    required this.textStyle,
    super.key,
  });
  final BoardBackupController controller;
  final TextStyle textStyle;

  Future<void> _import(BuildContext context) async {
    final backup = await controller.chooseImport();
    if (backup == null) return;
    var confirmed = false;
    try {
      if (context.mounted) {
        confirmed =
            await showDialog<bool>(
              context: context,
              animationStyle: MediaQuery.disableAnimationsOf(context)
                  ? AnimationStyle.noAnimation
                  : null,
              builder: (context) => ImportConfirmationDialog(
                current: controller.current,
                incoming: backup,
              ),
            ) ??
            false;
      }
    } finally {
      if (confirmed) {
        await controller.applyImport(backup);
      } else {
        controller.declineImport();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = CareBridgePalette.of(context);
    final bodyStyle = TextStyle(color: palette.ink, fontSize: 18);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final busy = controller.isBusy;
        final outcome = controller.outcome;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              container: true,
              header: true,
              child: Text('Backup', style: textStyle),
            ),
            const SizedBox(height: 8),
            Text(
              'Save these settings to a file you keep, or replace them '
              'from a CareBridge backup file. The built-in choices on the '
              'board are not part of a backup and always stay.',
              style: bodyStyle,
            ),
            const SizedBox(height: 16),
            _BackupButton(
              key: const Key('backup-export'),
              icon: Icons.save_alt_rounded,
              label: 'Export board backup',
              textStyle: textStyle,
              onPressed: busy ? null : controller.export,
            ),
            const SizedBox(height: 12),
            _BackupButton(
              key: const Key('backup-import'),
              icon: Icons.restore_page_rounded,
              label: 'Import board backup',
              textStyle: textStyle,
              onPressed: busy ? null : () => _import(context),
            ),
            // Below both buttons, so a message never moves them.
            if (outcome != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: _BackupStatus(
                  outcome: outcome,
                  message: backupOutcomeMessage(outcome, controller.problem),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _BackupButton extends StatelessWidget {
  const _BackupButton({
    required this.icon,
    required this.label,
    required this.textStyle,
    required this.onPressed,
    super.key,
  });
  final IconData icon;
  final String label;
  final TextStyle textStyle;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = CareBridgePalette.of(context);
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(72),
        alignment: AlignmentDirectional.centerStart,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        backgroundColor: palette.surface,
        foregroundColor: palette.ink,
        textStyle: textStyle,
        side: BorderSide(
          color: palette.outline,
          width: palette.isHighContrast ? 3 : 2,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      onPressed: onPressed,
      icon: Icon(icon, size: 36),
      label: Text(label),
    );
  }
}

class _BackupStatus extends StatelessWidget {
  const _BackupStatus({required this.outcome, required this.message});
  final BackupOutcome outcome;
  final String message;

  bool get _succeeded =>
      outcome == BackupOutcome.exported || outcome == BackupOutcome.imported;

  bool get _cancelled =>
      outcome == BackupOutcome.exportCancelled ||
      outcome == BackupOutcome.importCancelled;

  @override
  Widget build(BuildContext context) {
    final palette = CareBridgePalette.of(context);
    final icon = _succeeded
        ? Icons.check_circle_rounded
        : _cancelled
        ? Icons.info_rounded
        : Icons.error_rounded;
    // Announced by screen readers when it appears or changes.
    return Semantics(
      key: const Key('backup-status'),
      container: true,
      liveRegion: true,
      label: message,
      child: ExcludeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: palette.ink, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: palette.ink,
                  fontSize: 20,
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

/// Shows exactly what an import would change and asks before replacing.
class ImportConfirmationDialog extends StatelessWidget {
  const ImportConfirmationDialog({
    required this.current,
    required this.incoming,
    super.key,
  });
  final BoardBackup current;
  final BoardBackup incoming;

  static String _onOff(bool value) => value ? 'On' : 'Off';

  @override
  Widget build(BuildContext context) {
    final palette = CareBridgePalette.of(context);
    final isTablet = MediaQuery.sizeOf(context).shortestSide >= 600;
    final titleStyle = TextStyle(
      color: palette.ink,
      fontSize: isTablet ? 28 : 24,
      fontWeight: FontWeight.w800,
    );
    final bodyStyle = TextStyle(color: palette.ink, fontSize: 20);
    final DisplayPreferences now = current.displayPreferences;
    final DisplayPreferences after = incoming.displayPreferences;
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    );
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 2,
      child: AlertDialog(
        key: const Key('import-confirmation'),
        scrollable: true,
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: palette.outline,
            width: palette.isHighContrast ? 3 : 2,
          ),
        ),
        title: Text('Replace current settings?', style: titleStyle),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'The settings on this device will be replaced by the ones in '
              'this backup.',
              style: bodyStyle,
            ),
            const SizedBox(height: 16),
            Text(
              'High contrast: ${_onOff(now.highContrast)} now, '
              '${_onOff(after.highContrast)} after import.',
              key: const Key('import-summary-high-contrast'),
              style: bodyStyle.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            Text(
              'The built-in choices on the board stay the same.',
              style: bodyStyle,
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              key: const Key('import-cancel'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(72),
                foregroundColor: palette.ink,
                backgroundColor: palette.surface,
                textStyle: titleStyle,
                side: BorderSide(color: palette.outline, width: 2),
                shape: buttonShape,
              ),
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Keep current settings'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              key: const Key('import-confirm'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(72),
                backgroundColor: palette.selectedSurface,
                foregroundColor: palette.onSelectedSurface,
                textStyle: titleStyle,
                shape: buttonShape,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Replace settings'),
            ),
          ],
        ),
      ),
    );
  }
}
