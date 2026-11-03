import 'package:shared_preferences/shared_preferences.dart';

import '../domain/display_preferences.dart';
import '../services/display_preferences_store.dart';

/// Keeps display preferences in the platform's app-private key-value storage
/// (SharedPreferences on Android, UserDefaults on iOS). Nothing leaves the
/// device through CareBridge.
class SharedPreferencesDisplayPreferencesStore
    implements DisplayPreferencesStore {
  SharedPreferencesDisplayPreferencesStore({
    Future<SharedPreferences> Function()? preferences,
  }) : _preferences = preferences ?? SharedPreferences.getInstance;
  final Future<SharedPreferences> Function() _preferences;

  static const highContrastKey = 'display.highContrast';

  @override
  Future<DisplayPreferences?> load() async {
    final preferences = await _preferences();
    final highContrast = preferences.getBool(highContrastKey);
    if (highContrast == null) return null;
    return DisplayPreferences(highContrast: highContrast);
  }

  @override
  Future<void> save(DisplayPreferences preferences) async {
    final stored = await _preferences();
    await stored.setBool(highContrastKey, preferences.highContrast);
  }
}
