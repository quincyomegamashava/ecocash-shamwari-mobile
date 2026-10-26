import '../json.dart';

class ApiException implements Exception {
  ApiException({
    required this.code,
    required this.message,
    this.status,
    this.details = const {},
  });

  final String code;
  final String message;
  final int? status;
  final Map<String, dynamic> details;

  @override
  String toString() => message;
}

/// Pulls `data` out of the Shamwari envelope, or throws [ApiException].
Map<String, dynamic> unwrapEnvelope(int? status, dynamic body) {
  if (body is! Map) {
    throw ApiException(
      code: 'bad_response',
      message: 'The server sent an unexpected body.',
      status: status,
    );
  }
  final map = asMap(body);
  if (map['ok'] == true) {
    return asMap(map['data']);
  }
  final error = asMap(map['error']);
  throw ApiException(
    code: asString(error['code'], 'error'),
    message: asString(error['message'], 'Request failed.'),
    status: status,
    details: asMap(error['details']),
  );
}

String friendlyError(Object error) {
  if (error is ApiException) {
    switch (error.code) {
      case 'unauthorized':
        return 'Those details do not match a demo desk.';
      case 'token_expired':
        return 'This session has expired. Sign in again.';
      case 'network':
        return error.message;
      case 'need_yes':
        return 'Use a yes word — yes, hongu, yebo, ewe, or ehe. Nothing was posted.';
      case 'bad_pin':
        return 'That PIN does not match. Nothing was posted.';
      case 'transcript_empty':
        return 'The microphone file had no words. Type a phrase, or tap one of the fixed lines.';
      case 'insufficient':
        return 'The wallet no longer covers that hold.';
      case 'forbidden':
        return error.message;
      default:
        return error.message;
    }
  }
  return 'Something went wrong. Pull to try again.';
}
