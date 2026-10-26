import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../models/models.dart';
import 'api_exception.dart';
import 'shamwari_api.dart';

class DioShamwariApi implements ShamwariApi {
  DioShamwariApi({
    required String baseUrl,
    required String? Function() token,
    Dio? dio,
  }) : _dio =
           dio ??
           Dio(
             BaseOptions(
               baseUrl: baseUrl,
               connectTimeout: const Duration(seconds: 8),
               receiveTimeout: const Duration(seconds: 25),
               headers: {'Accept': 'application/json'},
               responseType: ResponseType.json,
               validateStatus: (code) => code != null && code < 600,
             ),
           ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final bearer = token();
          if (bearer != null && bearer.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $bearer';
          }
          handler.next(options);
        },
      ),
    );
  }

  final Dio _dio;

  Future<Map<String, dynamic>> _send(Future<Response<dynamic>> call) async {
    try {
      final response = await call;
      return unwrapEnvelope(response.statusCode, response.data);
    } on DioException catch (error) {
      final data = error.response?.data;
      if (data != null) {
        return unwrapEnvelope(error.response?.statusCode, data);
      }
      throw ApiException(
        code: 'network',
        message: 'The server did not answer. Check the address, or turn on offline mock.',
        status: error.response?.statusCode,
      );
    }
  }

  @override
  Future<HealthInfo> health() async {
    return HealthInfo.fromJson(await _send(_dio.get('/api/v1/health')));
  }

  @override
  Future<LoginResult> login(String username, String password) async {
    return LoginResult.fromJson(
      await _send(
        _dio.post(
          '/api/v1/auth/login',
          data: {'username': username, 'password': password},
        ),
      ),
    );
  }

  @override
  Future<void> logout() async {
    await _send(_dio.post('/api/v1/auth/logout'));
  }

  @override
  Future<Me> me() async {
    return Me.fromJson(await _send(_dio.get('/api/v1/auth/me')));
  }

  @override
  Future<List<Merchant>> merchants() async {
    final data = await _send(_dio.get('/api/v1/merchants'));
    return mapMerchants(data['merchants']);
  }

  @override
  Future<List<SearchHit>> search(String query) async {
    final data = await _send(
      _dio.get('/api/v1/search', queryParameters: {'q': query}),
    );
    return (data['results'] as List? ?? const [])
        .map(
          (item) => SearchHit.fromJson((item as Map).cast<String, dynamic>()),
        )
        .toList();
  }

  Future<DemoScript> _demo(String path) async {
    return DemoScript.fromJson(await _send(_dio.post(path)));
  }

  @override
  Future<DemoScript> demo() async =>
      DemoScript.fromJson(await _send(_dio.get('/api/v1/demo')));

  @override
  Future<DemoScript> demoStart() => _demo('/api/v1/demo/start');

  @override
  Future<DemoScript> demoNext() => _demo('/api/v1/demo/next');

  @override
  Future<DemoScript> demoBack() => _demo('/api/v1/demo/back');

  @override
  Future<DemoScript> demoStop() => _demo('/api/v1/demo/stop');

  @override
  Future<WalletSnapshot> wallet() async {
    return WalletSnapshot.fromJson(await _send(_dio.get('/api/v1/wallet')));
  }

  @override
  Future<List<Txn>> transactions({int limit = 20}) async {
    final data = await _send(
      _dio.get('/api/v1/transactions', queryParameters: {'limit': limit}),
    );
    return _txns(data['transactions']);
  }

  @override
  Future<List<Txn>> activity() async {
    final data = await _send(_dio.get('/api/v1/activity'));
    return _txns(data['activity']);
  }

  @override
  Future<List<Contact>> contacts() async {
    final data = await _send(_dio.get('/api/v1/contacts'));
    return (data['contacts'] as List? ?? const [])
        .map((item) => Contact.fromJson((item as Map).cast<String, dynamic>()))
        .toList();
  }

  @override
  Future<TransferResult> createTransfer({
    required int amountCents,
    required String currency,
    required String kind,
    String? recipientName,
    int? recipientId,
    String? merchantName,
    int? merchantId,
  }) async {
    return TransferResult.fromJson(
      await _send(
        _dio.post(
          '/api/v1/transfers',
          data: {
            'amount_cents': amountCents,
            'currency': currency,
            'kind': kind,
            'recipient_name': ?recipientName,
            'recipient_id': ?recipientId,
            'merchant_name': ?merchantName,
            'merchant_id': ?merchantId,
          },
        ),
      ),
    );
  }

  @override
  Future<Txn> transfer(int id) async {
    final data = await _send(_dio.get('/api/v1/transfers/$id'));
    return Txn.fromJson((data['transaction'] as Map).cast<String, dynamic>());
  }

  @override
  Future<ConfirmResult> confirmTransfer(
    int id, {
    required String confirmWord,
    required String pin,
    bool riskAck = false,
  }) async {
    return ConfirmResult.fromJson(
      await _send(
        _dio.post(
          '/api/v1/transfers/$id/confirm',
          data: {
            'confirm_word': confirmWord,
            'pin': pin,
            if (riskAck) 'risk_ack': true,
          },
        ),
      ),
    );
  }

  @override
  Future<Txn> cancelTransfer(int id) async {
    final data = await _send(_dio.post('/api/v1/transfers/$id/cancel'));
    return Txn.fromJson((data['transaction'] as Map).cast<String, dynamic>());
  }

  @override
  Future<VoiceCatalog> voicePhrases() async {
    return VoiceCatalog.fromJson(
      await _send(_dio.get('/api/v1/voice/phrases')),
    );
  }

  @override
  Future<VoiceInterpretation> interpretText(String text) async {
    return VoiceInterpretation.fromJson(
      await _send(_dio.post('/api/v1/voice/interpret', data: {'text': text})),
    );
  }

  @override
  Future<VoiceInterpretation> interpretSample(String sampleId) async {
    return VoiceInterpretation.fromJson(
      await _send(
        _dio.post('/api/v1/voice/interpret', data: {'sample_id': sampleId}),
      ),
    );
  }

  @override
  Future<VoiceInterpretation> interpretAudio(
    Uint8List bytes,
    String filename, {
    String? language,
  }) async {
    final form = FormData.fromMap({
      'audio': MultipartFile.fromBytes(bytes, filename: filename),
      'language': ?language,
    });
    return VoiceInterpretation.fromJson(
      await _send(_dio.post('/api/v1/voice/interpret', data: form)),
    );
  }

  @override
  Future<TransferResult> prepareVoice(Map<String, dynamic> plan) async {
    return TransferResult.fromJson(
      await _send(_dio.post('/api/v1/voice/prepare', data: {'plan': plan})),
    );
  }

  @override
  Future<ConfirmResult> confirmVoice({
    required int txnId,
    required String confirmWord,
    required String pin,
    bool riskAck = false,
  }) async {
    return ConfirmResult.fromJson(
      await _send(
        _dio.post(
          '/api/v1/voice/confirm',
          data: {
            'txn_id': txnId,
            'confirm_word': confirmWord,
            'pin': pin,
            if (riskAck) 'risk_ack': true,
          },
        ),
      ),
    );
  }

  @override
  Future<CoachState> coach() async =>
      CoachState.fromJson(await _send(_dio.get('/api/v1/coach')));

  @override
  Future<CoachReply> coachSend(String text) async {
    return CoachReply.fromJson(
      await _send(_dio.post('/api/v1/coach/messages', data: {'text': text})),
    );
  }

  @override
  Future<List<ScamSample>> scamSamples() async {
    final data = await _send(_dio.get('/api/v1/scam/samples'));
    return (data['samples'] as List? ?? const [])
        .map(
          (item) => ScamSample.fromJson((item as Map).cast<String, dynamic>()),
        )
        .toList();
  }

  @override
  Future<ScamReport> scamCheck({String? sample, String? text}) async {
    final data = await _send(
      _dio.post(
        '/api/v1/scam/check',
        data: {
          'sample': ?sample,
          'text': ?text,
        },
      ),
    );
    return ScamReport.fromJson((data['report'] as Map).cast<String, dynamic>());
  }

  @override
  Future<ReceiptBook> receipts() async =>
      ReceiptBook.fromJson(await _send(_dio.get('/api/v1/receipts')));

  @override
  Future<List<ReceiptSample>> receiptSamples() async {
    final data = await _send(_dio.get('/api/v1/receipts/samples'));
    return (data['samples'] as List? ?? const [])
        .map(
          (item) =>
              ReceiptSample.fromJson((item as Map).cast<String, dynamic>()),
        )
        .toList();
  }

  @override
  Future<ReceiptImage> receiptSampleImage(String filename) async {
    return ReceiptImage.fromJson(
      await _send(_dio.get('/api/v1/receipts/samples/$filename')),
    );
  }

  @override
  Future<ReceiptExtraction> readReceiptSample(String sample) async {
    final data = await _send(
      _dio.post('/api/v1/receipts/read', data: {'sample': sample}),
    );
    return ReceiptExtraction.fromJson(
      (data['extraction'] as Map).cast<String, dynamic>(),
    );
  }

  @override
  Future<ReceiptExtraction> readReceiptImage(
    Uint8List bytes,
    String filename,
  ) async {
    final form = FormData.fromMap({
      'image': MultipartFile.fromBytes(bytes, filename: filename),
    });
    final data = await _send(_dio.post('/api/v1/receipts/read', data: form));
    return ReceiptExtraction.fromJson(
      (data['extraction'] as Map).cast<String, dynamic>(),
    );
  }

  @override
  Future<ReceiptEntry> saveReceipt({
    required String vendor,
    required String receiptDate,
    required String currency,
    required int totalCents,
    required String notes,
    required List<ReceiptItem> items,
  }) async {
    final data = await _send(
      _dio.post(
        '/api/v1/receipts',
        data: {
          'vendor': vendor,
          'receipt_date': receiptDate,
          'currency': currency,
          'total_cents': totalCents,
          'notes': notes,
          'items': items.map((item) => item.toJson()).toList(),
        },
      ),
    );
    return ReceiptEntry.fromJson(
      (data['entry'] as Map).cast<String, dynamic>(),
    );
  }

  @override
  Future<ReceiptExport> exportReceipts() async {
    return ReceiptExport.fromJson(
      await _send(_dio.get('/api/v1/receipts/export')),
    );
  }

  @override
  Future<AccessState> accessibility() async {
    return AccessState.fromJson(await _send(_dio.get('/api/v1/accessibility')));
  }

  @override
  Future<AccessSettings> updateAccessibility({
    bool? largeType,
    bool? highContrast,
    bool? speakBalances,
  }) async {
    final data = await _send(
      _dio.put(
        '/api/v1/accessibility',
        data: {
          'large_type': ?largeType,
          'high_contrast': ?highContrast,
          'speak_balances': ?speakBalances,
        },
      ),
    );
    return AccessSettings.fromJson(
      (data['settings'] as Map).cast<String, dynamic>(),
    );
  }

  @override
  Future<PulseSnapshot> pulse() async =>
      PulseSnapshot.fromJson(await _send(_dio.get('/api/v1/pulse')));

  @override
  Future<PulsePublish> publishPulse() async {
    return PulsePublish.fromJson(
      await _send(_dio.post('/api/v1/pulse/publish')),
    );
  }

  @override
  Future<PulseHighlight> highlightPulse() async {
    return PulseHighlight.fromJson(
      await _send(_dio.post('/api/v1/pulse/highlight')),
    );
  }

  @override
  Future<SopBundle> onboardingDocs() async {
    return SopBundle.fromJson(
      await _send(_dio.get('/api/v1/onboarding/documents')),
    );
  }

  @override
  Future<BuddyAnswer> onboardingAsk(String question) async {
    return BuddyAnswer.fromJson(
      await _send(
        _dio.post('/api/v1/onboarding/ask', data: {'question': question}),
      ),
    );
  }

  @override
  Future<QuizPaper> onboardingQuiz() async {
    return QuizPaper.fromJson(
      await _send(_dio.post('/api/v1/onboarding/quiz')),
    );
  }

  @override
  Future<QuizScore> onboardingScore(Map<String, String> answers) async {
    final data = await _send(
      _dio.post('/api/v1/onboarding/quiz/score', data: {'answers': answers}),
    );
    return QuizScore.fromJson((data['score'] as Map).cast<String, dynamic>());
  }

  @override
  Future<LedgerBook> ledger() async =>
      LedgerBook.fromJson(await _send(_dio.get('/api/v1/ledger')));

  @override
  Future<List<AiCall>> aiLog() async {
    final data = await _send(_dio.get('/api/v1/ai-log'));
    return (data['calls'] as List? ?? const [])
        .map((item) => AiCall.fromJson((item as Map).cast<String, dynamic>()))
        .toList();
  }

  @override
  Future<TransferResult> prizeRiskTransfer() async {
    return TransferResult.fromJson(
      await _send(_dio.post('/api/v1/demo/risk-transfer')),
    );
  }

  @override
  Future<ImpactReport> impact() async {
    return ImpactReport.fromJson(await _send(_dio.get('/api/v1/impact')));
  }

  @override
  Future<ChannelTurn> ussd({String? sessionId, String text = ''}) async {
    return ChannelTurn.fromJson(
      await _send(
        _dio.post(
          '/api/v1/channels/ussd',
          data: {
            'session_id': ?sessionId,
            'text': text,
            'service_code': '*151#',
          },
        ),
      ),
    );
  }

  @override
  Future<ChannelTurn> chat({String? sessionId, String text = ''}) async {
    return ChannelTurn.fromJson(
      await _send(
        _dio.post(
          '/api/v1/channels/chat',
          data: {'session_id': ?sessionId, 'text': text},
        ),
      ),
    );
  }

  @override
  Future<CopilotCase> copilot(int itemId) async {
    return CopilotCase.fromJson(
      await _send(_dio.get('/api/v1/pulse/$itemId/copilot')),
    );
  }

  @override
  Future<CopilotCase> refreshCopilot(int itemId) async {
    return CopilotCase.fromJson(
      await _send(_dio.post('/api/v1/pulse/$itemId/copilot')),
    );
  }

  @override
  Future<DecisionResult> decidePulse(
    int itemId, {
    required String action,
    String text = '',
  }) async {
    return DecisionResult.fromJson(
      await _send(
        _dio.post(
          '/api/v1/pulse/$itemId/decision',
          data: {'action': action, 'text': text},
        ),
      ),
    );
  }

  @override
  Future<List<AuditEntry>> audit() async {
    final data = await _send(_dio.get('/api/v1/audit'));
    return (data['entries'] as List? ?? const [])
        .map(
          (item) => AuditEntry.fromJson((item as Map).cast<String, dynamic>()),
        )
        .toList();
  }
}

List<Merchant> mapMerchants(dynamic raw) {
  return (raw as List? ?? const [])
      .map((item) => Merchant.fromJson((item as Map).cast<String, dynamic>()))
      .toList();
}

List<Txn> _txns(dynamic raw) {
  return (raw as List? ?? const [])
      .map((item) => Txn.fromJson((item as Map).cast<String, dynamic>()))
      .toList();
}
