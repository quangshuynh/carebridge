import 'dart:async';

import 'package:carebridge/application/display_preferences_controller.dart';
import 'package:carebridge/domain/display_preferences.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_display_preferences_store.dart';

void main() {
  test('starts standard and writes nothing when nothing is saved', () async {
    final store = FakeDisplayPreferencesStore();
    final controller = DisplayPreferencesController(store: store);
    await controller.load();

    expect(controller.highContrast, isFalse);
    expect(store.saveCount, 0);
  });

  test('loads a saved high-contrast preference', () async {
    final store = FakeDisplayPreferencesStore(
      const DisplayPreferences(highContrast: true),
    );
    final controller = DisplayPreferencesController(store: store);
    var notifications = 0;
    controller.addListener(() => notifications++);
    await controller.load();

    expect(controller.highContrast, isTrue);
    expect(notifications, 1);
  });

  test('a change is shown at once and saved on the device', () async {
    final store = FakeDisplayPreferencesStore();
    final controller = DisplayPreferencesController(store: store);
    await controller.load();

    final saving = controller.setHighContrast(true);
    expect(controller.highContrast, isTrue, reason: 'before the save ends');
    await saving;
    expect(store.saved, const DisplayPreferences(highContrast: true));

    await controller.setHighContrast(false);
    expect(store.saved, const DisplayPreferences(highContrast: false));
  });

  test('setting the current value again saves nothing', () async {
    final store = FakeDisplayPreferencesStore();
    final controller = DisplayPreferencesController(store: store);
    await controller.setHighContrast(false);
    expect(store.saveCount, 0);
  });

  test('a change made while loading is not overwritten by the load', () async {
    final store = FakeDisplayPreferencesStore(
      const DisplayPreferences(highContrast: true),
    )..pendingLoad = Completer<void>();
    final controller = DisplayPreferencesController(store: store);

    final loading = controller.load();
    await controller.setHighContrast(true);
    await controller.setHighContrast(false);
    store.pendingLoad!.complete();
    await loading;

    expect(controller.highContrast, isFalse);
    expect(store.saved, const DisplayPreferences(highContrast: false));
  });

  test('unreadable storage keeps the standard display', () async {
    final store = FakeDisplayPreferencesStore()
      ..loadError = StateError('corrupt');
    final controller = DisplayPreferencesController(store: store);
    await controller.load();
    expect(controller.highContrast, isFalse);
  });

  test('a failed save still applies the change for this session', () async {
    final store = FakeDisplayPreferencesStore()..saveError = StateError('full');
    final controller = DisplayPreferencesController(store: store);
    await controller.setHighContrast(true);
    expect(controller.highContrast, isTrue);
  });

  test('without a store, preferences stay in memory', () async {
    final controller = DisplayPreferencesController();
    await controller.load();
    await controller.setHighContrast(true);
    expect(controller.highContrast, isTrue);
  });

  test('a load finishing after dispose changes nothing', () async {
    final store = FakeDisplayPreferencesStore(
      const DisplayPreferences(highContrast: true),
    )..pendingLoad = Completer<void>();
    final controller = DisplayPreferencesController(store: store);
    final loading = controller.load();
    controller.dispose();
    store.pendingLoad!.complete();
    await loading;
    expect(controller.highContrast, isFalse);
  });
}
