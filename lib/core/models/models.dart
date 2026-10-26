import '../json.dart';

class UserAccount {
  const UserAccount({
    required this.id,
    required this.username,
    required this.role,
    required this.displayName,
    this.customerId,
  });

  final int id;
  final String username;
  final String role;
  final String displayName;
  final int? customerId;

  bool get isStaff => role == 'staff';
  bool get isCustomer => role == 'customer';

  factory UserAccount.fromJson(Map<String, dynamic> json) {
    return UserAccount(
      id: asInt(json['id']),
      username: asString(json['username']),
      role: asString(json['role']),
      displayName: asString(json['display_name']),
      customerId: asIntOrNull(json['customer_id']),
    );
  }
}

class CustomerProfile {
  const CustomerProfile({
    required this.id,
    required this.fullName,
    required this.shortName,
    required this.city,
    required this.language,
    required this.role,
    required this.phoneMasked,
  });

  final int id;
  final String fullName;
  final String shortName;
  final String city;
  final String language;
  final String role;
  final String phoneMasked;

  factory CustomerProfile.fromJson(Map<String, dynamic> json) {
    return CustomerProfile(
      id: asInt(json['id']),
      fullName: asString(json['full_name']),
      shortName: asString(json['short_name'], asString(json['full_name'])),
      city: asString(json['city']),
      language: asString(json['language']),
      role: asString(json['role']),
      phoneMasked: asString(json['phone_masked']),
    );
  }
}

class Wallet {
  const Wallet({
    required this.currency,
    required this.balanceCents,
    required this.pendingCents,
    required this.availableCents,
    required this.displayBalance,
    required this.displayAvailable,
  });

  final String currency;
  final int balanceCents;
  final int pendingCents;
  final int availableCents;
  final String displayBalance;
  final String displayAvailable;

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      currency: asString(json['currency']),
      balanceCents: asInt(json['balance_cents']),
      pendingCents: asInt(json['pending_cents']),
      availableCents: asInt(json['available_cents']),
      displayBalance: asString(json['display_balance']),
      displayAvailable: asString(json['display_available']),
    );
  }
}

class SavingsGoal {
  const SavingsGoal({
    required this.name,
    required this.currency,
    required this.savedCents,
    required this.targetCents,
    required this.displaySaved,
    required this.displayTarget,
    required this.dueDate,
    required this.expectedCents,
    required this.onTrack,
    required this.remainingDays,
    required this.weeklyCents,
  });

  final String name;
  final String currency;
  final int savedCents;
  final int targetCents;
  final String displaySaved;
  final String displayTarget;
  final String dueDate;
  final int expectedCents;
  final bool onTrack;
  final int remainingDays;
  final int weeklyCents;

  double get progress =>
      targetCents == 0 ? 0 : (savedCents / targetCents).clamp(0, 1);

  factory SavingsGoal.fromJson(Map<String, dynamic> json) {
    return SavingsGoal(
      name: asString(json['name']),
      currency: asString(json['currency'], 'USD'),
      savedCents: asInt(json['saved_cents']),
      targetCents: asInt(json['target_cents']),
      displaySaved: asString(json['display_saved']),
      displayTarget: asString(json['display_target']),
      dueDate: asString(json['due_date']),
      expectedCents: asInt(json['expected_cents']),
      onTrack: asBool(json['on_track']),
      remainingDays: asInt(json['remaining_days']),
      weeklyCents: asInt(json['weekly_cents']),
    );
  }
}

class SpendDay {
  const SpendDay({
    required this.label,
    required this.date,
    required this.amountCents,
    required this.display,
    required this.peak,
  });

  final String label;
  final String date;
  final int amountCents;
  final String display;
  final bool peak;

  factory SpendDay.fromJson(Map<String, dynamic> json) {
    return SpendDay(
      label: asString(json['label']),
      date: asString(json['date']),
      amountCents: asInt(json['amount_cents']),
      display: asString(json['display']),
      peak: asBool(json['peak']),
    );
  }
}

class WeekSpend {
  const WeekSpend({
    required this.totalCents,
    required this.display,
    required this.deltaPct,
    required this.days,
  });

  final int totalCents;
  final String display;
  final int? deltaPct;
  final List<SpendDay> days;

  factory WeekSpend.fromJson(Map<String, dynamic> json) {
    return WeekSpend(
      totalCents: asInt(json['total_cents']),
      display: asString(json['display']),
      deltaPct: asIntOrNull(json['delta_pct']),
      days: mapList(json['days'], SpendDay.fromJson),
    );
  }
}

class WalletSnapshot {
  const WalletSnapshot({
    required this.customer,
    required this.wallets,
    required this.goal,
    required this.week,
    required this.pendingCount,
  });

