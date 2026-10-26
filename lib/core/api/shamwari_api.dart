import 'dart:typed_data';

import '../models/models.dart';

/// Mobile contract. Money is integer cents. The PIN is accepted only by the
/// two confirm methods.
abstract class ShamwariApi {
  Future<HealthInfo> health();
  Future<LoginResult> login(String username, String password);
  Future<void> logout();
  Future<Me> me();
  Future<List<Merchant>> merchants();
  Future<List<SearchHit>> search(String query);
  Future<DemoScript> demo();
  Future<DemoScript> demoStart();
  Future<DemoScript> demoNext();
  Future<DemoScript> demoBack();
  Future<DemoScript> demoStop();
  Future<WalletSnapshot> wallet();
  Future<List<Txn>> transactions({int limit = 20});
  Future<List<Txn>> activity();
  Future<List<Contact>> contacts();
  Future<TransferResult> createTransfer({
    required int amountCents,
    required String currency,
    required String kind,
    String? recipientName,
    int? recipientId,
    String? merchantName,
    int? merchantId,
  });
  Future<Txn> transfer(int id);
  Future<ConfirmResult> confirmTransfer(
    int id, {
    required String confirmWord,
    required String pin,
  });
  Future<Txn> cancelTransfer(int id);
  Future<VoiceCatalog> voicePhrases();
  Future<VoiceInterpretation> interpretText(String text);
  Future<VoiceInterpretation> interpretAudio(
    Uint8List bytes,
    String filename, {
    String? language,
  });
  Future<TransferResult> prepareVoice(Map<String, dynamic> plan);
  Future<ConfirmResult> confirmVoice({
    required int txnId,
    required String confirmWord,
    required String pin,
  });
  Future<CoachState> coach();
  Future<CoachReply> coachSend(String text);
  Future<List<ScamSample>> scamSamples();
  Future<ScamReport> scamCheck({String? sample, String? text});
  Future<ReceiptBook> receipts();
  Future<List<ReceiptSample>> receiptSamples();
  Future<ReceiptImage> receiptSampleImage(String filename);
  Future<ReceiptExtraction> readReceiptSample(String sample);
  Future<ReceiptExtraction> readReceiptImage(Uint8List bytes, String filename);
  Future<ReceiptEntry> saveReceipt({
    required String vendor,
    required String receiptDate,
    required String currency,
    required int totalCents,
    required String notes,
    required List<ReceiptItem> items,
  });
  Future<ReceiptExport> exportReceipts();
  Future<AccessState> accessibility();
  Future<AccessSettings> updateAccessibility({
    bool? largeType,
    bool? highContrast,
    bool? speakBalances,
  });
  Future<PulseSnapshot> pulse();
  Future<PulsePublish> publishPulse();
  Future<PulseHighlight> highlightPulse();
  Future<SopBundle> onboardingDocs();
  Future<BuddyAnswer> onboardingAsk(String question);
  Future<QuizPaper> onboardingQuiz();
  Future<QuizScore> onboardingScore(Map<String, String> answers);
  Future<LedgerBook> ledger();
  Future<List<AiCall>> aiLog();
}
