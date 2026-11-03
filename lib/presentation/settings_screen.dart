import 'package:flutter/material.dart';

import '../application/board_backup_controller.dart';
import '../application/board_choices_controller.dart';
import '../application/display_preferences_controller.dart';
import 'backup_settings_section.dart';
import 'care_bridge_theme.dart';
import 'caregiver_route.dart';
import 'choices/caregiver_widgets.dart';
import 'choices/choices_editor_screen.dart';

/// Caregiver-facing display settings, reached from the board by a
/// deliberate hold. Changes apply at once and are kept on the device.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    required this.preferences,
    this.choices,
    this.backup,
    super.key,
  });
  final DisplayPreferencesController preferences;

  /// The caregiver's choices. Null hides the choices section.
  final BoardChoicesController? choices;

  /// Export and import. Null hides the backup section.
  final BoardBackupController? backup;

  @override
  Widget build(BuildContext context) {
    final palette = CareBridgePalette.of(context);
    final systemHighContrast = MediaQuery.highContrastOf(context);
    final isTablet = MediaQuery.sizeOf(context).shortestSide >= 600;
    final textStyle = TextStyle(
      color: palette.ink,
      fontSize: isTablet ? 28 : 24,
      fontWeight: FontWeight.w800,
    );
    // Text here starts at 24 logical pixels, so the system text size is
    // honored up to twice that; beyond it a single word would fill a phone.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 2,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 72,
          backgroundColor: palette.background,
          foregroundColor: palette.ink,
          title: Text('Settings', style: textStyle),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                padding: EdgeInsets.all(isTablet ? 24 : 16),
                children: [
                  ListenableBuilder(
                    listenable: preferences,
                    builder: (context, _) => _HighContrastSwitch(
                      value: preferences.highContrast,
                      onChanged: preferences.setHighContrast,
                      textStyle: textStyle,
                    ),
                  ),
                  if (systemHighContrast)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        'High contrast is also on while the device asks for '
                        'more contrast.',
                        key: const Key('system-high-contrast-note'),
                        style: TextStyle(color: palette.ink, fontSize: 18),
                      ),
                    ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    key: const Key('settings-done'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(72),
                      backgroundColor: palette.selectedSurface,
                      foregroundColor: palette.onSelectedSurface,
                      textStyle: textStyle,
                    ),
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_rounded, size: 32),
                    label: const Text('Back to board'),
                  ),
                  if (choices case final choices?) ...[
                    const SizedBox(height: 48),
                    Semantics(
                      container: true,
                      header: true,
                      child: Text('Choices', style: textStyle),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add choices, change their words, pictures, and order, '
                      'or hide them from the board.',
                      style: TextStyle(color: palette.ink, fontSize: 18),
                    ),
                    const SizedBox(height: 16),
                    CaregiverButton(
                      key: const Key('settings-edit-choices'),
                      icon: Icons.grid_view_rounded,
                      label: 'Edit choices',
                      onPressed: () {
                        choices.clearResult();
                        Navigator.of(context).push(
                          caregiverRoute<void>(
                            context,
                            (context) => ChoicesEditorScreen(choices: choices),
                          ),
                        );
                      },
                    ),
                  ],
                  // Last, so its messages never move the controls above.
                  if (backup case final backup?) ...[
                    const SizedBox(height: 48),
                    BackupSettingsSection(
                      controller: backup,
                      textStyle: textStyle,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HighContrastSwitch extends StatelessWidget {
  const _HighContrastSwitch({
    required this.value,
    required this.onChanged,
    required this.textStyle,
  });
  final bool value;
  final ValueChanged<bool> onChanged;
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    final palette = CareBridgePalette.of(context);
    return Material(
      color: palette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: palette.isHighContrast ? palette.outline : palette.idleBorder,
          width: palette.idleBorderWidth,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: SwitchListTile(
        key: const Key('high-contrast-switch'),
        value: value,
        onChanged: onChanged,
        minTileHeight: 88,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        secondary: Icon(Icons.contrast_rounded, color: palette.ink, size: 40),
        title: Text('High contrast', style: textStyle),
        // A word as well as the switch position, so the state never depends
        // on color. Screen readers already announce the switch state.
        subtitle: ExcludeSemantics(
          child: Text(
            value ? 'On' : 'Off',
            key: const Key('high-contrast-state'),
            style: TextStyle(
              color: palette.ink,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        thumbIcon: WidgetStateProperty.resolveWith(
          (states) => Icon(
            states.contains(WidgetState.selected)
                ? Icons.check_rounded
                : Icons.close_rounded,
          ),
        ),
      ),
    );
  }
}