  final CustomerProfile customer;
  final List<Wallet> wallets;
  final SavingsGoal? goal;
  final WeekSpend week;
  final int pendingCount;

  Wallet? wallet(String currency) {
    for (final item in wallets) {
      if (item.currency == currency) return item;
    }
    return wallets.isEmpty ? null : wallets.first;
  }

  factory WalletSnapshot.fromJson(Map<String, dynamic> json) {
    final goal = json['goal'];
    return WalletSnapshot(
      customer: CustomerProfile.fromJson(asMap(json['customer'])),
      wallets: mapList(json['wallets'], Wallet.fromJson),
      goal: goal == null ? null : SavingsGoal.fromJson(asMap(goal)),
      week: WeekSpend.fromJson(asMap(json['week'])),
      pendingCount: asInt(json['pending_count']),
    );
  }
}

class Txn {
  const Txn({
    required this.id,
    required this.reference,
    required this.kind,
    required this.category,
    required this.status,
    required this.amountCents,
    required this.currency,
    required this.display,
    required this.senderId,
    required this.recipientId,
    required this.merchantId,
    required this.counterparty,
    required this.note,
    required this.outgoing,
    required this.createdAt,
    required this.postedAt,
    this.name,
    this.initials,
  });

  final int id;
  final String reference;
  final String kind;
  final String category;
  final String status;
  final int amountCents;
  final String currency;
  final String display;
  final int? senderId;
  final int? recipientId;
  final int? merchantId;
  final String counterparty;
  final String note;
  final bool? outgoing;
  final String createdAt;
  final String? postedAt;
  final String? name;
  final String? initials;

  String get title => (name == null || name!.isEmpty) ? counterparty : name!;

  factory Txn.fromJson(Map<String, dynamic> json) {
    return Txn(
      id: asInt(json['id']),
      reference: asString(json['reference']),
      kind: asString(json['kind']),
      category: asString(json['category']),
      status: asString(json['status']),
      amountCents: asInt(json['amount_cents']),
      currency: asString(json['currency']),
      display: asString(json['display']),
      senderId: asIntOrNull(json['sender_id']),
      recipientId: asIntOrNull(json['recipient_id']),
      merchantId: asIntOrNull(json['merchant_id']),
      counterparty: asString(json['counterparty']),
      note: asString(json['note']),
      outgoing: json['outgoing'] is bool ? json['outgoing'] as bool : null,
      createdAt: asString(json['created_at']),
      postedAt: asStringOrNull(json['posted_at']),
      name: asStringOrNull(json['name']),
      initials: asStringOrNull(json['initials']),
    );
  }
}

class Contact {
  const Contact({
    required this.id,
    required this.name,
    required this.city,
    required this.customerId,
  });

  final int id;
  final String name;
  final String city;
  final int customerId;

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: asInt(json['id']),
      name: asString(json['name']),
      city: asString(json['city']),
      customerId: asInt(json['customer_id']),
    );
  }
}

class Merchant {
  const Merchant({
    required this.id,
    required this.name,
    required this.category,
    required this.city,
  });

  final int id;
  final String name;
  final String category;
  final String city;

  factory Merchant.fromJson(Map<String, dynamic> json) {
    return Merchant(
      id: asInt(json['id']),
      name: asString(json['name']),
      category: asString(json['category']),
      city: asString(json['city']),
    );
  }
}

class SearchHit {
  const SearchHit({
    required this.label,
    required this.group,
    required this.hint,
    required this.apiPath,
  });

  final String label;
  final String group;
  final String hint;
  final String? apiPath;

  factory SearchHit.fromJson(Map<String, dynamic> json) {
    return SearchHit(
      label: asString(json['label']),
      group: asString(json['group']),
      hint: asString(json['hint']),
      apiPath: json['api_path'] == null ? null : asString(json['api_path']),
    );
  }
}

class DemoStep {
  const DemoStep({
    required this.number,
    required this.slug,
    required this.role,
    required this.kicker,
    required this.title,
    required this.narration,
    required this.action,
    required this.calls,
  });

  final int number;
  final String slug;
  final String role;
  final String kicker;
  final String title;
  final String narration;
  final String action;
  final List<String> calls;

  factory DemoStep.fromJson(Map<String, dynamic> json) {
    return DemoStep(
      number: asInt(json['number']),
      slug: asString(json['slug']),
      role: asString(json['role']),
      kicker: asString(json['kicker']),
      title: asString(json['title']),
      narration: asString(json['narration']),
      action: asString(json['action']),
      calls: asList(json['calls']).map((item) => item.toString()).toList(),
    );
  }
}

class DemoScript {
  const DemoScript({
    required this.active,
    required this.done,
    required this.index,
    required this.total,
    required this.current,
    required this.demoPin,
    required this.yesWords,
    required this.pinRule,
    required this.steps,
  });

