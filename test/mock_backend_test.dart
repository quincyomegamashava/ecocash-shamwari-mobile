import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shamwari_mobile/core/api/api_exception.dart';
import 'package:shamwari_mobile/core/api/mock_backend.dart';

void main() {
  late MockBackend api;

  setUp(() => api = MockBackend());

  Future<void> signIn(String username, String password) async {
    final result = await api.login(username, password);
    api.attach(result.token);
  }

  test('login accepts the two desks and rejects the rest', () async {
    final rudo = await api.login('rudo', 'rudo-demo');
    expect(rudo.user.role, 'customer');
    expect(rudo.tokenType, 'Bearer');
    api.attach(rudo.token);
    final me = await api.me();
    expect(me.customer?.fullName, 'Rudo Moyo');

    final care = await api.login('care', 'care-demo');
    expect(care.user.role, 'staff');

    expect(
      () => api.login('rudo', 'wrong'),
      throwsA(isA<ApiException>().having((error) => error.code, 'code', 'unauthorized')),
    );
    expect(
      () => api.login('', ''),
      throwsA(isA<ApiException>().having((error) => error.code, 'code', 'validation')),
    );
  });

  test('a pending transfer posts only with a yes word and PIN 2580', () async {
    await signIn('rudo', 'rudo-demo');
    final before = await api.wallet();
    expect(before.wallet('USD')!.balanceCents, 8600);
    expect(before.wallet('USD')!.displayBalance, 'US\$ 86.00');
    expect(before.week.totalCents, 3800);
    expect(before.week.days.firstWhere((day) => day.peak).amountCents, 1000);

    final pending = await api.createTransfer(
      amountCents: 2000,
      currency: 'USD',
      kind: 'transfer',
      recipientName: 'Mai Tendai',
    );
    expect(pending.outcome, 'pending');
    expect(pending.transaction.status, 'pending');
    final held = await api.wallet();
    expect(held.wallet('USD')!.balanceCents, 8600);
    expect(held.wallet('USD')!.availableCents, 6600);

    expect(
      () => api.confirmTransfer(pending.transaction.id, confirmWord: 'maybe', pin: '2580'),
      throwsA(isA<ApiException>().having((error) => error.code, 'code', 'need_yes')),
    );
    expect((await api.transfer(pending.transaction.id)).status, 'pending');

    expect(
      () => api.confirmTransfer(pending.transaction.id, confirmWord: 'hongu', pin: '1111'),
      throwsA(
        isA<ApiException>()
            .having((error) => error.code, 'code', 'bad_pin')
            .having((error) => error.details['pin_sent_to_model'], 'model', false),
      ),
    );
    expect((await api.transfer(pending.transaction.id)).status, 'pending');
    expect((await api.wallet()).wallet('USD')!.balanceCents, 8600);

    final posted = await api.confirmTransfer(
      pending.transaction.id,
      confirmWord: 'yebo',
      pin: '2580',
    );
    expect(posted.outcome, 'posted');
    expect(posted.pinSentToModel, isFalse);
    expect(posted.pinCheckedLocally, isTrue);
    final after = await api.wallet();
    expect(after.wallet('USD')!.balanceCents, 6600);
    expect(after.wallet('USD')!.availableCents, 6600);
    expect(after.wallet('USD')!.displayBalance, 'US\$ 66.00');
  });

  test('roles, search, coach scrubbing, and silent audio', () async {
    await signIn('rudo', 'rudo-demo');
    expect(
      () => api.pulse(),
      throwsA(
        isA<ApiException>()
            .having((error) => error.code, 'code', 'forbidden')
            .having((error) => error.message, 'message', contains('care team')),
      ),
    );
    final customerHits = await api.search('pulse');
    expect(customerHits.any((hit) => hit.label == 'Customer Pulse'), isFalse);

    final reply = await api.coachSend('Call me on 0771 234 567. PIN 2580 in 2026.');
    expect(reply.messages.last.content, isNot(contains('2580')));
    final saved = reply.messages.firstWhere((message) => message.role == 'user');
    expect(saved.content, contains('[redacted]'));
    expect(saved.content, contains('[phone]'));
    expect(saved.content, contains('2026'));
    expect(reply.note, contains('scrubbed'));

    expect(
      () => api.interpretAudio(Uint8List.fromList([1, 2, 3]), 'note.m4a'),
      throwsA(isA<ApiException>().having((error) => error.code, 'code', 'transcript_empty')),
    );

    final heard = await api.interpretText('tumira madhora makumi maviri kuna Mai Tendai');
    expect(heard.plan.intent, 'send_money');
    expect(heard.plan.amountCents, 2000);
    expect(heard.plan.recipientName, 'Mai Tendai');

    final script = await api.demoStart();
    expect(script.current?.slug, 'voice');
    expect(script.current?.role, 'customer');
    final rudoToken = api.tokenReader;
    api.attach((await api.login('rudo', 'rudo-demo')).token);
    expect((await api.demo()).active, isFalse);

    await signIn('care', 'care-demo');
    expect(
      () => api.wallet(),
      throwsA(
        isA<ApiException>().having((error) => error.message, 'message', contains('customer side')),
      ),
    );
    final staffHits = await api.search('pulse');
    expect(staffHits.map((hit) => hit.label), contains('Customer Pulse'));
    expect(staffHits.length, lessThanOrEqualTo(12));
    final pulse = await api.pulse();
    final published = pulse.series.daily.fold<int>(0, (sum, day) => sum + day.total);
    expect(published, 66);
    expect(rudoToken, isNull);
  });
}
