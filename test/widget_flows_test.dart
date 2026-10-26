import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shamwari_mobile/core/theme/shamwari_theme.dart';
import 'package:shamwari_mobile/widgets/pin_pad.dart';

import 'support/app_harness.dart';

void main() {
  testWidgets('login reaches Rudo’s book and a wrong desk stays on the form', (
    tester,
  ) async {
    await bootApp(tester, AppHarness());
    expect(find.text('The wallet that waits for yes.'), findsOneWidget);
    expect(find.text('Prototype · synthetic data'), findsNothing);

    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.byKey(const Key('username')),
      240,
      scrollable: scrollable,
    );
    await tester.enterText(find.byKey(const Key('username')), 'rudo');
    await tester.enterText(find.byKey(const Key('password')), 'nope');
    await tester.ensureVisible(find.byKey(const Key('sign-in')));
    await tester.tap(find.byKey(const Key('sign-in')));
    await pumpFrames(tester, 8);
    expect(find.textContaining('do not match'), findsOneWidget);

    await tester.tap(find.byKey(const Key('demo-accounts')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('desk-rudo')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('sign-in')));
    await pumpFrames(tester, 12);
    expect(find.text('US\$ 86.00'), findsWidgets);
    expect(find.textContaining('Term 2 school fees'), findsWidgets);
  });

  testWidgets('care is kept off the wallet and Rudo is kept off pulse', (
    tester,
  ) async {
    await bootApp(tester, AppHarness());
    await signIn(tester, 'desk-care');
    expect(find.text('Live customer pulse.'), findsOneWidget);

    GoRouter.of(tester.element(find.text('Live customer pulse.'))).go('/home');
    await pumpFrames(tester, 4);
    expect(find.text('This desk is the customer side.'), findsOneWidget);

    GoRouter.of(tester.element(find.text('Back to pulse'))).go('/login');
    await pumpFrames(tester, 4);
  });

  testWidgets('send money shows a PIN pad that does not print the digits', (
    tester,
  ) async {
    await bootApp(tester, AppHarness());
    await signIn(tester, 'desk-rudo');
    GoRouter.of(tester.element(find.text('US\$ 86.00'))).go('/send');
    await pumpFrames(tester, 10);
    expect(find.text('Send. Then confirm.'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('amount')), '20');
    await tester.tap(find.byKey(const Key('prepare-transfer')));
    await pumpFrames(tester, 8);
    expect(find.text('Still pending.'), findsOneWidget);
    expect(find.byKey(const Key('pin-pad')), findsOneWidget);
    expect(find.text('2580'), findsNothing);
    // The pad sits just under the floating nav. Dragging reveals it; ensureVisible
    // treats the cached sliver as already shown and does not move.
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -360));
    await tester.pump();

    Future<void> press(String digit) async {
      final key = find.descendant(
        of: find.byKey(const Key('pin-pad')),
        matching: find.text(digit),
      );
      await tester.tap(key);
      await tester.pump();
    }

    await press('2');
    await press('5');
    await press('8');
    await press('0');
    expect(find.text('2580'), findsNothing);
    expect(find.textContaining('4 of 4'), findsNothing);
    final semantics = tester.getSemantics(find.byKey(const Key('pin-pad')));
    expect(semantics.label, contains('4 of 4'));

    await tester.tap(find.byKey(const Key('pin-confirm')));
    await pumpFrames(tester, 8);
    expect(find.text('The book moved.'), findsOneWidget);
    expect(find.textContaining('Sent to the model: no'), findsOneWidget);
  });

  testWidgets('the PIN pad itself never renders the secret', (tester) async {
    var pin = '';
    await tester.pumpWidget(
      MaterialApp(
        theme: shamwariTheme(ShamwariPalette.dark),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return PinPad(
                pin: pin,
                onChanged: (value) => setState(() => pin = value),
              );
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('2'));
    await tester.pump();
    await tester.tap(find.text('5'));
    await tester.pump();
    expect(pin, '25');
    expect(find.text('25'), findsNothing);
    expect(
      tester.getSemantics(find.byKey(const Key('pin-pad'))).label,
      contains('2 of 4'),
    );
  });

  testWidgets('a new tab replaces the previous screen', (tester) async {
    await bootApp(tester, AppHarness());
    await signIn(tester, 'desk-rudo');
    expect(find.textContaining('Mhoro'), findsOneWidget);
    expect(find.text('US\$ 86.00'), findsWidgets);

    GoRouter.of(tester.element(find.byKey(const Key('shamwari-nav')))).go('/coach');
    await pumpFrames(tester, 6);
    expect(find.text('A coach inside the book.'), findsOneWidget);
    expect(find.textContaining('Mhoro'), findsNothing);

    GoRouter.of(tester.element(find.byKey(const Key('shamwari-nav')))).go('/scam');
    await pumpFrames(tester, 6);
    expect(find.text('Is this a lure?'), findsOneWidget);
    expect(find.text('A coach inside the book.'), findsNothing);
    expect(find.textContaining('Mhoro'), findsNothing);
    expect(find.text('US\$ 86.00'), findsNothing);
  });

  testWidgets('prize desk warning blocks the PIN until it is acknowledged', (
    tester,
  ) async {
    await bootApp(tester, AppHarness());
    await signIn(tester, 'desk-rudo');
    GoRouter.of(tester.element(find.byKey(const Key('shamwari-nav')))).go('/send');
    await pumpFrames(tester, 12);
    await tester.scrollUntilVisible(
      find.byKey(const Key('prize-desk')),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.byKey(const Key('prize-desk')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('prize-desk')));
    await pumpFrames(tester, 8);
    expect(find.textContaining('Prize Desk'), findsWidgets);
    expect(find.byKey(const Key('pin-pad')), findsNothing);
    await tester.scrollUntilVisible(
      find.byKey(const Key('risk-ack')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('risk-ack')));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.byKey(const Key('pin-pad')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(const Key('pin-pad')), findsOneWidget);
  });

  testWidgets('chat and ussd open as plain text channels', (tester) async {
    await bootApp(tester, AppHarness());
    await signIn(tester, 'desk-rudo');
    final router = GoRouter.of(
      tester.element(find.byKey(const Key('shamwari-nav'))),
    );
    router.go('/chat');
    await pumpFrames(tester, 8);
    expect(find.text('Chat channel'), findsOneWidget);
    expect(find.textContaining('Shamwari chat'), findsOneWidget);
    expect(find.textContaining('WhatsApp'), findsNothing);

    router.go('/ussd');
    await pumpFrames(tester, 8);
    expect(find.text('USSD *151#'), findsOneWidget);
    expect(find.textContaining('*151#'), findsWidgets);
    expect(find.text('Chat channel'), findsNothing);
  });

  testWidgets('care home shows impact and a copilot case', (tester) async {
    await bootApp(tester, AppHarness());
    await signIn(tester, 'desk-care');
    expect(find.byKey(const Key('impact-card')), findsOneWidget);
    expect(find.text('minutes saved'), findsOneWidget);
    expect(find.text('SIMULATED'), findsWidgets);

    GoRouter.of(tester.element(find.byKey(const Key('shamwari-nav')))).go(
      '/pulse/case/58',
    );
    await pumpFrames(tester, 10);
    await tester.scrollUntilVisible(
      find.byKey(const Key('copilot-approve')),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Approve & send'), findsOneWidget);
    expect(find.textContaining('reversal'), findsWidgets);
    await tester.scrollUntilVisible(
      find.byKey(const Key('copilot-discard')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('copilot-discard')));
    await pumpFrames(tester, 4);
    expect(find.textContaining('Discarded'), findsOneWidget);

    GoRouter.of(tester.element(find.byKey(const Key('shamwari-nav')))).go('/audit');
    await pumpFrames(tester, 8);
    expect(find.text('Audit log'), findsOneWidget);
    expect(find.textContaining('discard'), findsWidgets);
  });
}