  final bool active;
  final bool done;
  final int? index;
  final int total;
  final DemoStep? current;
  final String demoPin;
  final List<String> yesWords;
  final String pinRule;
  final List<DemoStep> steps;

  factory DemoScript.fromJson(Map<String, dynamic> json) {
    return DemoScript(
      active: asBool(json['active']),
      done: asBool(json['done']),
      index: asIntOrNull(json['index']),
      total: asInt(json['total']),
      current: json['current'] == null
          ? null
          : DemoStep.fromJson(asMap(json['current'])),
      demoPin: asString(json['demo_pin']),
      yesWords: asList(json['yes_words'])
          .map((item) => item.toString())
          .toList(),
      pinRule: asString(json['pin_rule']),
      steps: mapList(json['steps'], DemoStep.fromJson),
    );
  }
}

class VoicePhrase {
  const VoicePhrase({
    required this.language,
    required this.label,
    required this.text,
    required this.hint,
  });

  final String language;
  final String label;
  final String text;
  final String hint;

  factory VoicePhrase.fromJson(Map<String, dynamic> json) {
    return VoicePhrase(
      language: asString(json['language']),
      label: asString(json['label']),
      text: asString(json['text']),
      hint: asString(json['hint']),
    );
  }
}

class VoiceCatalog {
  const VoiceCatalog({
    required this.demoPin,
    required this.yesWords,
    required this.pinRule,
    required this.phrases,
  });

  final String demoPin;
  final List<String> yesWords;
  final String pinRule;
  final List<VoicePhrase> phrases;

  factory VoiceCatalog.fromJson(Map<String, dynamic> json) {
    return VoiceCatalog(
      demoPin: asString(json['demo_pin']),
      yesWords: asList(json['yes_words'])
          .map((item) => item.toString())
          .toList(),
      pinRule: asString(json['pin_rule']),
      phrases: mapList(json['phrases'], VoicePhrase.fromJson),
    );
  }
}

class VoicePlan {
  const VoicePlan({
    required this.intent,
    required this.amountCents,
    required this.currency,
    required this.language,
    required this.recipientId,
    required this.recipientName,
    required this.merchantId,
    required this.merchantName,
    required this.missing,
    required this.ambiguous,
    required this.unknownName,
    required this.locked,
    required this.confidence,
    required this.sentence,
    required this.source,
    required this.redacted,
    required this.providerNote,
    required this.transcript,
    required this.availableCents,
  });

  final String intent;
  final int? amountCents;
  final String currency;
  final String language;
  final int? recipientId;
  final String recipientName;
  final int? merchantId;
  final String merchantName;
  final List<String> missing;
  final List<String> ambiguous;
  final String unknownName;
  final bool locked;
  final double confidence;
  final String sentence;
  final String source;
  final bool redacted;
  final String providerNote;
  final String transcript;
  final int? availableCents;

  bool get readyToPrepare =>
      missing.isEmpty &&
      (intent == 'send_money' ||
          intent == 'buy_airtime' ||
          intent == 'pay_merchant');

  Map<String, dynamic> toJson() {
    return {
      'intent': intent,
      'amount_cents': amountCents,
      'currency': currency,
      'language': language,
      'recipient_id': recipientId,
      'recipient_name': recipientName,
      'merchant_id': merchantId,
      'merchant_name': merchantName,
      'missing': missing,
      'ambiguous': ambiguous,
      'unknown_name': unknownName,
      'locked': locked,
      'confidence': confidence,
      'sentence': sentence,
      'source': source,
      'redacted': redacted,
      'provider_note': providerNote,
      'transcript': transcript,
      'available_cents': availableCents,
    };
  }

  factory VoicePlan.fromJson(Map<String, dynamic> json) {
    return VoicePlan(
      intent: asString(json['intent']),
      amountCents: asIntOrNull(json['amount_cents']),
      currency: asString(json['currency'], 'USD'),
      language: asString(json['language'], 'en'),
      recipientId: asIntOrNull(json['recipient_id']),
      recipientName: asString(json['recipient_name']),
      merchantId: asIntOrNull(json['merchant_id']),
      merchantName: asString(json['merchant_name']),
      missing: asList(json['missing']).map((item) => item.toString()).toList(),
      ambiguous: asList(json['ambiguous'])
          .map((item) => item.toString())
          .toList(),
      unknownName: asString(json['unknown_name']),
      locked: asBool(json['locked']),
      confidence: asDouble(json['confidence']),
      sentence: asString(json['sentence']),
      source: asString(json['source']),
      redacted: asBool(json['redacted']),
      providerNote: asString(json['provider_note']),
      transcript: asString(json['transcript']),
      availableCents: asIntOrNull(json['available_cents']),
    );
  }
}

