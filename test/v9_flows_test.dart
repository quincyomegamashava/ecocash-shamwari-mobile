import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shamwari_mobile/core/api/api_exception.dart';
import 'package:shamwari_mobile/core/api/mock_backend.dart';
import 'package:shamwari_mobile/core/session/stores.dart';

void main() {
  late MockBackend api;

  setUp(() async {
    api = MockBackend();
    final rudo = await api.login('rudo', 'rudo-demo');
    api.attach(rudo.token);
  });

  Future<void> asCare() async {
    final care = await api.login('care', 'care-demo');
    api.attach(care.token);
  }

  test('the production URL is the default and a trailing slash is removed', () {
    expect(
      defaultBaseUrl,
      'https://shamwari.3xm7hvreng89r.eu-west-2.cs.amazonlightsail.com',
    );
    expect(normalizeBaseUrl('$defaultBaseUrl/'), defaultBaseUrl);
    expect(normalizeBaseUrl(''), defaultBaseUrl);
  });

  test('sample clips become a pending five-dollar plan', () async {
    final ndebele = await api.interpretSample('thumela-5-tendai');
    expect(ndebele.plan.intent, 'send_money');
    expect(ndebele.plan.amountCents, 500);
    expect(ndebele.plan.language, 'nd');
    expect(ndebele.plan.recipientName, 'Mai Tendai');
    expect(ndebele.transcriptNote, contains('offline'));

    final shona = await api.interpretAudio(
      Uint8List.fromList([1, 2, 3]),
      'tumira-5-tendai-sn.wav',
    );
    expect(shona.plan.amountCents, 500);
    expect(shona.plan.language, 'sn');

    expect(
      () => api.interpretAudio(Uint8List.fromList([9]), 'note.m4a'),
      throwsA(
        isA<ApiException>().having(
          (error) => error.code,
          'code',
          'transcript_empty',
        ),
      ),
    );
  });

  test('prize desk stays pending until the warning is acknowledged', () async {
    final created = await api.prizeRiskTransfer();
    final txn = created.transaction;
    expect(txn.status, 'pending');
    expect(txn.risk.level, 'high');
    expect(txn.risk.requiresAck, isTrue);
    expect(txn.risk.score, greaterThanOrEqualTo(70));
    expect(txn.risk.reasons.map((item) => item.code), contains('flagged'));
    expect(created.warning, contains('risk_ack'));

    expect(
      () => api.confirmTransfer(txn.id, confirmWord: 'hongu', pin: '2580'),
      throwsA(
        isA<ApiException>()
            .having((error) => error.code, 'code', 'risk_ack_required')
            .having(
              (error) => error.details['transaction']['status'],
              'status',
              'pending',
            ),
      ),
    );

    final posted = await api.confirmTransfer(
      txn.id,
      confirmWord: 'hongu',
      pin: '2580',
      riskAck: true,
    );
    expect(posted.transaction.status, 'posted');
    expect(posted.pinSentToModel, isFalse);
  });

  test('cancelling a high-risk transfer is an audit row', () async {
    final created = await api.prizeRiskTransfer();
    await api.cancelTransfer(created.transaction.id);
    await asCare();
    final rows = await api.audit();
    expect(rows.map((row) => row.action), contains('scam_blocked'));
  });

  test('ussd and chat share the ledger and never echo the PIN', () async {
    final menu = await api.ussd(text: '');
    expect(menu.message, contains('*151#'));
    expect(menu.continueSession, isTrue);
    final balance = await api.ussd(sessionId: menu.sessionId, text: '1');
    expect(balance.message, contains('86.00'));

    final chat = await api.chat(text: 'tumira \$5 kuna Tendai');
    expect(chat.message, contains('Pending'));
    expect(chat.replies.single.type, 'text');
    final yes = await api.chat(sessionId: chat.sessionId, text: 'hongu');
    expect(yes.message, contains('PIN'));
    final posted = await api.chat(sessionId: chat.sessionId, text: '2580');
    expect(posted.message, contains('Posted'));
    expect(posted.message, isNot(contains('2580')));
    final wallet = await api.wallet();
    expect(wallet.wallet('USD')!.balanceCents, 8100);
  });

  test('impact is staff-only and a copilot approval moves the live count', () async {
    expect(
      () => api.impact(),
      throwsA(isA<ApiException>().having((error) => error.code, 'code', 'forbidden')),
    );
    await asCare();
    final before = await api.impact();
    expect(before.simulated, isTrue);
    expect(before.timeSavedMinutes.basis, 'simulated');
    expect(before.ticketsDeflected.basis, 'simulated');
    expect(before.timeSavedMinutes.total, before.timeSavedMinutes.baseline);

    final opened = await api.copilot(58);
    expect(opened.suggestion.summary, isNotEmpty);
    expect(opened.suggestion.drafts, isNotEmpty);
    expect(opened.suggestion.offline, isTrue);
    final approved = await api.decidePulse(
      58,
      action: 'approve',
      text: opened.suggestion.drafts.first,
    );
    expect(approved.sent, isTrue);
    final again = await api.impact();
    expect(again.ticketsDeflected.live, 1);
    expect(again.ticketsDeflected.basis, 'simulated+live');
    final actions = (await api.audit()).map((row) => row.action);
    expect(actions, containsAll(['suggested', 'approve']));

    final rudo = await api.login('rudo', 'rudo-demo');
    api.attach(rudo.token);
    expect(
      () => api.decidePulse(58, action: 'approve'),
      throwsA(isA<ApiException>().having((error) => error.code, 'code', 'forbidden')),
    );
  });
}
