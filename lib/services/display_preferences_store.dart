import '../domain/display_preferences.dart';

abstract interface class DisplayPreferencesStore {
  /// The saved preferences, or null when nothing has been saved yet.
  Future<DisplayPreferences?> load();

  /// Saves [preferences] on the device.
  Future<void> save(DisplayPreferences preferences);
}