class VoiceInterpretation {
  const VoiceInterpretation({
    required this.transcript,
    required this.transcriptNote,
    required this.balances,
    required this.plan,
  });

  final String transcript;
  final String transcriptNote;
  final List<Wallet> balances;
  final VoicePlan plan;

  factory VoiceInterpretation.fromJson(Map<String, dynamic> json) {
    return VoiceInterpretation(
      transcript: asString(json['transcript']),
      transcriptNote: asString(json['transcript_note']),
      balances: mapList(json['balances'], Wallet.fromJson),
      plan: VoicePlan.fromJson(asMap(json['plan'])),
    );
  }
}

class TransferResult {
  const TransferResult({
    required this.outcome,
    required this.transaction,
    this.message = '',
  });

  final String outcome;
  final Txn transaction;
  final String message;

  factory TransferResult.fromJson(Map<String, dynamic> json) {
    return TransferResult(
      outcome: asString(json['outcome']),
      transaction: Txn.fromJson(asMap(json['transaction'])),
      message: asString(json['message']),
    );
  }
}

class ConfirmResult {
  const ConfirmResult({
    required this.outcome,
    required this.pinCheckedLocally,
    required this.pinSentToModel,
    required this.transaction,
  });

  final String outcome;
  final bool pinCheckedLocally;
  final bool pinSentToModel;
  final Txn transaction;

  factory ConfirmResult.fromJson(Map<String, dynamic> json) {
    return ConfirmResult(
      outcome: asString(json['outcome']),
      pinCheckedLocally: asBool(json['pin_checked_locally']),
      pinSentToModel: asBool(json['pin_sent_to_model']),
      transaction: Txn.fromJson(asMap(json['transaction'])),
    );
  }
}

class CoachMessage {
  const CoachMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  final int id;
  final String role;
  final String content;
  final String createdAt;

  bool get fromUser => role == 'user';

  factory CoachMessage.fromJson(Map<String, dynamic> json) {
    return CoachMessage(
      id: asInt(json['id']),
      role: asString(json['role']),
      content: asString(json['content']),
      createdAt: asString(json['created_at']),
    );
  }
}

class SpendCategory {
  const SpendCategory({
    required this.key,
    required this.label,
    required this.amountCents,
    required this.display,
    required this.share,
  });

  final String key;
  final String label;
  final int amountCents;
  final String display;
  final double share;

  factory SpendCategory.fromJson(Map<String, dynamic> json) {
    return SpendCategory(
      key: asString(json['key']),
      label: asString(json['label']),
      amountCents: asInt(json['amount_cents']),
      display: asString(json['display']),
      share: asDouble(json['share']),
    );
  }
}

class CoachState {
  const CoachState({
    required this.suggestions,
    required this.warnings,
    required this.categories,
    required this.goal,
    required this.messages,
  });

  final List<String> suggestions;
  final List<String> warnings;
  final List<SpendCategory> categories;
  final SavingsGoal? goal;
  final List<CoachMessage> messages;

  factory CoachState.fromJson(Map<String, dynamic> json) {
    final goal = json['goal'];
    return CoachState(
      suggestions: asList(json['suggestions'])
          .map((item) => item.toString())
          .toList(),
      warnings: asList(json['warnings'])
          .map((item) => item.toString())
          .toList(),
      categories: mapList(json['categories'], SpendCategory.fromJson),
      goal: goal == null ? null : SavingsGoal.fromJson(asMap(goal)),
      messages: mapList(json['messages'], CoachMessage.fromJson),
    );
  }
}

class CoachReply {
  const CoachReply({
    required this.reply,
    required this.note,
    required this.messages,
  });

  final CoachMessage reply;
  final String note;
  final List<CoachMessage> messages;

  factory CoachReply.fromJson(Map<String, dynamic> json) {
    return CoachReply(
      reply: CoachMessage.fromJson(asMap(json['reply'])),
      note: asString(json['note']),
      messages: mapList(json['messages'], CoachMessage.fromJson),
    );
  }
}

class ScamSample {
  const ScamSample({required this.id, required this.title, required this.text});

  final String id;
  final String title;
  final String text;

  factory ScamSample.fromJson(Map<String, dynamic> json) {
    return ScamSample(
      id: asString(json['id']),
      title: asString(json['title']),
      text: asString(json['text']),
    );
  }
}

class ScamReport {
  const ScamReport({
    required this.verdict,
    required this.label,
    required this.rulesVerdict,
    required this.rulesLabel,
    required this.aiVerdict,
    required this.aiConfidence,
    required this.source,
    required this.patterns,
    required this.steps,
    required this.note,
    required this.errorDetail,
  });

