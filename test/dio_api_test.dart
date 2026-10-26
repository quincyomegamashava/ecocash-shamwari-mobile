import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shamwari_mobile/core/api/dio_api.dart';

void main() {
  test('PIN is sent only on the confirm routes', () async {
    final calls = <RequestOptions>[];
    final dio = Dio(
      BaseOptions(
        baseUrl: 'http://10.0.2.2:8642',
        validateStatus: (code) => code != null && code < 600,
      ),
    );
    var token = '';
    final api = DioShamwariApi(
      baseUrl: 'http://10.0.2.2:8642',
      token: () => token,
      dio: dio,
    );
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          calls.add(options);
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'ok': true,
                'synthetic': true,
                'data': _payload(options.path),
              },
            ),
          );
        },
      ),
    );

    final login = await api.login('rudo', 'rudo-demo');
    expect(login.token, 'example-bearer-token');
    expect(calls.single.path, '/api/v1/auth/login');
    expect(calls.single.data, {'username': 'rudo', 'password': 'rudo-demo'});
    expect(calls.single.headers['Authorization'], isNull);

    token = login.token;
    calls.clear();
    await api.coachSend('my pin is 2580');
    expect(calls.single.path, '/api/v1/coach/messages');
    expect(calls.single.data, {'text': 'my pin is 2580'});
    expect((calls.single.data as Map).containsKey('pin'), isFalse);
    expect(calls.single.headers['Authorization'], 'Bearer example-bearer-token');

    calls.clear();
    final confirmed = await api.confirmTransfer(
      41,
      confirmWord: 'hongu',
      pin: '2580',
    );
    expect(calls.single.path, '/api/v1/transfers/41/confirm');
    expect(calls.single.data, {'confirm_word': 'hongu', 'pin': '2580'});
    expect(confirmed.pinSentToModel, isFalse);
    expect(confirmed.transaction.status, 'posted');

    calls.clear();
    await api.confirmVoice(txnId: 42, confirmWord: 'yes', pin: '2580');
    expect(calls.single.path, '/api/v1/voice/confirm');
    expect(calls.single.data, {
      'txn_id': 42,
      'confirm_word': 'yes',
      'pin': '2580',
    });
  });
}

Map<String, dynamic> _payload(String path) {
  if (path.endsWith('/auth/login')) {
    return {
      'token': 'example-bearer-token',
      'token_type': 'Bearer',
      'expires_at': '2026-11-09T00:00:00Z',
      'user': {
        'id': 1,
        'username': 'rudo',
        'role': 'customer',
        'display_name': 'Rudo Moyo',
        'customer_id': 1,
      },
    };
  }
  if (path.contains('/coach/')) {
    return {
      'note': 'A secret was scrubbed before this was saved.',
      'reply': {
        'id': 3,
        'role': 'assistant',
        'content': 'Behind.',
        'created_at': '2026-10-26T08:00:00Z',
      },
      'messages': [
        {
          'id': 2,
          'role': 'user',
          'content': 'my pin is [redacted]',
          'created_at': '2026-10-26T08:00:00Z',
        },
      ],
    };
  }
  return {
    'outcome': 'posted',
    'pin_checked_locally': true,
    'pin_sent_to_model': false,
    'transaction': {
      'id': 41,
      'reference': 'SM-100041',
      'kind': 'transfer',
      'category': 'family',
      'status': 'posted',
      'amount_cents': 2000,
      'currency': 'USD',
      'display': 'US\$ 20.00',
      'sender_id': 1,
      'counterparty': 'Mai Tendai',
      'note': 'Posted.',
      'outgoing': true,
      'created_at': '2026-10-26T08:00:00Z',
      'posted_at': '2026-10-26T08:01:00Z',
    },
  };
}
