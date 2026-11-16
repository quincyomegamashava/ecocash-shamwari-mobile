import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shamwari_mobile/core/theme/shamwari_theme.dart';

import 'support/app_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    shamwariAllowBlur = false;
    final sans = FontLoader('Plus Jakarta Sans');
    for (final file in [
      'PlusJakartaSans-Regular.ttf',
      'PlusJakartaSans-Medium.ttf',
      'PlusJakartaSans-SemiBold.ttf',
      'PlusJakartaSans-Bold.ttf',
      'PlusJakartaSans-ExtraBold.ttf',
    ]) {
      final bytes = await File('assets/fonts/$file').readAsBytes();
      sans.addFont(Future.value(ByteData.view(bytes.buffer)));
    }
    await sans.load();
    final icons = FontLoader('MaterialIcons');
    final iconFile = File(
      '${Platform.environment['FLUTTER_ROOT'] ?? '/home/ubuntu/sdk/flutter'}'
      '/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    );
    final iconBytes = await iconFile.readAsBytes();
    icons.addFont(Future.value(ByteData.view(iconBytes.buffer)));
    await icons.load();
  });

  testWidgets('dark screenshots', (tester) async {
    if (!autoUpdateGoldenFiles) return;
    await _gallery(tester, 'dark', AppHarness());
  }, timeout: const Timeout(Duration(minutes: 2)));

  testWidgets('light screenshots', (tester) async {
    if (!autoUpdateGoldenFiles) return;
    await _gallery(tester, 'light', AppHarness(theme: 'light'));
  }, timeout: const Timeout(Duration(minutes: 2)));

  testWidgets('accessibility screenshots', (tester) async {
    if (!autoUpdateGoldenFiles) return;
    await _gallery(
      tester,
      'contrast',
      AppHarness(highContrast: true),
      contrastOnly: true,
    );
  }, timeout: const Timeout(Duration(minutes: 2)));
}

Future<void> _gallery(
  WidgetTester tester,
  String prefix,
  AppHarness harness, {
  bool contrastOnly = false,
}) async {
  debugPrint('gallery $prefix');
  await bootApp(tester, harness);
  debugPrint('booted $prefix');
  await _shoot(tester, '$prefix-login');
  if (contrastOnly) {
    await signIn(tester, 'desk-rudo');
    await _until(tester, find.text('Shamwari · EcoCash AI'));
    await _shoot(tester, '$prefix-chat');
    _go(tester, '/home');
    await _until(tester, find.textContaining('Mhoro'));
    await _shoot(tester, '$prefix-home');
    _go(tester, '/accessibility');
    await _until(tester, find.text('Easier to see. Easier to hear.'));
    final contrast = find.widgetWithText(SwitchListTile, 'High contrast');
    await tester.ensureVisible(contrast);
    await tester.tap(contrast);
    await pumpFrames(tester, 10);
    await _shoot(tester, '$prefix-accessibility');
    return;
  }

  await signIn(tester, 'desk-rudo');
  await _until(tester, find.text('Shamwari · EcoCash AI'));
  await _shoot(tester, '$prefix-chat');
  _go(tester, '/home');
  await _until(tester, find.textContaining('Mhoro'));
  await _shoot(tester, '$prefix-home');

  _go(tester, '/send');
  await _until(tester, find.text('Send. Then confirm.'));
  await tester.enterText(find.byKey(const Key('amount')), '20');
  await tester.tap(find.byKey(const Key('prepare-transfer')));
  await _until(tester, find.byKey(const Key('pin-pad')));
  final pad = find.byKey(const Key('pin-pad'));
  await tester.ensureVisible(pad);
  await tester.pump();
  await _shoot(tester, '$prefix-send-pin');

  _go(tester, '/voice');
  await _until(tester, find.text('Say it. Then confirm it.'));
  await _shoot(tester, '$prefix-voice');

  _go(tester, '/coach');
  await _until(tester, find.text('A coach inside the book.'));
  final ask = find
      .widgetWithText(ActionChip, 'Can I still make my school fees goal?')
      .first;
  await tester.scrollUntilVisible(
    ask,
    240,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.tap(ask);
  await _until(tester, find.textContaining('straight-line'));
  await tester.scrollUntilVisible(
    find.textContaining('straight-line').first,
    220,
    scrollable: find.byType(Scrollable).first,
  );
  await _shoot(tester, '$prefix-coach');

  _go(tester, '/scam');
  await _until(tester, find.text('Is this a lure?'));
  final sample = find.widgetWithText(ActionChip, 'Fake reversal').first;
  await tester.scrollUntilVisible(
    sample,
    240,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.tap(sample);
  await _until(tester, find.text('Likely scam'));
  await tester.scrollUntilVisible(
    find.text('Likely scam').first,
    240,
    scrollable: find.byType(Scrollable).first,
  );
  await _shoot(tester, '$prefix-scam');

  _go(tester, '/receipts');
  await _until(tester, find.textContaining('Read a slip'));
  await _shoot(tester, '$prefix-receipts');

  _go(tester, '/accessibility');
  await _until(tester, find.text('Easier to see. Easier to hear.'));
  await _shoot(tester, '$prefix-accessibility');

  tester
      .stateList<ScaffoldState>(find.byType(Scaffold))
      .firstWhere((state) => state.hasEndDrawer)
      .openEndDrawer();
  await pumpFrames(tester, 8);
  await tester.scrollUntilVisible(
    find.text('Sign out'),
    200,
    scrollable: find
        .descendant(of: find.byType(Drawer), matching: find.byType(Scrollable))
        .first,
  );
  await tester.tap(find.text('Sign out'));
  await _until(tester, find.byKey(const Key('demo-accounts')));
  await tester.tap(find.byKey(const Key('demo-accounts')));
  await _until(tester, find.text('Choose a demo desk.'));

  await signIn(tester, 'desk-care');
  await _until(tester, find.text('Live customer pulse.'));
  await _shoot(tester, '$prefix-pulse');

  _go(tester, '/onboarding');
  await _until(tester, find.text('Onboarding buddy.'));
  await _shoot(tester, '$prefix-onboarding');
}

void _go(WidgetTester tester, String path) {
  GoRouter.of(tester.element(find.byKey(const Key('shamwari-nav')))).go(path);
}

Future<void> _until(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 60));
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('Timed out waiting for $finder');
}

Future<void> _shoot(WidgetTester tester, String name) async {
  debugPrint('shoot $name');
  debugPrint('pump-start');
  await tester.pump();
  debugPrint('pump-done $name');
  await expectLater(
    find.byKey(const Key('shamwari-shot')),
    matchesGoldenFile('goldens/$name.png'),
  );
  debugPrint('wrote $name');
}