  final String verdict;
  final String label;
  final String rulesVerdict;
  final String rulesLabel;
  final String aiVerdict;
  final double aiConfidence;
  final String source;
  final List<String> patterns;
  final List<String> steps;
  final String note;
  final String errorDetail;

  factory ScamReport.fromJson(Map<String, dynamic> json) {
    return ScamReport(
      verdict: asString(json['verdict']),
      label: asString(json['label']),
      rulesVerdict: asString(json['rules_verdict']),
      rulesLabel: asString(json['rules_label']),
      aiVerdict: asString(json['ai_verdict']),
      aiConfidence: asDouble(json['ai_confidence']),
      source: asString(json['source']),
      patterns: asList(json['patterns'])
          .map((item) => item.toString())
          .toList(),
      steps: asList(json['steps']).map((item) => item.toString()).toList(),
      note: asString(json['note']),
      errorDetail: asString(json['error_detail']),
    );
  }
}

class ReceiptItem {
  const ReceiptItem({required this.description, required this.amountCents});

  final String description;
  final int amountCents;

  factory ReceiptItem.fromJson(Map<String, dynamic> json) {
    return ReceiptItem(
      description: asString(json['description']),
      amountCents: asInt(json['amount_cents']),
    );
  }

  Map<String, dynamic> toJson() => {
    'description': description,
    'amount_cents': amountCents,
  };
}

class ReceiptEntry {
  const ReceiptEntry({
    required this.id,
    required this.merchantId,
    required this.merchant,
    required this.vendor,
    required this.receiptDate,
    required this.totalCents,
    required this.currency,
    required this.display,
    required this.items,
    required this.notes,
    required this.sourceName,
    required this.createdAt,
  });

  final int id;
  final int merchantId;
  final String merchant;
  final String vendor;
  final String receiptDate;
  final int totalCents;
  final String currency;
  final String display;
  final List<ReceiptItem> items;
  final String notes;
  final String sourceName;
  final String createdAt;

  factory ReceiptEntry.fromJson(Map<String, dynamic> json) {
    return ReceiptEntry(
      id: asInt(json['id']),
      merchantId: asInt(json['merchant_id']),
      merchant: asString(json['merchant']),
      vendor: asString(json['vendor']),
      receiptDate: asString(json['receipt_date']),
      totalCents: asInt(json['total_cents']),
      currency: asString(json['currency']),
      display: asString(json['display']),
      items: mapList(json['items'], ReceiptItem.fromJson),
      notes: asString(json['notes']),
      sourceName: asString(json['source_name']),
      createdAt: asString(json['created_at']),
    );
  }
}

class ReceiptSample {
  const ReceiptSample({
    required this.filename,
    required this.vendor,
    required this.date,
    required this.currency,
    required this.note,
    required this.title,
    required this.payload,
  });

  final String filename;
  final String vendor;
  final String date;
  final String currency;
  final String note;
  final String title;
  final String payload;

  factory ReceiptSample.fromJson(Map<String, dynamic> json) {
    return ReceiptSample(
      filename: asString(json['filename']),
      vendor: asString(json['vendor']),
      date: asString(json['date']),
      currency: asString(json['currency']),
      note: asString(json['note']),
      title: asString(json['title']),
      payload: asString(json['payload']),
    );
  }
}

class ReceiptBook {
  const ReceiptBook({required this.merchant, required this.entries});

  final Merchant merchant;
  final List<ReceiptEntry> entries;

  factory ReceiptBook.fromJson(Map<String, dynamic> json) {
    return ReceiptBook(
      merchant: Merchant.fromJson(asMap(json['merchant'])),
      entries: mapList(json['entries'], ReceiptEntry.fromJson),
    );
  }
}

class ReceiptExtraction {
  const ReceiptExtraction({
    required this.vendor,
    required this.date,
    required this.currency,
    required this.totalCents,
    required this.display,
    required this.items,
    required this.note,
    required this.source,
  });

  final String vendor;
  final String date;
  final String currency;
  final int totalCents;
  final String display;
  final List<ReceiptItem> items;
  final String note;
  final String source;

  factory ReceiptExtraction.fromJson(Map<String, dynamic> json) {
    return ReceiptExtraction(
      vendor: asString(json['vendor']),
      date: asString(json['date']),
      currency: asString(json['currency'], 'USD'),
      totalCents: asInt(json['total_cents']),
      display: asString(json['display']),
      items: mapList(json['items'], ReceiptItem.fromJson),
      note: asString(json['note']),
      source: asString(json['source']),
    );
  }
}

class ReceiptImage {
  const ReceiptImage({
    required this.filename,
    required this.mediaType,
    required this.base64,
  });

  final String filename;
  final String mediaType;
  final String base64;

  factory ReceiptImage.fromJson(Map<String, dynamic> json) {
    return ReceiptImage(
      filename: asString(json['filename']),
      mediaType: asString(json['media_type']),
      base64: asString(json['base64']),
    );
  }
}

