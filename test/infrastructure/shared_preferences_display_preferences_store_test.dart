import 'package:carebridge/domain/display_preferences.dart';
import 'package:carebridge/infrastructure/shared_preferences_display_preferences_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('nothing saved reads as null, not as a guessed value', () async {
    SharedPreferences.setMockInitialValues({});
    expect(await SharedPreferencesDisplayPreferencesStore().load(), isNull);
  });

  test('a saved preference is read back by a new store instance', () async {
    SharedPreferences.setMockInitialValues({});
    await SharedPreferencesDisplayPreferencesStore().save(
      const DisplayPreferences(highContrast: true),
    );

    expect(
      await SharedPreferencesDisplayPreferencesStore().load(),
      const DisplayPreferences(highContrast: true),
    );
    final raw = await SharedPreferences.getInstance();
    expect(
      raw.getBool(SharedPreferencesDisplayPreferencesStore.highContrastKey),
      isTrue,
    );
  });

  test('saving leaves other stored values untouched', () async {
    SharedPreferences.setMockInitialValues({'board.other': 'kept'});
    await SharedPreferencesDisplayPreferencesStore().save(
      const DisplayPreferences(highContrast: false),
    );
    final raw = await SharedPreferences.getInstance();
    expect(raw.getString('board.other'), 'kept');
  });
}
