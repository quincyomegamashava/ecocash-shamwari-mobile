import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shamwari_mobile/main.dart' as app;

/// Drives the Linux desktop build in mock mode and writes one PNG per screen.
/// This is the running app, not the flutter_tester golden harness.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('capture dark, light, and contrast screens', (tester) async {
    await app.main();
    await _until(tester, find.textContaining('waits for yes'));
    await _enableMock(tester);
    if (find.byTooltip('Light mode').evaluate().isNotEmpty) {
      await tester.tap(find.byTooltip('Light mode'));
      await tester.pump(const Duration(milliseconds: 300));
    }

    await _customerGallery(tester, 'default');
    await _signOut(tester);
    await tester.tap(find.byTooltip('Dark mode'));
    await tester.pump(const Duration(milliseconds: 300));
    await _customerGallery(tester, 'dark');
    await _signOut(tester);
    await tester.tap(find.byTooltip('Accessibility'));
    await tester.pump(const Duration(milliseconds: 300));
    await _customerGallery(tester, 'contrast');
  }, timeout: const Timeout(Duration(minutes: 12)));
}

Future<void> _customerGallery(WidgetTester tester, String prefix) async {
  await _shoot(tester, '$prefix-login');
  await _signIn(tester, 'desk-rudo');
  await _until(tester, find.textContaining('Mhoro'));
  await _shoot(tester, '$prefix-home');

  await _tab(tester, '/send');
  await _until(tester, find.text('Send. Then confirm.'));
  await tester.enterText(find.byKey(const Key('amount')), '20');
  await tester.tap(find.byKey(const Key('prepare-transfer')));
  await _until(tester, find.byKey(const Key('pin-pad')));
  await _reveal(tester, find.byKey(const Key('pin-pad')));
  await _shoot(tester, '$prefix-send-pin');

  await _tab(tester, '/voice');
  await _until(tester, find.text('Say it. Then confirm it.'));
  await _shoot(tester, '$prefix-voice');

  await _tab(tester, '/coach');
  await _until(tester, find.text('A coach inside the book.'));
  final ask = find
      .widgetWithText(ActionChip, 'Can I still make my school fees goal?')
      .first;
  await _reveal(tester, ask);
  await tester.tap(ask);
  await _until(tester, find.textContaining('straight-line'));
  await _reveal(tester, find.textContaining('straight-line'));
  await _shoot(tester, '$prefix-coach');

  await _tab(tester, '/scam');
  await _until(tester, find.text('Is this a lure?'));
  final sample = find.widgetWithText(ActionChip, 'Fake reversal').first;
  await _reveal(tester, sample);
  await tester.tap(sample);
  await _until(tester, find.text('Likely scam'));
  await _reveal(tester, find.text('Likely scam'));
  expect(find.textContaining('Mhoro'), findsNothing);
  expect(find.text('A coach inside the book.'), findsNothing);
  await _shoot(tester, '$prefix-scam');

  await _drawerTap(tester, 'Receipts');
  await _until(tester, find.textContaining('Read a slip'));
  await _shoot(tester, '$prefix-receipts');

  await _drawerTap(tester, 'Accessibility');
  await _until(tester, find.text('Easier to see. Easier to hear.'));
  await _shoot(tester, '$prefix-accessibility');

  await _drawerTap(tester, 'Activity');
  await _until(tester, find.text('Activity'));
  await _shoot(tester, '$prefix-activity');

  await _drawerTap(tester, 'Search');
  await _until(tester, find.byKey(const Key('search-field')));
  await _shoot(tester, '$prefix-search');

  await _drawerTap(tester, 'Profile');
  await _until(tester, find.text('Account settings'));
  await _shoot(tester, '$prefix-profile');

  await _signOut(tester);
  await _signIn(tester, 'desk-care');
  await _until(tester, find.text('Live customer pulse.'));
  await _shoot(tester, '$prefix-pulse');

  await _tab(tester, '/onboarding');
  await _until(tester, find.text('Onboarding buddy.'));
  await _shoot(tester, '$prefix-onboarding');

  await _drawerTap(tester, 'Ledger');
  await _until(tester, find.text('Masked phones. No PIN hashes.'));
  await _shoot(tester, '$prefix-ledger');

  await _drawerTap(tester, 'AI log');
  await _until(tester, find.text('Metadata only.'));
  await _shoot(tester, '$prefix-ai-log');

  await _signOut(tester);
  final walk = find.byKey(const Key('walk-morning'));
  await _reveal(tester, walk);
  await tester.tap(walk);
  await tester.pump(const Duration(milliseconds: 300));
  await _until(tester, find.textContaining('1 /'));
  await _shoot(tester, '$prefix-demo');
  await tester.tap(find.text('Stop'));
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _enableMock(WidgetTester tester) async {
  final server = find.text('Server');
  await _reveal(tester, server);
  final serverRect = tester.getRect(server);
  await tester.tapAt(serverRect.center);
  await tester.pump(const Duration(milliseconds: 500));
  final mock = find.byKey(const Key('mock-mode'), skipOffstage: false);
  if (mock.evaluate().isEmpty) {
    final texts = find.byType(Text, skipOffstage: false).evaluate().map((
      element,
    ) {
      final widget = element.widget;
      return widget is Text ? widget.data : null;
    }).whereType<String>();
    fail('Server tap at $serverRect did not open mock. texts=${texts.join(' | ')}');
  }
  await _reveal(tester, mock);
  final tile = tester.widget<SwitchListTile>(mock);
  if (!tile.value) {
    await tester.tap(mock);
    await tester.pump(const Duration(milliseconds: 300));
  }
  expect(tester.widget<SwitchListTile>(mock).value, isTrue);
  await _reveal(tester, find.textContaining('waits for yes'));
}

Future<void> _signIn(WidgetTester tester, String deskKey) async {
  final desk = find.byKey(Key(deskKey));
  await _reveal(tester, desk);
  await tester.tap(desk);
  await tester.pump(const Duration(milliseconds: 200));
  final button = find.byKey(const Key('sign-in'));
  await _reveal(tester, button);
  await tester.tap(button);
  await tester.pump(const Duration(milliseconds: 200));
}

Future<void> _signOut(WidgetTester tester) async {
  await _drawerTap(tester, 'Sign out');
  await _until(tester, find.textContaining('waits for yes'));
}

Future<void> _drawerTap(WidgetTester tester, String label) async {
  tester
      .stateList<ScaffoldState>(find.byType(Scaffold))
      .firstWhere((state) => state.hasDrawer)
      .openDrawer();
  await tester.pump(const Duration(milliseconds: 400));
  final item = find.descendant(
    of: find.byType(Drawer),
    matching: find.text(label),
  );
  final drawerScroll = find.descendant(
    of: find.byType(Drawer),
    matching: find.byType(Scrollable),
  );
  await _reveal(tester, item, scrollable: drawerScroll);
  await tester.tap(item);
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _tab(WidgetTester tester, String path) async {
  await tester.tap(find.byKey(Key('nav-$path')));
  await tester.pump(const Duration(milliseconds: 200));
}

Finder _pageScroll() => find.byType(Scrollable);

Future<void> _reveal(
  WidgetTester tester,
  Finder finder, {
  Finder? scrollable,
}) async {
  final scroll = scrollable ?? _pageScroll();
  final states = tester.stateList<ScrollableState>(scroll).toList();
  if (states.isEmpty) fail('No scrollable for $finder');
  states.sort(
    (a, b) => b.position.maxScrollExtent.compareTo(a.position.maxScrollExtent),
  );
  final page = states.first;
  final root = tester.getRect(find.byKey(const Key('shamwari-shot')));
  if (finder.evaluate().isEmpty) {
    page.position.jumpTo(0);
    await tester.pump(const Duration(milliseconds: 40));
    var previousMax = -1.0;
    for (var i = 0; i < 40 && finder.evaluate().isEmpty; i++) {
      final max = page.position.maxScrollExtent;
      if (page.position.pixels >= max - 1 && (max - previousMax).abs() < 1) {
        break;
      }
      previousMax = max;
      final next = (page.position.pixels + 280).clamp(0.0, max);
      page.position.jumpTo(next == page.position.pixels ? max : next);
      await tester.pump(const Duration(milliseconds: 40));
    }
  }
  if (finder.evaluate().isNotEmpty) {
    await tester.ensureVisible(finder.first);
    await tester.pump(const Duration(milliseconds: 40));
  }
  for (var i = 0; i < 8 && finder.evaluate().isNotEmpty; i++) {
    final rect = tester.getRect(finder.first);
    if (rect.top >= root.top + 4 && rect.bottom <= root.bottom - 4) return;
    final max = page.position.maxScrollExtent;
    final delta = rect.center.dy > root.center.dy ? 120.0 : -120.0;
    page.position.jumpTo((page.position.pixels + delta).clamp(0.0, max));
    await tester.pump(const Duration(milliseconds: 40));
  }
  if (finder.evaluate().isEmpty) {
    fail('Never built $finder. extent=${page.position.maxScrollExtent}');
  }
  final rect = tester.getRect(finder.first);
  if (rect.center.dy < root.top || rect.center.dy > root.bottom) {
    fail('Could not bring $finder on screen. rect=$rect root=$root');
  }
}

Future<void> _until(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 80; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('Timed out waiting for $finder');
}

/// Grabs the on-screen GTK window. RepaintBoundary.toImage deadlocks once the
/// sage glass cards stack several backdrop blurs.
Future<void> _shoot(WidgetTester tester, String name) async {
  await tester.pump(const Duration(milliseconds: 400));
  final file = File('/tmp/shamwari-shots/$name.png');
  await file.parent.create(recursive: true);
  final error = await tester.runAsync(() async {
    final info = await Process.run('xwininfo', ['-name', 'Shamwari']);
    final text = '${info.stdout}';
    int grab(String label) {
      final match = RegExp('$label:\\s+(-?\\d+)').firstMatch(text);
      if (match == null) return -1;
      return int.parse(match.group(1)!);
    }

    final x = grab('Absolute upper-left X');
    final y = grab('Absolute upper-left Y');
    final w = grab('Width');
    final h = grab('Height');
    if (x < 0 || y < 0 || w < 100 || h < 100) {
      return 'xwininfo failed (${info.exitCode}): $text ${info.stderr}';
    }
    final shot = await Process.run('scrot', [
      '-o',
      '-a',
      '$x,$y,$w,$h',
      file.path,
    ]);
    if (shot.exitCode != 0 || !file.existsSync()) {
      return 'scrot failed (${shot.exitCode}): ${shot.stderr} ${shot.stdout}';
    }
    return null;
  });
  if (error != null) fail(error);
  debugPrint('shot $name ${await file.length()} bytes');
}