class ReceiptExport {
  const ReceiptExport({
    required this.filename,
    required this.mediaType,
    required this.csv,
  });

  final String filename;
  final String mediaType;
  final String csv;

  factory ReceiptExport.fromJson(Map<String, dynamic> json) {
    return ReceiptExport(
      filename: asString(json['filename']),
      mediaType: asString(json['media_type']),
      csv: asString(json['csv']),
    );
  }
}

class AccessSettings {
  const AccessSettings({
    required this.largeType,
    required this.highContrast,
    required this.speakBalances,
  });

  final bool largeType;
  final bool highContrast;
  final bool speakBalances;

  factory AccessSettings.fromJson(Map<String, dynamic> json) {
    return AccessSettings(
      largeType: asBool(json['large_type']),
      highContrast: asBool(json['high_contrast']),
      speakBalances: json.containsKey('speak_balances')
          ? asBool(json['speak_balances'])
          : true,
    );
  }
}

class QrSample {
  const QrSample({
    required this.filename,
    required this.title,
    required this.payload,
  });

  final String filename;
  final String title;
  final String payload;

  factory QrSample.fromJson(Map<String, dynamic> json) {
    return QrSample(
      filename: asString(json['filename']),
      title: asString(json['title']),
      payload: asString(json['payload']),
    );
  }
}

class AccessState {
  const AccessState({
    required this.settings,
    required this.spoken,
    required this.balances,
    required this.qrSamples,
  });

  final AccessSettings settings;
  final String spoken;
  final List<Wallet> balances;
  final List<QrSample> qrSamples;

  factory AccessState.fromJson(Map<String, dynamic> json) {
    return AccessState(
      settings: AccessSettings.fromJson(asMap(json['settings'])),
      spoken: asString(json['spoken']),
      balances: mapList(json['balances'], Wallet.fromJson),
      qrSamples: mapList(json['qr_samples'], QrSample.fromJson),
    );
  }
}

class PulseDaily {
  const PulseDaily({
    required this.date,
    required this.total,
    required this.negative,
  });

  final String date;
  final int total;
  final int negative;

  factory PulseDaily.fromJson(Map<String, dynamic> json) {
    return PulseDaily(
      date: asString(json['date']),
      total: asInt(json['total']),
      negative: asInt(json['negative']),
    );
  }
}

class PulseTheme {
  const PulseTheme({required this.label, required this.count});

  final String label;
  final int count;

  factory PulseTheme.fromJson(Map<String, dynamic> json) {
    return PulseTheme(
      label: asString(json['label']),
      count: asInt(json['count']),
    );
  }
}

class PulseRegion {
  const PulseRegion({
    required this.region,
    required this.negative,
    required this.neutral,
    required this.positive,
  });

  final String region;
  final int negative;
  final int neutral;
  final int positive;

  int get volume => negative + neutral + positive;

  factory PulseRegion.fromJson(Map<String, dynamic> json) {
    return PulseRegion(
      region: asString(json['region']),
      negative: asInt(json['negative']),
      neutral: asInt(json['neutral']),
      positive: asInt(json['positive']),
    );
  }
}

class PulseSeries {
  const PulseSeries({
    required this.daily,
    required this.themes,
    required this.regions,
  });

  final List<PulseDaily> daily;
  final List<PulseTheme> themes;
  final List<PulseRegion> regions;

  factory PulseSeries.fromJson(Map<String, dynamic> json) {
    return PulseSeries(
      daily: mapList(json['daily'], PulseDaily.fromJson),
      themes: mapList(json['themes'], PulseTheme.fromJson),
      regions: mapList(json['regions'], PulseRegion.fromJson),
    );
  }
}

class PulseItem {
  const PulseItem({
    required this.id,
    required this.source,
    required this.text,
    required this.theme,
    required this.themeLabel,
    required this.sentiment,
    required this.region,
    required this.createdAt,
  });

  final int id;
  final String source;
  final String text;
  final String theme;
  final String themeLabel;
  final String sentiment;
  final String region;
  final String createdAt;

  factory PulseItem.fromJson(Map<String, dynamic> json) {
    return PulseItem(
      id: asInt(json['id']),
      source: asString(json['source']),
      text: asString(json['text']),
      theme: asString(json['theme']),
      themeLabel: asString(json['theme_label']),
      sentiment: asString(json['sentiment']),
      region: asString(json['region']),
      createdAt: asString(json['created_at']),
    );
  }
}

class PulseComplaint {
  const PulseComplaint({
    required this.theme,
    required this.label,
    required this.region,
    required this.count,
    required this.sample,
  });

  final String theme;
  final String label;
  final String region;
  final int count;
  final String sample;

