import 'dart:async';

import 'package:carebridge/domain/display_preferences.dart';
import 'package:carebridge/services/display_preferences_store.dart';

/// Stands in for on-device storage. One instance survives an app "restart"
/// in a test the way the platform's storage survives a real one.
class FakeDisplayPreferencesStore implements DisplayPreferencesStore {
  FakeDisplayPreferencesStore([this.saved]);
  DisplayPreferences? saved;
  Completer<void>? pendingLoad;
  Object? loadError;
  Object? saveError;
  int saveCount = 0;

  @override
  Future<DisplayPreferences?> load() async {
    await pendingLoad?.future;
    if (loadError != null) throw loadError!;
    return saved;
  }

  @override
  Future<void> save(DisplayPreferences preferences) async {
    saveCount++;
    if (saveError != null) throw saveError!;
    saved = preferences;
  }
}
