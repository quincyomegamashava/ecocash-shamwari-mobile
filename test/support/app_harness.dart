import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shamwari_mobile/app.dart';
import 'package:shamwari_mobile/core/api/mock_backend.dart';
import 'package:shamwari_mobile/core/session/session.dart';
import 'package:shamwari_mobile/core/session/stores.dart';

class AppHarness {
  AppHarness({this.mockMode = true, this.theme = 'dark', this.highContrast = false}) {
    prefs.setBool('mock_mode', mockMode);
    prefs.setString('theme', theme);
    prefs.setBool('high_contrast', highContrast);
  }

  final MemoryPrefs prefs = MemoryPrefs();
  final MemoryTokenStore tokens = MemoryTokenStore();
  final MockBackend mock = MockBackend();
  final bool mockMode;
  final String theme;
  final bool highContrast;

  Widget build() {
    return ProviderScope(
      overrides: [
        prefsStoreProvider.overrideWithValue(prefs),
        tokenStoreProvider.overrideWithValue(tokens),
        loadPaceProvider.overrideWithValue(Duration.zero),
        mockBackendProvider.overrideWithValue(mock),
      ],
      child: const ShamwariApp(),
    );
  }
}

Future<void> pumpFrames(WidgetTester tester, [int frames = 8]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 80));
  }
}

Future<void> bootApp(WidgetTester tester, AppHarness harness) async {
  tester.view.physicalSize = const Size(390 * 2, 844 * 2);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(harness.build());
  await pumpFrames(tester, 6);
}

Future<void> signIn(WidgetTester tester, String deskKey) async {
  final scrollable = find.byType(Scrollable).first;
  await tester.tap(find.byKey(const Key('demo-accounts')));
  await tester.pump();
  await _reveal(tester, find.byKey(Key(deskKey)), scrollable);
  await tester.tap(find.byKey(Key(deskKey)));
  await tester.pump();
  await _reveal(tester, find.byKey(const Key('sign-in')), scrollable);
  await tester.tap(find.byKey(const Key('sign-in')));
  await pumpFrames(tester, 12);
}

Future<void> _reveal(WidgetTester tester, Finder finder, Finder scrollable) async {
  await tester.scrollUntilVisible(finder, 280, scrollable: scrollable);
  final height = tester.view.physicalSize.height / tester.view.devicePixelRatio;
  for (var i = 0; i < 6; i++) {
    final rect = tester.getRect(finder);
    if (rect.top >= 4 && rect.bottom <= height - 8) return;
    await tester.drag(scrollable, Offset(0, rect.center.dy > height / 2 ? -120 : 120));
    await tester.pump();
  }
}