  factory PulseComplaint.fromJson(Map<String, dynamic> json) {
    return PulseComplaint(
      theme: asString(json['theme']),
      label: asString(json['label']),
      region: asString(json['region']),
      count: asInt(json['count']),
      sample: asString(json['sample']),
    );
  }
}

class PulseSnapshot {
  const PulseSnapshot({
    required this.points,
    required this.complaints,
    required this.series,
    required this.feed,
  });

  final List<String> points;
  final List<PulseComplaint> complaints;
  final PulseSeries series;
  final List<PulseItem> feed;

  factory PulseSnapshot.fromJson(Map<String, dynamic> json) {
    return PulseSnapshot(
      points: asList(json['points']).map((item) => item.toString()).toList(),
      complaints: mapList(json['complaints'], PulseComplaint.fromJson),
      series: PulseSeries.fromJson(asMap(json['series'])),
      feed: mapList(json['feed'], PulseItem.fromJson),
    );
  }
}

class PulsePublish {
  const PulsePublish({required this.item, required this.series});

  final PulseItem item;
  final PulseSeries series;

  factory PulsePublish.fromJson(Map<String, dynamic> json) {
    return PulsePublish(
      item: PulseItem.fromJson(asMap(json['item'])),
      series: PulseSeries.fromJson(asMap(json['series'])),
    );
  }
}

class PulseHighlight {
  const PulseHighlight({
    required this.points,
    required this.prose,
    required this.note,
  });

  final List<String> points;
  final String prose;
  final String note;

  factory PulseHighlight.fromJson(Map<String, dynamic> json) {
    return PulseHighlight(
      points: asList(json['points']).map((item) => item.toString()).toList(),
      prose: asString(json['prose']),
      note: asString(json['note']),
    );
  }
}

class SopDoc {
  const SopDoc({required this.docId, required this.title, required this.body});

  final String docId;
  final String title;
  final String body;

  factory SopDoc.fromJson(Map<String, dynamic> json) {
    return SopDoc(
      docId: asString(json['doc_id']),
      title: asString(json['title']),
      body: asString(json['body']),
    );
  }
}

class SopBundle {
  const SopBundle({required this.fiction, required this.documents});

  final bool fiction;
  final List<SopDoc> documents;

  factory SopBundle.fromJson(Map<String, dynamic> json) {
    return SopBundle(
      fiction: asBool(json['fiction'], true),
      documents: mapList(json['documents'], SopDoc.fromJson),
    );
  }
}

class SopHit {
  const SopHit({
    required this.docId,
    required this.docTitle,
    required this.heading,
    required this.snippet,
  });

  final String docId;
  final String docTitle;
  final String heading;
  final String snippet;

  factory SopHit.fromJson(Map<String, dynamic> json) {
    return SopHit(
      docId: asString(json['doc_id']),
      docTitle: asString(json['doc_title']),
      heading: asString(json['heading']),
      snippet: asString(json['snippet']),
    );
  }
}

class BuddyAnswer {
  const BuddyAnswer({
    required this.question,
    required this.answer,
    required this.hits,
    required this.note,
  });

  final String question;
  final String answer;
  final List<SopHit> hits;
  final String note;

  factory BuddyAnswer.fromJson(Map<String, dynamic> json) {
    return BuddyAnswer(
      question: asString(json['question']),
      answer: asString(json['answer']),
      hits: mapList(json['hits'], SopHit.fromJson),
      note: asString(json['note']),
    );
  }
}

class QuizChoice {
  const QuizChoice({required this.key, required this.text});

  final String key;
  final String text;

  factory QuizChoice.fromJson(Map<String, dynamic> json) {
    return QuizChoice(key: asString(json['key']), text: asString(json['text']));
  }
}

class QuizQuestion {
  const QuizQuestion({
    required this.question,
    required this.docId,
    required this.docTitle,
    required this.choices,
  });

  final String question;
  final String docId;
  final String docTitle;
  final List<QuizChoice> choices;

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      question: asString(json['question']),
      docId: asString(json['doc_id']),
      docTitle: asString(json['doc_title']),
      choices: mapList(json['choices'], QuizChoice.fromJson),
    );
  }
}

class QuizPaper {
  const QuizPaper({required this.note, required this.questions});

  final String note;
  final List<QuizQuestion> questions;

  factory QuizPaper.fromJson(Map<String, dynamic> json) {
    return QuizPaper(
      note: asString(json['note']),
      questions: mapList(json['questions'], QuizQuestion.fromJson),
    );
  }
}

class QuizReview {
  const QuizReview({
    required this.question,
    required this.picked,
    required this.answer,
    required this.ok,
    required this.docTitle,
    required this.docId,
  });

  final String question;
  final String picked;
  final String answer;
  final bool ok;
  final String docTitle;
  final String docId;

