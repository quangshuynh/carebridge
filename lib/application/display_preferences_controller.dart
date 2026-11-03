import 'package:flutter/foundation.dart';

import '../domain/display_preferences.dart';
import '../services/display_preferences_store.dart';

/// Owns the display preferences. The board never waits for storage: it
/// starts with the standard display and switches once saved preferences are
/// read. Storage failures keep the preference in memory for this session.
class DisplayPreferencesController extends ChangeNotifier {
  DisplayPreferencesController({this.store});

  /// Null keeps preferences in memory only.
  final DisplayPreferencesStore? store;
  DisplayPreferences _preferences = DisplayPreferences.standard;
  bool _changedThisSession = false;
  bool _isDisposed = false;

  DisplayPreferences get preferences => _preferences;
  bool get highContrast => _preferences.highContrast;

  /// Reads saved preferences once at startup. A change made before the read
  /// finishes is newer, so it is kept.
  Future<void> load() async {
    DisplayPreferences? saved;
    try {
      saved = await store?.load();
    } catch (_) {
      // Unreadable storage leaves the standard display in place.
    }
    if (_isDisposed || _changedThisSession || saved == null) return;
    if (saved == _preferences) return;
    _preferences = saved;
    notifyListeners();
  }

  Future<void> setHighContrast(bool enabled) async {
    if (_isDisposed || enabled == _preferences.highContrast) return;
    _changedThisSession = true;
    _preferences = _preferences.copyWith(highContrast: enabled);
    // The display changes first; saving never delays or undoes it.
    notifyListeners();
    try {
      await store?.save(_preferences);
    } catch (_) {}
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
