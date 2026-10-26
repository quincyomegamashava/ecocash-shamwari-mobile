import 'package:flutter_test/flutter_test.dart';
import 'package:shamwari_mobile/core/api/api_exception.dart';
import 'package:shamwari_mobile/core/money.dart';

void main() {
  test('money stays in integer cents', () {
    expect(parseCents('20'), 2000);
    expect(parseCents('20.5'), 2050);
    expect(parseCents('US\$ 86.00'), 8600);
    expect(parseCents('1,250.50'), 125050);
    expect(parseCents('20.555'), isNull);
    expect(parseCents(''), isNull);
    expect(formatCents(8600, 'USD'), 'US\$ 86.00');
    expect(formatCents(42000, 'ZIG'), 'ZiG 420.00');
    expect(formatCents(-150, 'USD'), '-US\$ 1.50');
  });

  test('unwraps the success envelope and error codes', () {
    final data = unwrapEnvelope(200, {
      'ok': true,
      'synthetic': true,
      'data': {'token': 'abc'},
    });
    expect(data['token'], 'abc');

    expect(
      () => unwrapEnvelope(400, {
        'ok': false,
        'error': {
          'code': 'bad_pin',
          'message': 'That PIN does not match.',
          'details': {'outcome': 'bad_pin'},
        },
      }),
      throwsA(
        isA<ApiException>()
            .having((error) => error.code, 'code', 'bad_pin')
            .having((error) => error.status, 'status', 400)
            .having(
              (error) => error.details['outcome'],
              'outcome',
              'bad_pin',
            ),
      ),
    );

    expect(
      () => unwrapEnvelope(500, 'nope'),
      throwsA(isA<ApiException>().having((error) => error.code, 'code', 'bad_response')),
    );
    expect(friendlyError(ApiException(code: 'need_yes', message: 'raw')), contains('hongu'));
    expect(friendlyError(ApiException(code: 'transcript_empty', message: 'raw')), contains('microphone'));
  });
}