  factory QuizReview.fromJson(Map<String, dynamic> json) {
    return QuizReview(
      question: asString(json['question']),
      picked: asString(json['picked']),
      answer: asString(json['answer']),
      ok: asBool(json['ok']),
      docTitle: asString(json['doc_title']),
      docId: asString(json['doc_id']),
    );
  }
}

class QuizScore {
  const QuizScore({
    required this.correct,
    required this.total,
    required this.review,
  });

  final int correct;
  final int total;
  final List<QuizReview> review;

  factory QuizScore.fromJson(Map<String, dynamic> json) {
    return QuizScore(
      correct: asInt(json['correct']),
      total: asInt(json['total']),
      review: mapList(json['review'], QuizReview.fromJson),
    );
  }
}

class LedgerCustomer {
  const LedgerCustomer({required this.profile, required this.wallets});

  final CustomerProfile profile;
  final List<Wallet> wallets;

  factory LedgerCustomer.fromJson(Map<String, dynamic> json) {
    return LedgerCustomer(
      profile: CustomerProfile.fromJson(json),
      wallets: mapList(json['wallets'], Wallet.fromJson),
    );
  }
}

class AgentDesk {
  const AgentDesk({
    required this.id,
    required this.name,
    required this.city,
    required this.booth,
  });

  final int id;
  final String name;
  final String city;
  final String booth;

  factory AgentDesk.fromJson(Map<String, dynamic> json) {
    return AgentDesk(
      id: asInt(json['id']),
      name: asString(json['name']),
      city: asString(json['city']),
      booth: asString(json['booth']),
    );
  }
}

class LedgerBook {
  const LedgerBook({
    required this.customers,
    required this.merchants,
    required this.agents,
    required this.transactions,
    required this.receipts,
  });

  final List<LedgerCustomer> customers;
  final List<Merchant> merchants;
  final List<AgentDesk> agents;
  final List<Txn> transactions;
  final List<ReceiptEntry> receipts;

  factory LedgerBook.fromJson(Map<String, dynamic> json) {
    return LedgerBook(
      customers: mapList(json['customers'], LedgerCustomer.fromJson),
      merchants: mapList(json['merchants'], Merchant.fromJson),
      agents: mapList(json['agents'], AgentDesk.fromJson),
      transactions: mapList(json['transactions'], Txn.fromJson),
      receipts: mapList(json['receipts'], ReceiptEntry.fromJson),
    );
  }
}

class AiCall {
  const AiCall({
    required this.id,
    required this.createdAt,
    required this.module,
    required this.operation,
    required this.provider,
    required this.model,
    required this.status,
    required this.promptChars,
    required this.latencyMs,
    required this.error,
  });

  final int id;
  final String createdAt;
  final String module;
  final String operation;
  final String provider;
  final String model;
  final String status;
  final int promptChars;
  final int latencyMs;
  final String error;

  factory AiCall.fromJson(Map<String, dynamic> json) {
    return AiCall(
      id: asInt(json['id']),
      createdAt: asString(json['created_at']),
      module: asString(json['module']),
      operation: asString(json['operation']),
      provider: asString(json['provider']),
      model: asString(json['model']),
      status: asString(json['status']),
      promptChars: asInt(json['prompt_chars']),
      latencyMs: asInt(json['latency_ms']),
      error: asString(json['error']),
    );
  }
}

class HealthInfo {
  const HealthInfo({
    required this.version,
    required this.aiMode,
    required this.aiLabel,
    required this.customers,
  });

  final String version;
  final String aiMode;
  final String aiLabel;
  final int customers;

  factory HealthInfo.fromJson(Map<String, dynamic> json) {
    return HealthInfo(
      version: asString(json['version']),
      aiMode: asString(json['ai_mode']),
      aiLabel: asString(json['ai_label']),
      customers: asInt(json['customers']),
    );
  }
}

class LoginResult {
  const LoginResult({
    required this.token,
    required this.tokenType,
    required this.expiresAt,
    required this.user,
  });

  final String token;
  final String tokenType;
  final String expiresAt;
  final UserAccount user;

  factory LoginResult.fromJson(Map<String, dynamic> json) {
    return LoginResult(
      token: asString(json['token']),
      tokenType: asString(json['token_type'], 'Bearer'),
      expiresAt: asString(json['expires_at']),
      user: UserAccount.fromJson(asMap(json['user'])),
    );
  }
}

class Me {
  const Me({required this.user, this.customer});

  final UserAccount user;
  final CustomerProfile? customer;

  factory Me.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'];
    return Me(
      user: UserAccount.fromJson(asMap(json['user'])),
      customer: customer == null
          ? null
          : CustomerProfile.fromJson(asMap(customer)),
    );
  }
}
