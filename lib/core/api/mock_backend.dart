import 'dart:typed_data';

import '../models/models.dart';
import '../money.dart';
import 'api_exception.dart';
import 'shamwari_api.dart';

/// In-memory book that follows the mobile contract, including error codes.
/// State lives for the process. A fresh launch reseeds the synthetic ledger.
class MockBackend implements ShamwariApi {
  MockBackend();

  /// Optional live token, used by the app. Tests can [attach] instead.
  String? Function()? tokenReader;

  String? _attached;
  final Map<String, String> _sessions = {};
  final Set<String> _revoked = {};
  final Map<String, _DemoProgress> _demo = {};
  final Map<String, AccessSettings> _access = {};
  final Map<String, List<CoachMessage>> _threads = {};
  final Map<String, List<String>?> _quizKeys = {};
  int _txnSeq = 40;
  int _receiptSeq = 1;
  int _messageSeq = 2;
  int _aiSeq = 4;
  int _pulseSeq = 58;

  final List<Txn> _txns = [];
  final List<ReceiptEntry> _receipts = [];
  final List<AiCall> _ai = [];
  final List<_Day> _days = [];
  final List<_PulseDay> _daily = [];
  final List<_ThemeCount> _themes = [];
  final List<_RegionCount> _regions = [];
  final List<PulseItem> _feed = [];
  int _publishCursor = 0;

  late final Map<String, _Pot> _pots;

  static const yesWords = ['yes', 'hongu', 'yebo', 'ewe', 'ehe'];
  static const pin = '2580';
  static const pinRule =
      'The demo PIN is checked only on the confirm endpoint. Do not send it to coach, scam, voice interpret, or onboarding.';

  void attach(String? token) => _attached = token;

  void adopt(String token, String username) {
    _sessions[token] = username;
    _attached = token;
  }

  String? get _token {
    final live = tokenReader?.call();
    if (live != null && live.isNotEmpty) return live;
    return _attached;
  }

  MockBackend.seeded() {
    _init();
  }

  bool _ready = false;

  void _init() {
    if (_ready) return;
    _ready = true;
    _pots = {'USD': _Pot(8600, 0), 'ZIG': _Pot(42000, 0)};
    _days.addAll([
      _Day('Tue', '2026-10-20', 400),
      _Day('Wed', '2026-10-21', 1000),
      _Day('Thu', '2026-10-22', 600),
      _Day('Fri', '2026-10-23', 500),
      _Day('Sat', '2026-10-24', 700),
      _Day('Sun', '2026-10-25', 400),
      _Day('Mon', '2026-10-26', 200),
    ]);
    _txns.addAll([
      _posted(
        id: 31,
        kind: 'merchant_pay',
        category: 'groceries',
        amount: 8000,
        currency: 'ZIG',
        merchantId: 2,
        counterparty: 'Mbare Fresh Produce',
        at: '2026-10-20T09:00:00Z',
      ),
      _posted(
        id: 28,
        kind: 'airtime',
        category: 'airtime',
        amount: 500,
        currency: 'USD',
        counterparty: 'Airtime',
        at: '2026-10-24T07:00:00Z',
        name: 'Airtime',
        initials: 'AI',
      ),
      _posted(
        id: 27,
        kind: 'transfer',
        category: 'family',
        amount: 1500,
        currency: 'USD',
        recipientId: 3,
        counterparty: 'Farai Ncube',
        at: '2026-10-22T16:10:00Z',
      ),
      _posted(
        id: 24,
        kind: 'transfer',
        category: 'transport',
        amount: 200,
        currency: 'USD',
        counterparty: 'Kombi rank',
        at: '2026-10-21T12:40:00Z',
        name: 'Transport',
        initials: 'TR',
      ),
      _posted(
        id: 21,
        kind: 'cash_in',
        category: 'cash_in',
        amount: 5000,
        currency: 'USD',
        counterparty: 'Copacabana booth',
        at: '2026-10-18T08:05:00Z',
        outgoing: false,
        name: 'Cash in',
        initials: 'CI',
      ),
    ]);
    _threads['rudo'] = [
      const CoachMessage(
        id: 1,
        role: 'assistant',
        content: 'Rudo, I am watching the tuckshop book with you. Ask about school fees, airtime, or this week.',
        createdAt: '2026-10-01T09:00:00Z',
      ),
    ];
    _daily.addAll([
      _PulseDay('2026-10-09', 4, 2),
      _PulseDay('2026-10-10', 4, 2),
      _PulseDay('2026-10-11', 4, 2),
      _PulseDay('2026-10-12', 5, 2),
      _PulseDay('2026-10-13', 5, 3),
      _PulseDay('2026-10-14', 5, 3),
      _PulseDay('2026-10-15', 5, 2),
      _PulseDay('2026-10-16', 4, 2),
      _PulseDay('2026-10-17', 4, 2),
      _PulseDay('2026-10-18', 4, 2),
      _PulseDay('2026-10-19', 5, 2),
      _PulseDay('2026-10-20', 4, 2),
      _PulseDay('2026-10-21', 4, 3),
      _PulseDay('2026-10-22', 4, 3),
      _PulseDay('2026-10-23', 2, 0),
      _PulseDay('2026-10-24', 1, 0),
      _PulseDay('2026-10-25', 1, 0),
      _PulseDay('2026-10-26', 1, 0),
    ]);
    _themes.addAll([
      _ThemeCount('Praise', 12),
      _ThemeCount('Fees', 11),
      _ThemeCount('Agent liquidity', 11),
      _ThemeCount('App stability', 11),
      _ThemeCount('ZiG conversion', 8),
      _ThemeCount('Reversal scam', 8),
      _ThemeCount('Failed transfer', 5),
    ]);
    _regions.addAll([
      _RegionCount('Harare', 10, 6, 3),
      _RegionCount('Bulawayo', 8, 5, 4),
      _RegionCount('Mutare', 6, 4, 2),
      _RegionCount('Gweru', 4, 3, 2),
      _RegionCount('Chitungwiza', 4, 3, 2),
    ]);
    _feed.addAll([
      _feedItem(
        58,
        'ticket',
        'Harare: a reversal SMS asked a customer for a PIN. This looks like a scam.',
        'reversal_scam',
        'Reversal scam',
        'negative',
        'Harare',
        '2026-10-26T06:00:00Z',
      ),
      _feedItem(
        57,
        'post',
        'Praise for the Copacabana booth queue this morning.',
        'praise',
        'Praise',
        'positive',
        'Harare',
        '2026-10-25T15:10:00Z',
      ),
      _feedItem(
        56,
        'review',
        'Bulawayo customers are asking why ZiG airtime shows a different figure.',
        'zig_conversion',
        'ZiG conversion',
        'neutral',
        'Bulawayo',
        '2026-10-25T11:00:00Z',
      ),
      _feedItem(
        55,
        'ticket',
        'Mutare: the app closed on the confirm step. No money moved.',
        'app_stability',
        'App stability',
        'negative',
        'Mutare',
        '2026-10-24T09:40:00Z',
      ),
      _feedItem(
        54,
        'ticket',
        'Gweru agent float is thin before lunch.',
        'agent_liquidity',
        'Agent liquidity',
        'negative',
        'Gweru',
        '2026-10-23T10:15:00Z',
      ),
      _feedItem(
        53,
        'review',
        'Chitungwiza parents are asking about school-fee reminders.',
        'fees',
        'Fees',
        'neutral',
        'Chitungwiza',
        '2026-10-22T08:20:00Z',
      ),
    ]);
    _ai.add(
      const AiCall(
        id: 4,
        createdAt: '2026-10-26T06:50:00Z',
        module: 'coach',
        operation: 'reply',
        provider: 'mock',
        model: 'mock',
        status: 'ok',
        promptChars: 420,
        latencyMs: 1,
        error: '',
      ),
    );
  }

  String? _username() {
    _init();
    final token = _token;
    if (token == null ||
        token.isEmpty ||
        _revoked.contains(token) ||
        !_sessions.containsKey(token)) {
      throw ApiException(
        code: 'unauthorized',
        message: 'Sign in again.',
        status: 401,
      );
    }
    return _sessions[token];
  }

  UserAccount _user() {
    final name = _username();
    return _account(name!);
  }

  void _customer() {
    final user = _user();
    if (!user.isCustomer) {
      throw ApiException(
        code: 'forbidden',
        message: 'This desk is the customer side.',
        status: 403,
      );
    }
  }

  void _staff() {
    final user = _user();
    if (!user.isStaff) {
      throw ApiException(
        code: 'forbidden',
        message: 'This desk is for the care team.',
        status: 403,
      );
    }
  }

  UserAccount _account(String username) {
    if (username == 'care') {
      return const UserAccount(
        id: 2,
        username: 'care',
        role: 'staff',
        displayName: 'Care desk',
        customerId: null,
      );
    }
    return const UserAccount(
      id: 1,
      username: 'rudo',
      role: 'customer',
      displayName: 'Rudo Moyo',
      customerId: 1,
    );
  }

  CustomerProfile _rudo() {
    return const CustomerProfile(
      id: 1,
      fullName: 'Rudo Moyo',
      shortName: 'Rudo Moyo',
      city: 'Harare',
      language: 'en',
      role: 'Tuckshop owner',
      phoneMasked: '0771••••01',
    );
  }

  @override
  Future<HealthInfo> health() async {
    _init();
    return const HealthInfo(
      version: 'v1',
      aiMode: 'mock',
      aiLabel: 'Mock',
      customers: 8,
    );
  }

  @override
  Future<LoginResult> login(String username, String password) async {
    _init();
    if (username.trim().isEmpty || password.isEmpty) {
      throw ApiException(
        code: 'validation',
        message: 'Enter a username and a password.',
        status: 400,
      );
    }
    final ok =
        (username == 'rudo' && password == 'rudo-demo') ||
        (username == 'care' && password == 'care-demo');
    if (!ok) {
      throw ApiException(
        code: 'unauthorized',
        message: 'Those details do not match a demo desk.',
        status: 401,
      );
    }
    final token = 'mock.$username.${DateTime.now().microsecondsSinceEpoch}';
    _sessions[token] = username;
    _attached = token;
    final expires = DateTime.now().toUtc().add(const Duration(days: 14));
    return LoginResult(
      token: token,
      tokenType: 'Bearer',
      expiresAt: _iso(expires),
      user: _account(username),
    );
  }

  @override
  Future<void> logout() async {
    final token = _token;
    _username();
    if (token != null) _revoked.add(token);
    _attached = null;
  }

  @override
  Future<Me> me() async {
    final user = _user();
    return Me(user: user, customer: user.isCustomer ? _rudo() : null);
  }

  @override
  Future<List<Merchant>> merchants() async {
    _user();
    return _merchants();
  }

  @override
  Future<List<SearchHit>> search(String query) async {
    final user = _user();
    final catalog = user.isStaff ? _staffSearch : _customerSearch;
    final q = query.trim().toLowerCase();
    final hits = catalog
        .where((hit) {
          if (q.isEmpty) return true;
          return hit.label.toLowerCase().contains(q) ||
              hit.group.toLowerCase().contains(q) ||
              hit.hint.toLowerCase().contains(q);
        })
        .take(12);
    return hits.toList();
  }

  DemoScript _scriptFor(String username, _DemoProgress? progress) {
    final steps = _steps;
    if (progress == null || !progress.started) {
      return DemoScript(
        active: false,
        done: progress?.done ?? false,
        index: null,
        total: steps.length,
        current: null,
        demoPin: pin,
        yesWords: yesWords,
        pinRule: pinRule,
        steps: steps,
      );
    }
    if (progress.done ||
        progress.index == null ||
        progress.index! >= steps.length) {
      return DemoScript(
        active: false,
        done: true,
        index: null,
        total: steps.length,
        current: null,
        demoPin: pin,
        yesWords: yesWords,
        pinRule: pinRule,
        steps: steps,
      );
    }
    return DemoScript(
      active: true,
      done: false,
      index: progress.index,
      total: steps.length,
      current: steps[progress.index!],
      demoPin: pin,
      yesWords: yesWords,
      pinRule: pinRule,
      steps: steps,
    );
  }

  /// Progress lives on the bearer token, matching the contract's preference row.
  String _demoKey() {
    _username();
    return _token!;
  }

  @override
  Future<DemoScript> demo() async {
    final key = _demoKey();
    return _scriptFor(_sessions[key]!, _demo[key]);
  }

  @override
  Future<DemoScript> demoStart() async {
    final key = _demoKey();
    _demo[key] = _DemoProgress(started: true, index: 0);
    return _scriptFor(_sessions[key]!, _demo[key]);
  }

  @override
  Future<DemoScript> demoNext() async {
    final key = _demoKey();
    final progress = _demo[key];
    if (progress == null || !progress.started || progress.index == null) {
      throw ApiException(
        code: 'validation',
        message: 'Start the demo first.',
        status: 400,
      );
    }
    final next = progress.index! + 1;
    if (next >= _steps.length) {
      _demo[key] = _DemoProgress(started: false, done: true);
    } else {
      _demo[key] = _DemoProgress(started: true, index: next);
    }
    return _scriptFor(_sessions[key]!, _demo[key]);
  }

  @override
  Future<DemoScript> demoBack() async {
    final key = _demoKey();
    final progress = _demo[key];
    if (progress == null || !progress.started || progress.index == null) {
      _demo[key] = _DemoProgress(started: true, index: 0);
    } else {
      final back = progress.index! <= 0 ? 0 : progress.index! - 1;
      _demo[key] = _DemoProgress(started: true, index: back);
    }
    return _scriptFor(_sessions[key]!, _demo[key]);
  }

  @override
  Future<DemoScript> demoStop() async {
    final key = _demoKey();
    _demo[key] = _DemoProgress(started: false);
    return _scriptFor(_sessions[key]!, _demo[key]);
  }

  @override
  Future<WalletSnapshot> wallet() async {
    _customer();
    return _wallet();
  }

  WalletSnapshot _wallet() {
    final peak = _days
        .map((day) => day.amountCents)
        .fold<int>(0, (a, b) => a > b ? a : b);
    final days = _days
        .map(
          (day) => SpendDay(
            label: day.label,
            date: day.date,
            amountCents: day.amountCents,
            display: formatCents(day.amountCents, 'USD'),
            peak: day.amountCents == peak && peak > 0,
          ),
        )
        .toList();
    final total = _days.fold<int>(0, (sum, day) => sum + day.amountCents);
    return WalletSnapshot(
      customer: _rudo(),
      wallets: [_walletModel('USD'), _walletModel('ZIG')],
      goal: const SavingsGoal(
        name: 'Term 2 school fees',
        currency: 'USD',
        savedCents: 4500,
        targetCents: 15000,
        displaySaved: 'US\$ 45.00',
        displayTarget: 'US\$ 150.00',
        dueDate: '2026-12-01',
        expectedCents: 9065,
        onTrack: false,
        remainingDays: 36,
        weeklyCents: 2041,
      ),
      week: WeekSpend(
        totalCents: total,
        display: formatCents(total, 'USD'),
        deltaPct: 23,
        days: days,
      ),
      pendingCount: _txns
          .where((txn) => txn.status == 'pending' && txn.senderId == 1)
          .length,
    );
  }

  Wallet _walletModel(String currency) {
    final pot = _pots[currency]!;
    final available = pot.balance - pot.pending;
    return Wallet(
      currency: currency,
      balanceCents: pot.balance,
      pendingCents: pot.pending,
      availableCents: available,
      displayBalance: formatCents(pot.balance, currency),
      displayAvailable: formatCents(available, currency),
    );
  }

  @override
  Future<List<Txn>> transactions({int limit = 20}) async {
    _customer();
    final cap = limit.clamp(1, 50);
    return _txns.take(cap).toList();
  }

  @override
  Future<List<Txn>> activity() async {
    _customer();
    return _txns.take(8).map(_asActivity).toList();
  }

  @override
  Future<List<Contact>> contacts() async {
    _customer();
    return _contacts;
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
    _customer();
    return _create(
      amountCents: amountCents,
      currency: currency,
      kind: kind,
      recipientName: recipientName,
      recipientId: recipientId,
      merchantName: merchantName,
      merchantId: merchantId,
      note: 'Created pending by the mobile API. Synthetic.',
    );
  }

  TransferResult _create({
    required int amountCents,
    required String currency,
    required String kind,
    String? recipientName,
    int? recipientId,
    String? merchantName,
    int? merchantId,
    required String note,
  }) {
    final normalized = _kind(kind);
    final cur = currency.toUpperCase() == 'ZIG'
        ? 'ZIG'
        : (currency.toUpperCase() == 'USD' ? 'USD' : '');
    if (cur.isEmpty) {
      throw ApiException(
        code: 'validation',
        message: 'Currency must be USD or ZiG.',
        status: 400,
      );
    }
    if (amountCents <= 0) {
      throw ApiException(
        code: 'validation',
        message: 'Send amount_cents.',
        status: 400,
      );
    }
    final cap = switch (normalized) {
      'airtime' => 10000,
      'merchant_pay' => 200000,
      _ => 1000000,
    };
    if (amountCents > cap) {
      throw ApiException(
        code: 'validation',
        message: 'That amount is above the demo cap.',
        status: 400,
      );
    }
    final pot = _pots[cur]!;
    if (pot.balance - pot.pending < amountCents) {
      throw ApiException(
        code: 'validation',
        message: 'Available balance does not cover the hold.',
        status: 400,
      );
    }
    int? resolvedRecipient;
    int? resolvedMerchant;
    String counterparty;
    String category;
    if (normalized == 'transfer') {
      final contact = _matchContact(recipientName, recipientId);
      if (contact == null) {
        throw ApiException(
          code: 'validation',
          message: 'That contact is not on Rudo\'s list.',
          status: 400,
        );
      }
      resolvedRecipient = contact.customerId;
      counterparty = contact.name;
      category = 'family';
    } else if (normalized == 'merchant_pay') {
      final merchant = _matchMerchant(merchantName, merchantId);
      if (merchant == null) {
        throw ApiException(
          code: 'validation',
          message: 'That merchant is not in the synthetic book.',
          status: 400,
        );
      }
      resolvedMerchant = merchant.id;
      counterparty = merchant.name;
      category = merchant.category.toLowerCase();
    } else {
      counterparty = 'Airtime';
      category = 'airtime';
    }
    pot.pending += amountCents;
    final id = _txnSeq++;
    final txn = Txn(
      id: id,
      reference: 'SM-${100000 + id}',
      kind: normalized,
      category: category,
      status: 'pending',
      amountCents: amountCents,
      currency: cur,
      display: formatCents(amountCents, cur),
      senderId: 1,
      recipientId: resolvedRecipient,
      merchantId: resolvedMerchant,
      counterparty: counterparty,
      note: note,
      outgoing: true,
      createdAt: _iso(DateTime.now().toUtc()),
      postedAt: null,
    );
    _txns.insert(0, txn);
    return TransferResult(outcome: 'pending', transaction: txn, message: note);
  }

  @override
  Future<Txn> transfer(int id) async {
    _customer();
    final txn = _findTxn(id);
    if (txn == null) {
      throw ApiException(
        code: 'not_found',
        message: 'That transfer is not in this book.',
        status: 404,
      );
    }
    return txn;
  }

  @override
  Future<ConfirmResult> confirmTransfer(
    int id, {
    required String confirmWord,
    required String pin,
  }) {
    _customer();
    return Future.value(_confirm(id, confirmWord, pin));
  }

  @override
  Future<Txn> cancelTransfer(int id) async {
    _customer();
    final index = _txns.indexWhere((txn) => txn.id == id);
    if (index < 0) {
      throw ApiException(
        code: 'not_found',
        message: 'That transfer is not in this book.',
        status: 404,
      );
    }
    final txn = _txns[index];
    if (txn.status != 'pending' || txn.senderId != 1) {
      throw ApiException(
        code: 'not_pending',
        message: 'Only a pending transfer you created can be cancelled.',
        status: 409,
      );
    }
    _pots[txn.currency]!.pending -= txn.amountCents;
    final cancelled = _copy(txn, status: 'cancelled');
    _txns[index] = cancelled;
    return cancelled;
  }

  ConfirmResult _confirm(int id, String confirmWord, String pinValue) {
    final index = _txns.indexWhere((txn) => txn.id == id);
    if (index < 0) {
      throw ApiException(
        code: 'not_found',
        message: 'That transfer is not in this book.',
        status: 404,
      );
    }
    final txn = _txns[index];
    if (txn.senderId != 1) {
      throw ApiException(
        code: 'forbidden',
        message: 'That transfer belongs to someone else.',
        status: 403,
      );
    }
    if (txn.status == 'posted') {
      return ConfirmResult(
        outcome: 'already',
        pinCheckedLocally: true,
        pinSentToModel: false,
        transaction: txn,
      );
    }
    if (txn.status != 'pending') {
      throw ApiException(
        code: 'not_pending',
        message: 'That row is not pending.',
        status: 409,
        details: {
          'transaction': {'id': txn.id, 'status': txn.status},
        },
      );
    }
    final word = confirmWord.trim().toLowerCase();
    if (!yesWords.contains(word)) {
      throw ApiException(
        code: 'need_yes',
        message: 'Confirm with a yes word. The transfer is still pending.',
        status: 400,
        details: {
          'outcome': 'need_yes',
          'pin_checked_locally': false,
          'pin_sent_to_model': false,
          'transaction': {'id': txn.id, 'status': 'pending'},
        },
      );
    }
    if (pinValue != pin) {
      throw ApiException(
        code: 'bad_pin',
        message: 'That PIN does not match the synthetic demo PIN. Nothing was posted.',
        status: 400,
        details: {
          'outcome': 'bad_pin',
          'pin_checked_locally': true,
          'pin_sent_to_model': false,
          'transaction': {'id': txn.id, 'status': 'pending'},
        },
      );
    }
    final pot = _pots[txn.currency]!;
    if (pot.balance < txn.amountCents) {
      throw ApiException(
        code: 'insufficient',
        message: 'The wallet no longer covers that hold.',
        status: 400,
        details: {
          'transaction': {'id': txn.id, 'status': 'pending'},
        },
      );
    }
    pot.balance -= txn.amountCents;
    pot.pending -= txn.amountCents;
    if (txn.currency == 'USD') _addSpend(txn.amountCents);
    final posted = _copy(
      txn,
      status: 'posted',
      postedAt: _iso(DateTime.now().toUtc()),
    );
    _txns[index] = posted;
    return ConfirmResult(
      outcome: 'posted',
      pinCheckedLocally: true,
      pinSentToModel: false,
      transaction: posted,
    );
  }

  void _addSpend(int cents) {
    final today = _date(DateTime.now());
    final existing = _days.where((day) => day.date == today);
    if (existing.isEmpty) {
      _days.add(_Day(_weekday(DateTime.now()), today, cents));
    } else {
      existing.first.amountCents += cents;
    }
  }

  @override
  Future<VoiceCatalog> voicePhrases() async {
    _customer();
    return VoiceCatalog(
      demoPin: pin,
      yesWords: yesWords,
      pinRule: pinRule,
      phrases: _phrases,
    );
  }

  @override
  Future<VoiceInterpretation> interpretText(String text) async {
    _customer();
    final trimmed = text.trim();
    if (trimmed.isEmpty || trimmed.length > 400) {
      throw ApiException(
        code: 'validation',
        message: 'Enter a phrase under 400 characters.',
        status: 400,
      );
    }
    _logAi('voice', 'interpret', trimmed.length);
    return VoiceInterpretation(
      transcript: trimmed,
      transcriptNote: '',
      balances: [_walletModel('USD'), _walletModel('ZIG')],
      plan: _plan(trimmed),
    );
  }

  @override
  Future<VoiceInterpretation> interpretAudio(
    Uint8List bytes,
    String filename, {
    String? language,
  }) async {
    _customer();
    _logAi(
      'voice',
      'interpret',
      bytes.length,
      status: 'error',
      error: 'transcript_empty',
    );
    throw ApiException(
      code: 'transcript_empty',
      message: 'Offline mock cannot hear audio. Use a demo phrase, or a browser with speech recognition.',
      status: 400,
    );
  }

  @override
  Future<TransferResult> prepareVoice(Map<String, dynamic> plan) async {
    _customer();
    final parsed = VoicePlan.fromJson(plan);
    if (parsed.missing.isNotEmpty) {
      throw ApiException(
        code: 'validation',
        message: 'The plan is still missing ${parsed.missing.join(', ')}.',
        status: 400,
      );
    }
    final kind = switch (parsed.intent) {
      'send_money' => 'transfer',
      'buy_airtime' => 'airtime',
      'pay_merchant' => 'merchant_pay',
      _ => '',
    };
    if (kind.isEmpty) {
      throw ApiException(
        code: 'validation',
        message: 'That intent cannot be prepared.',
        status: 400,
      );
    }
    final created = _create(
      amountCents: parsed.amountCents ?? 0,
      currency: parsed.currency,
      kind: kind,
      recipientName: parsed.recipientName,
      recipientId: parsed.recipientId,
      merchantName: parsed.merchantName,
      merchantId: parsed.merchantId,
      note: 'Prepared as pending. Nothing has been posted. Confirm with a yes word and the PIN.',
    );
    return TransferResult(
      outcome: created.outcome,
      transaction: created.transaction,
      message: 'Prepared as pending. Nothing has been posted. Confirm with a yes word and the PIN.',
    );
  }

  @override
  Future<ConfirmResult> confirmVoice({
    required int txnId,
    required String confirmWord,
    required String pin,
  }) async {
    _customer();
    return _confirm(txnId, confirmWord, pin);
  }

  @override
  Future<CoachState> coach() async {
    _customer();
    return _coachState();
  }

  CoachState _coachState() {
    final wallet = _wallet();
    return CoachState(
      suggestions: const [
        'Can I still make my school fees goal?',
        'Where is my airtime money going?',
        'What should I worry about this week?',
        'What is my balance?',
      ],
      warnings: const [
        'Airtime is 33% of USD spending in this ledger. It is the largest outflow.',
        'Transport is 21% of spending. Together with airtime, small taps are the leak.',
        'The savings mark for “Term 2 school fees” is behind a straight-line pace. About US\$ 91 would have been marked by today. US\$ 45 is marked.',
      ],
      categories: const [
        SpendCategory(
          key: 'airtime',
          label: 'Airtime',
          amountCents: 4800,
          display: 'US\$ 48.00',
          share: 0.3333,
        ),
        SpendCategory(
          key: 'transport',
          label: 'Transport',
          amountCents: 3000,
          display: 'US\$ 30.00',
          share: 0.2083,
        ),
        SpendCategory(
          key: 'groceries',
          label: 'Groceries',
          amountCents: 2600,
          display: 'US\$ 26.00',
          share: 0.1806,
        ),
        SpendCategory(
          key: 'family',
          label: 'Family',
          amountCents: 2200,
          display: 'US\$ 22.00',
          share: 0.1528,
        ),
        SpendCategory(
          key: 'other',
          label: 'Other',
          amountCents: 1800,
          display: 'US\$ 18.00',
          share: 0.125,
        ),
      ],
      goal: wallet.goal,
      messages: List<CoachMessage>.from(_threads['rudo'] ?? const []),
    );
  }

  @override
  Future<CoachReply> coachSend(String text) async {
    _customer();
    final trimmed = text.trim();
    if (trimmed.isEmpty || trimmed.length > 2000) {
      throw ApiException(
        code: 'validation',
        message: 'Enter a note under 2000 characters.',
        status: 400,
      );
    }
    final scrubbed = scrubSecrets(trimmed);
    final note = scrubbed == trimmed
        ? ''
        : 'A secret was scrubbed before this was saved.';
    final thread = _threads.putIfAbsent('rudo', () => []);
    final now = _iso(DateTime.now().toUtc());
    thread.add(
      CoachMessage(
        id: _messageSeq++,
        role: 'user',
        content: scrubbed,
        createdAt: now,
      ),
    );
    final reply = CoachMessage(
      id: _messageSeq++,
      role: 'assistant',
      content: _coachNarration(scrubbed),
      createdAt: now,
    );
    thread.add(reply);
    _logAi('coach', 'reply', scrubbed.length);
    return CoachReply(
      reply: reply,
      note: note,
      messages: List<CoachMessage>.from(thread),
    );
  }

  String _coachNarration(String text) {
    final lower = text.toLowerCase();
    final usd = _walletModel('USD');
    final zig = _walletModel('ZIG');
    if (lower.contains('school') ||
        lower.contains('goal') ||
        lower.contains('fees')) {
      return 'Rudo, the “Term 2 school fees” mark is US\$ 45 of US\$ 150, due 2026-12-01. That is behind the straight-line pace. A steady catch-up is about US\$ 20 a week. The mark is a note on this demo, not a separate wallet, and nothing moves until you add to it.';
    }
    if (lower.contains('airtime')) {
      return 'Airtime is US\$ 48.00, about 33% of the USD spend in this book. It is the largest outflow. Transport sits next to it. Small taps are the leak, and nothing moves until you confirm a payment yourself.';
    }
    if (lower.contains('balance') || lower.contains('mari')) {
      return 'Available ${usd.displayAvailable} and ${zig.displayAvailable}. Pending holds are already taken off the available figure. Posted balances move only after a yes word and the PIN.';
    }
    if (lower.contains('week') || lower.contains('worry')) {
      return 'This week the book shows ${_wallet().week.display} of USD spend. Airtime and transport are the two leaks. The school-fees mark is behind. I can only phrase the figures — the cents were counted here, not by a model.';
    }
    return 'I stayed inside the synthetic book. Available ${usd.displayAvailable}. The school-fees mark is US\$ 45 of US\$ 150 and behind pace. Say which one you want to look at.';
  }

  @override
  Future<List<ScamSample>> scamSamples() async {
    _customer();
    return _scamSamples;
  }

  @override
  Future<ScamReport> scamCheck({String? sample, String? text}) async {
    _customer();
    final sampleId = sample?.trim();
    if ((sampleId == null || sampleId.isEmpty) &&
        (text == null || text.trim().isEmpty)) {
      throw ApiException(
        code: 'validation',
        message: 'Paste a message or choose a sample.',
        status: 400,
      );
    }
    if (text != null && text.length > 2000) {
      throw ApiException(
        code: 'validation',
        message: 'That message is over 2000 characters.',
        status: 400,
      );
    }
    String body = text?.trim() ?? '';
    if (sampleId != null && sampleId.isNotEmpty) {
      final known = _scamSamples.where((item) => item.id == sampleId);
      if (known.isEmpty) {
        throw ApiException(
          code: 'not_found',
          message: 'That sample is not on the list.',
          status: 404,
        );
      }
      body = known.first.text;
    }
    _logAi('scam', 'check', body.length);
    return _scamReport(body, sampleId: sampleId);
  }

  ScamReport _scamReport(String body, {String? sampleId}) {
    final patterns = <String>[];
    final lower = body.toLowerCase();
    if (sampleId == 'reversal' || lower.contains('reversal')) {
      patterns.add('Reversal pretext');
    }
    if (sampleId == 'prize' ||
        lower.contains('won') ||
        lower.contains('congratulations')) {
      patterns.add('Prize bait');
    }
    if (lower.contains('pin') ||
        lower.contains('otp') ||
        lower.contains('password')) {
      patterns.add('Asks for a PIN, OTP, or password');
    }
    if ((sampleId == 'agent' || lower.contains('agent')) &&
        (lower.contains('pin') ||
            lower.contains('reversal') ||
            sampleId == 'agent')) {
      patterns.add('Someone claims to be an agent');
    }
    if (sampleId == 'pressure' ||
        lower.contains('suspend') ||
        lower.contains('within')) {
      patterns.add('Time pressure');
    }
    String rules;
    if (sampleId == 'family') {
      patterns.clear();
      rules = 'looks_safe';
    } else if (sampleId == 'pressure') {
      rules = 'suspicious';
    } else if (sampleId == 'reversal' ||
        sampleId == 'prize' ||
        sampleId == 'agent') {
      rules = 'likely_scam';
    } else if (patterns.contains('Asks for a PIN, OTP, or password') ||
        patterns.contains('Prize bait')) {
      rules = 'likely_scam';
    } else if (patterns.contains('Reversal pretext') && patterns.length > 1) {
      rules = 'likely_scam';
    } else if (patterns.isNotEmpty) {
      rules = 'suspicious';
    } else {
      rules = 'looks_safe';
    }
    final steps = switch (rules) {
      'likely_scam' => [
        'The local pattern list marks this as a likely scam.',
        'Do not reply, and do not read a PIN aloud.',
        'The final verdict is never softer than the rules.',
      ],
      'suspicious' => [
        'The wording uses pressure, and it has not asked for a PIN yet.',
        'Stop if the next line asks for a PIN, OTP, or password.',
        'This is a pattern check, not a guarantee.',
      ],
      _ => [
        'No known scam pattern matched this wording.',
        'This is a pattern check on a short local list, not a guarantee.',
        'If the conversation later asks for a PIN, stop. That part is never safe.',
      ],
    };
    return ScamReport(
      verdict: rules,
      label: _verdictLabel(rules),
      rulesVerdict: rules,
      rulesLabel: _verdictLabel(rules),
      aiVerdict: rules,
      aiConfidence: rules == 'looks_safe' ? 0.86 : 0.93,
      source: 'rules',
      patterns: patterns,
      steps: steps,
      note: '',
      errorDetail: '',
    );
  }

  @override
  Future<ReceiptBook> receipts() async {
    _customer();
    return ReceiptBook(
      merchant: _merchants().first,
      entries: List<ReceiptEntry>.from(_receipts),
    );
  }

  @override
  Future<List<ReceiptSample>> receiptSamples() async {
    _customer();
    return _receiptSamples;
  }

  @override
  Future<ReceiptImage> receiptSampleImage(String filename) async {
    _customer();
    if (_receiptSamples.every((sample) => sample.filename != filename)) {
      throw ApiException(
        code: 'not_found',
        message: 'That sample slip is not on the list.',
        status: 404,
      );
    }
    return ReceiptImage(
      filename: filename,
      mediaType: 'image/png',
      base64: _png,
    );
  }

  @override
  Future<ReceiptExtraction> readReceiptSample(String sample) async {
    _customer();
    final known = _receiptSamples.where((item) => item.filename == sample);
    if (known.isEmpty) {
      throw ApiException(
        code: 'not_found',
        message: 'That sample slip is not on the list.',
        status: 404,
      );
    }
    _logAi('receipts', 'read', sample.length);
    return _extractionFor(known.first);
  }

  @override
  Future<ReceiptExtraction> readReceiptImage(
    Uint8List bytes,
    String filename,
  ) async {
    _customer();
    if (bytes.isEmpty) {
      throw ApiException(
        code: 'validation',
        message: 'Choose an image.',
        status: 400,
      );
    }
    final isPng = bytes.length >= 4 && bytes[0] == 0x89 && bytes[1] == 0x50;
    final isJpeg = bytes.length >= 3 && bytes[0] == 0xFF && bytes[1] == 0xD8;
    if (!isPng && !isJpeg) {
      throw ApiException(
        code: 'validation',
        message: 'Send a PNG or JPEG till slip.',
        status: 400,
      );
    }
    _logAi('receipts', 'read', bytes.length);
    return const ReceiptExtraction(
      vendor: '',
      date: '',
      currency: 'USD',
      totalCents: 0,
      display: '',
      items: [],
      note: 'Mock mode could not read this photo. Fill the slip in by hand.',
      source: 'manual',
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
    _customer();
    if (vendor.trim().isEmpty || totalCents <= 0) {
      throw ApiException(
        code: 'validation',
        message: 'A slip needs a vendor and a positive total.',
        status: 400,
      );
    }
    final cur = currency.toUpperCase() == 'ZIG' ? 'ZIG' : 'USD';
    final entry = ReceiptEntry(
      id: _receiptSeq++,
      merchantId: 1,
      merchant: "Rudo's Tuckshop",
      vendor: vendor.trim(),
      receiptDate: receiptDate,
      totalCents: totalCents,
      currency: cur,
      display: formatCents(totalCents, cur),
      items: items,
      notes: notes,
      sourceName: 'mobile api',
      createdAt: _iso(DateTime.now().toUtc()),
    );
    _receipts.insert(0, entry);
    return entry;
  }

  @override
  Future<ReceiptExport> exportReceipts() async {
    _customer();
    final lines = <String>['vendor,receipt_date,currency,total,items,notes'];
    for (final entry in _receipts) {
      final items = entry.items
          .map(
            (item) =>
                '${item.description} ${formatCents(item.amountCents, entry.currency)}',
          )
          .join('; ');
      lines.add(
        '${entry.vendor},${entry.receiptDate},${entry.currency},${(entry.totalCents / 100).toStringAsFixed(2)},"$items",${entry.notes}',
      );
    }
    return ReceiptExport(
      filename: 'rudo-tuckshop-ledger.csv',
      mediaType: 'text/csv',
      csv: lines.join('\n'),
    );
  }

  @override
  Future<AccessState> accessibility() async {
    _customer();
    final settings =
        _access['rudo'] ??
        const AccessSettings(
          largeType: false,
          highContrast: false,
          speakBalances: true,
        );
    return AccessState(
      settings: settings,
      spoken: settings.speakBalances ? _spoken() : '',
      balances: [_walletModel('USD'), _walletModel('ZIG')],
      qrSamples: const [
        QrSample(
          filename: 'qr-till.png',
          title: 'Till slip QR',
          payload: 'SYNTHETIC TILL SLIP\nVendor: Mbare Fresh Produce\nDate: 20 Oct 2026\nTomatoes 2kg USD 4.00\nOnions 1kg USD 1.50\nTotal USD 5.50',
        ),
        QrSample(
          filename: 'qr-pay.png',
          title: 'Merchant pay QR',
          payload: 'SHAMWARI-PAY\nmerchant=Mbare Fresh Produce\namount=5.50\ncurrency=USD',
        ),
      ],
    );
  }

  String _spoken() {
    final usd = _walletModel('USD');
    final balance = (usd.balanceCents / 100).toStringAsFixed(2);
    final available = (usd.availableCents / 100).toStringAsFixed(2);
    final pending = (usd.pendingCents / 100).toStringAsFixed(2);
    return 'You are acting as Rudo Moyo in Harare. Available US dollars: $available. Posted balance $balance. Pending hold $pending.';
  }

  @override
  Future<AccessSettings> updateAccessibility({
    bool? largeType,
    bool? highContrast,
    bool? speakBalances,
  }) async {
    _customer();
    for (final value in [largeType, highContrast, speakBalances]) {
      if (value != null && value != true && value != false) {
        throw ApiException(
          code: 'validation',
          message: 'Settings must be true or false.',
          status: 400,
        );
      }
    }
    final current =
        _access['rudo'] ??
        const AccessSettings(
          largeType: false,
          highContrast: false,
          speakBalances: true,
        );
    final next = AccessSettings(
      largeType: largeType ?? current.largeType,
      highContrast: highContrast ?? current.highContrast,
      speakBalances: speakBalances ?? current.speakBalances,
    );
    _access['rudo'] = next;
    return next;
  }

  @override
  Future<PulseSnapshot> pulse() async {
    _staff();
    return _pulse();
  }

  PulseSnapshot _pulse() {
    return PulseSnapshot(
      points: _points(),
      complaints: [
        PulseComplaint(
          theme: 'reversal_scam',
          label: 'Reversal scam',
          region: 'Harare',
          count: _themes
              .firstWhere((theme) => theme.label == 'Reversal scam')
              .count,
          sample: 'Harare: a reversal SMS asked a customer for a PIN. This looks like a scam.',
        ),
      ],
      series: _series(),
      feed: List<PulseItem>.from(_feed.take(12)),
    );
  }

  PulseSeries _series() {
    return PulseSeries(
      daily: _daily
          .map(
            (day) => PulseDaily(
              date: day.date,
              total: day.total,
              negative: day.negative,
            ),
          )
          .toList(),
      themes: _themes
          .map((theme) => PulseTheme(label: theme.label, count: theme.count))
          .toList(),
      regions: _regions
          .map(
            (region) => PulseRegion(
              region: region.region,
              negative: region.negative,
              neutral: region.neutral,
              positive: region.positive,
            ),
          )
          .toList(),
    );
  }

  List<String> _points() {
    final total = _daily.fold<int>(0, (sum, day) => sum + day.total);
    final negative = _daily.fold<int>(0, (sum, day) => sum + day.negative);
    final pct = total == 0 ? 0 : (negative * 100 / total).round();
    final loudest = _themes.reduce((a, b) => a.count >= b.count ? a : b);
    final top = _regions.reduce((a, b) => a.volume >= b.volume ? a : b);
    final reversal = _themes.firstWhere(
      (theme) => theme.label == 'Reversal scam',
    );
    return [
      '$pct% of $total published messages are negative.',
      'The loudest theme is ${loudest.label} with ${loudest.count} messages.',
      '${top.region} has the most volume, with ${top.volume} messages.',
      'Reversal-scam mentions in the book: ${reversal.count}. The pattern list still answers if a model refuses the text.',
    ];
  }

  @override
  Future<PulsePublish> publishPulse() async {
    _staff();
    const script = [
      'Harare customers are quoting a reversal SMS and a PIN request at Copacabana.',
      'Bulawayo: praise for a short queue at City Hall booth.',
      'Mutare: a failed transfer was retried and the second attempt stayed pending until yes.',
      'Gweru: an agent asked for a top-up of float before the afternoon rush.',
    ];
    final text = script[_publishCursor % script.length];
    _publishCursor += 1;
    final negative =
        text.toLowerCase().contains('pin') ||
        text.toLowerCase().contains('failed');
    final item = _feedItem(
      ++_pulseSeq,
      'ticket',
      text,
      negative ? 'reversal_scam' : 'praise',
      negative ? 'Reversal scam' : 'Praise',
      negative ? 'negative' : 'positive',
      text.startsWith('Bulawayo')
          ? 'Bulawayo'
          : text.startsWith('Mutare')
          ? 'Mutare'
          : text.startsWith('Gweru')
          ? 'Gweru'
          : 'Harare',
      _iso(DateTime.now().toUtc()),
    );
    _feed.insert(0, item);
    final today = _date(DateTime.now());
    final slot = _daily.where((day) => day.date == today);
    if (slot.isEmpty) {
      _daily.add(_PulseDay(today, 1, negative ? 1 : 0));
    } else {
      slot.first.total += 1;
      if (negative) slot.first.negative += 1;
    }
    final theme = _themes.firstWhere(
      (row) => row.label == item.themeLabel,
      orElse: () => _themes.first,
    );
    theme.count += 1;
    _logAi('pulse', 'publish', text.length);
    return PulsePublish(item: item, series: _series());
  }

  @override
  Future<PulseHighlight> highlightPulse() async {
    _staff();
    final points = _points();
    _logAi('pulse', 'highlight', points.join(' ').length);
    return PulseHighlight(points: points, prose: points.join(' '), note: '');
  }

  @override
  Future<SopBundle> onboardingDocs() async {
    _staff();
    return const SopBundle(fiction: true, documents: _docs);
  }

  @override
  Future<BuddyAnswer> onboardingAsk(String question) async {
    _staff();
    final trimmed = question.trim();
    if (trimmed.isEmpty || trimmed.length > 500) {
      throw ApiException(
        code: 'validation',
        message: 'Ask in under 500 characters.',
        status: 400,
      );
    }
    final scrubbed = scrubSecrets(trimmed);
    final hits = _hitsFor(scrubbed);
    _logAi('onboarding', 'ask', scrubbed.length);
    final buffer = StringBuffer(
      'Here is what the fictional SOPs say. This is hackathon material, not EcoCash policy.',
    );
    if (hits.isEmpty) {
      buffer.write(
        '\n\nNothing in the fictional SOP pack matches that. Try PIN, reversal, voice, or the booth.',
      );
    } else {
      for (final hit in hits) {
        buffer.write('\n\n${hit.docTitle} — ${hit.heading}: ${hit.snippet}');
      }
    }
    return BuddyAnswer(
      question: scrubbed,
      answer: buffer.toString(),
      hits: hits,
      note: scrubbed == trimmed
          ? ''
          : 'A secret was scrubbed before the search.',
    );
  }

  List<SopHit> _hitsFor(String question) {
    final lower = question.toLowerCase();
    final hits = <SopHit>[];
    void add(
      String id,
      String title,
      String heading,
      String snippet,
      bool when,
    ) {
      if (when) {
        hits.add(
          SopHit(
            docId: id,
            docTitle: title,
            heading: heading,
            snippet: snippet,
          ),
        );
      }
    }

    add(
      'pin-handling',
      'PIN handling',
      'Never ask for a PIN',
      'An agent never asks a customer for a PIN, OTP or password.',
      lower.contains('pin') ||
          lower.contains('otp') ||
          lower.contains('password'),
    );
    add(
      'reversal-scams',
      'Reversal scams',
      'Stop the call',
      'A reversal text that asks for a PIN is a lure. The customer should not call the number in the SMS.',
      lower.contains('reversal') ||
          lower.contains('scam') ||
          lower.contains('sms'),
    );
    add(
      'accessibility-at-the-booth',
      'Accessibility at the booth',
      'Read the review aloud',
      'The customer reviews the vendor and total, then confirms with a yes and their own PIN. Scanning a QR does not post money.',
      lower.contains('qr') ||
          lower.contains('scan') ||
          lower.contains('access') ||
          lower.contains('booth'),
    );
    add(
      'voice-payments',
      'Voice payments',
      'Language and the hold',
      'Shona, Ndebele, and English phrases prepare a pending transfer. Money posts only after a yes word and the customer PIN.',
      lower.contains('voice') ||
          lower.contains('shona') ||
          lower.contains('ndebele'),
    );
    add(
      'confirming-a-payment',
      'Confirming a payment',
      'Yes, then PIN',
      'Yes words are yes, hongu, yebo, ewe, and ehe. The PIN is checked on the confirm step and is not sent to the model.',
      lower.contains('confirm') ||
          lower.contains('yes') ||
          lower.contains('hongu'),
    );
    return hits.take(3).toList();
  }

  @override
  Future<QuizPaper> onboardingQuiz() async {
    final name = _user().username;
    if (!_user().isStaff) {
      throw ApiException(
        code: 'forbidden',
        message: 'This desk is for the care team.',
        status: 403,
      );
    }
    _quizKeys[name] = ['C', 'A', 'B'];
    return const QuizPaper(note: '', questions: _quiz);
  }

  @override
  Future<QuizScore> onboardingScore(Map<String, String> answers) async {
    final name = _user().username;
    if (!_user().isStaff) {
      throw ApiException(
        code: 'forbidden',
        message: 'This desk is for the care team.',
        status: 403,
      );
    }
    final key = _quizKeys[name];
    if (key == null) {
      throw ApiException(
        code: 'validation',
        message: 'Start the quiz first.',
        status: 400,
      );
    }
    final review = <QuizReview>[];
    var correct = 0;
    for (var i = 0; i < _quiz.length; i++) {
      final picked = (answers['$i'] ?? '').toUpperCase();
      final answer = key[i];
      final ok = picked == answer;
      if (ok) correct += 1;
      review.add(
        QuizReview(
          question: _quiz[i].question,
          picked: picked,
          answer: answer,
          ok: ok,
          docTitle: _quiz[i].docTitle,
          docId: _quiz[i].docId,
        ),
      );
    }
    return QuizScore(correct: correct, total: _quiz.length, review: review);
  }

  @override
  Future<LedgerBook> ledger() async {
    _staff();
    return LedgerBook(
      customers: _ledgerCustomers(),
      merchants: _merchants(),
      agents: const [
        AgentDesk(
          id: 1,
          name: 'Mercy Zhou',
          city: 'Harare',
          booth: 'Copacabana booth',
        ),
        AgentDesk(
          id: 2,
          name: 'Tatenda Moyo',
          city: 'Bulawayo',
          booth: 'City Hall booth',
        ),
      ],
      transactions: _txns
          .take(50)
          .map((txn) => _copy(txn, clearOutgoing: true))
          .toList(),
      receipts: List<ReceiptEntry>.from(_receipts),
    );
  }

  @override
  Future<List<AiCall>> aiLog() async {
    _staff();
    return List<AiCall>.from(_ai.take(30));
  }

  void _logAi(
    String module,
    String operation,
    int chars, {
    String status = 'ok',
    String error = '',
  }) {
    _ai.insert(
      0,
      AiCall(
        id: ++_aiSeq,
        createdAt: _iso(DateTime.now().toUtc()),
        module: module,
        operation: operation,
        provider: 'mock',
        model: 'mock',
        status: status,
        promptChars: chars,
        latencyMs: 1,
        error: error,
      ),
    );
  }

  VoicePlan _plan(String text) {
    final lower = text.toLowerCase().trim();
    var language = 'en';
    if (lower.contains('tumira') ||
        lower.contains('ndiratidze') ||
        lower.contains('tenga') ||
        lower.contains('mari yangu')) {
      language = 'sn';
    }
    if (lower.contains('thumela') ||
        lower.contains('ngibonise') ||
        lower.contains('thenga') ||
        lower.contains('imali')) {
      language = 'nd';
    }
    final available = _pots['USD']!.balance - _pots['USD']!.pending;
    final locked = _phrases.any((phrase) => phrase.text.toLowerCase() == lower);
    if (lower.contains('balance') ||
        lower.contains('ndiratidze') ||
        lower.contains('ngibonise') ||
        lower.contains('mari yangu') ||
        lower.contains('imali yami')) {
      final sentence = switch (language) {
        'sn' => 'Ndiri kukuona mari yenyu.',
        'nd' => 'Ngibona imali yakho.',
        _ => 'Here are both wallets.',
      };
      return _emptyPlan(
        intent: 'check_balance',
        language: language,
        sentence: sentence,
        locked: locked,
        available: available,
        transcript: text,
      );
    }
    if (lower.contains('airtime')) {
      return VoicePlan(
        intent: 'buy_airtime',
        amountCents: 500,
        currency: 'USD',
        language: language,
        recipientId: null,
        recipientName: '',
        merchantId: null,
        merchantName: '',
        missing: const [],
        ambiguous: const [],
        unknownName: '',
        locked: locked,
        confidence: locked ? 0.99 : 0.8,
        sentence: language == 'sn' ? 'Ndichatenga airtime yemadhora mashanu.' : 'I will prepare five dollars of airtime. Nothing posts until you confirm.',
        source: locked ? 'phrase' : 'rules',
        redacted: false,
        providerNote: '',
        transcript: text,
        availableCents: available,
      );
    }
    final missing = <String>[];
    int? amount;
    if (lower.contains('makumi maviri') ||
        lower.contains('twenty') ||
        lower.contains('amabili') ||
        lower.contains('angamatshumi amabili')) {
      amount = 2000;
    } else {
      final match = RegExp(r'(\d{1,6})(?:\.(\d{1,2}))?').firstMatch(lower);
      if (match != null) {
        amount = parseCents(match.group(0)!);
      } else {
        missing.add('amount');
      }
    }
    Contact? contact;
    for (final candidate in _contacts) {
      if (lower.contains(candidate.name.toLowerCase())) contact = candidate;
    }
    if (contact == null &&
        (lower.contains('send') ||
            lower.contains('tumira') ||
            lower.contains('thumela'))) {
      missing.add('recipient');
    }
    if (contact == null &&
        !lower.contains('send') &&
        !lower.contains('tumira') &&
        !lower.contains('thumela')) {
      missing.add('intent');
    }
    final sentence = switch (language) {
      'sn' =>
        'Ndichatumira madhora makumi maviri kuna ${contact?.name ?? '…'}. Hongu here?',
      'nd' =>
        'Ngizathumela amadola angamatshumi amabili ku ${contact?.name ?? '…'}. Kulungile?',
      _ =>
        'I will prepare ${amount == null ? 'a transfer' : formatCents(amount, 'USD')} to ${contact?.name ?? 'someone'}. Nothing posts until you confirm.',
    };
    return VoicePlan(
      intent: 'send_money',
      amountCents: amount,
      currency: lower.contains('zig') ? 'ZIG' : 'USD',
      language: language,
      recipientId: contact?.customerId,
      recipientName: contact?.name ?? '',
      merchantId: null,
      merchantName: '',
      missing: missing,
      ambiguous: const [],
      unknownName: contact == null ? '' : '',
      locked: locked,
      confidence: locked ? 0.99 : 0.74,
      sentence: sentence,
      source: locked ? 'phrase' : 'rules',
      redacted: false,
      providerNote: '',
      transcript: text,
      availableCents: available,
    );
  }

  VoicePlan _emptyPlan({
    required String intent,
    required String language,
    required String sentence,
    required bool locked,
    required int available,
    required String transcript,
  }) {
    return VoicePlan(
      intent: intent,
      amountCents: null,
      currency: 'USD',
      language: language,
      recipientId: null,
      recipientName: '',
      merchantId: null,
      merchantName: '',
      missing: const [],
      ambiguous: const [],
      unknownName: '',
      locked: locked,
      confidence: locked ? 0.99 : 0.9,
      sentence: sentence,
      source: locked ? 'phrase' : 'rules',
      redacted: false,
      providerNote: '',
      transcript: transcript,
      availableCents: available,
    );
  }

  Contact? _matchContact(String? name, int? id) {
    if (id != null) {
      final byId = _contacts.where(
        (contact) => contact.customerId == id || contact.id == id,
      );
      if (byId.isNotEmpty) return byId.first;
    }
    if (name == null || name.trim().isEmpty) return null;
    final lower = name.trim().toLowerCase();
    final matches = _contacts.where(
      (contact) => contact.name.toLowerCase() == lower,
    );
    if (matches.isEmpty) return null;
    return matches.first;
  }

  Merchant? _matchMerchant(String? name, int? id) {
    final all = _merchants();
    if (id != null) {
      final byId = all.where((merchant) => merchant.id == id);
      if (byId.isNotEmpty) return byId.first;
    }
    if (name == null || name.trim().isEmpty) return null;
    final lower = name.trim().toLowerCase();
    final matches = all.where(
      (merchant) => merchant.name.toLowerCase() == lower,
    );
    if (matches.isEmpty) return null;
    return matches.first;
  }

  Txn? _findTxn(int id) {
    final matches = _txns.where((txn) => txn.id == id);
    if (matches.isEmpty) return null;
    return matches.first;
  }

  String _kind(String raw) {
    switch (raw) {
      case 'send_money':
      case 'transfer':
        return 'transfer';
      case 'buy_airtime':
      case 'airtime':
        return 'airtime';
      case 'pay_merchant':
      case 'merchant_pay':
        return 'merchant_pay';
      default:
        throw ApiException(
          code: 'validation',
          message: 'Kind must be a transfer, airtime, or merchant pay.',
          status: 400,
        );
    }
  }

  Txn _asActivity(Txn txn) {
    return _copy(
      txn,
      name: txn.name ?? txn.counterparty,
      initials: txn.initials ?? _initials(txn.counterparty),
    );
  }

  Txn _copy(
    Txn txn, {
    String? status,
    String? postedAt,
    bool? outgoing,
    bool clearOutgoing = false,
    String? name,
    String? initials,
  }) {
    return Txn(
      id: txn.id,
      reference: txn.reference,
      kind: txn.kind,
      category: txn.category,
      status: status ?? txn.status,
      amountCents: txn.amountCents,
      currency: txn.currency,
      display: txn.display,
      senderId: txn.senderId,
      recipientId: txn.recipientId,
      merchantId: txn.merchantId,
      counterparty: txn.counterparty,
      note: txn.note,
      outgoing: clearOutgoing ? null : (outgoing ?? txn.outgoing),
      createdAt: txn.createdAt,
      postedAt: postedAt ?? txn.postedAt,
      name: name ?? txn.name,
      initials: initials ?? txn.initials,
    );
  }

  Txn _posted({
    required int id,
    required String kind,
    required String category,
    required int amount,
    required String currency,
    required String counterparty,
    required String at,
    int? recipientId,
    int? merchantId,
    bool outgoing = true,
    String? name,
    String? initials,
  }) {
    return Txn(
      id: id,
      reference: 'SM-${100000 + id}',
      kind: kind,
      category: category,
      status: 'posted',
      amountCents: amount,
      currency: currency,
      display: formatCents(amount, currency),
      senderId: outgoing ? 1 : null,
      recipientId: recipientId ?? (outgoing ? null : 1),
      merchantId: merchantId,
      counterparty: counterparty,
      note: 'Synthetic',
      outgoing: outgoing,
      createdAt: at,
      postedAt: at,
      name: name,
      initials: initials,
    );
  }

  List<LedgerCustomer> _ledgerCustomers() {
    Wallet row(String currency, int cents) {
      return Wallet(
        currency: currency,
        balanceCents: cents,
        pendingCents: 0,
        availableCents: cents,
        displayBalance: formatCents(cents, currency),
        displayAvailable: formatCents(cents, currency),
      );
    }

    LedgerCustomer person(CustomerProfile profile, int usd, int zig) {
      if (profile.id == 1) {
        return LedgerCustomer(
          profile: profile,
          wallets: [_walletModel('USD'), _walletModel('ZIG')],
        );
      }
      return LedgerCustomer(
        profile: profile,
        wallets: [row('USD', usd), row('ZIG', zig)],
      );
    }

    return [
      person(_rudo(), 8600, 42000),
      person(
        const CustomerProfile(
          id: 2,
          fullName: 'Mai Tendai',
          shortName: 'Mai Tendai',
          city: 'Chitungwiza',
          language: 'sn',
          role: 'Parent',
          phoneMasked: '0772••••14',
        ),
        12000,
        8000,
      ),
      person(
        const CustomerProfile(
          id: 3,
          fullName: 'Farai Ncube',
          shortName: 'Farai Ncube',
          city: 'Bulawayo',
          language: 'nd',
          role: 'Mechanic',
          phoneMasked: '0773••••22',
        ),
        6400,
        15000,
      ),
      person(
        const CustomerProfile(
          id: 4,
          fullName: 'Nomsa Ndlovu',
          shortName: 'Nomsa Ndlovu',
          city: 'Bulawayo',
          language: 'nd',
          role: 'Teacher',
          phoneMasked: '0774••••08',
        ),
        9100,
        4300,
      ),
      person(
        const CustomerProfile(
          id: 5,
          fullName: 'Baba Joseph',
          shortName: 'Baba Joseph',
          city: 'Harare',
          language: 'en',
          role: 'Pensioner',
          phoneMasked: '0775••••19',
        ),
        3000,
        22000,
      ),
      person(
        const CustomerProfile(
          id: 6,
          fullName: 'Tendai Moyo',
          shortName: 'Tendai Moyo',
          city: 'Chitungwiza',
          language: 'sn',
          role: 'Student',
          phoneMasked: '0776••••33',
        ),
        1500,
        6000,
      ),
      person(
        const CustomerProfile(
          id: 7,
          fullName: 'Chipo Dube',
          shortName: 'Chipo Dube',
          city: 'Mutare',
          language: 'sn',
          role: 'Nurse',
          phoneMasked: '0777••••45',
        ),
        7200,
        5400,
      ),
      person(
        const CustomerProfile(
          id: 8,
          fullName: 'Blessing Phiri',
          shortName: 'Blessing Phiri',
          city: 'Gweru',
          language: 'en',
          role: 'Driver',
          phoneMasked: '0778••••27',
        ),
        4100,
        9800,
      ),
    ];
  }

  List<Merchant> _merchants() {
    return const [
      Merchant(
        id: 3,
        name: 'Copacabana Butchery',
        category: 'Butchery',
        city: 'Harare',
      ),
      Merchant(
        id: 4,
        name: 'Green Basket Grocer',
        category: 'Groceries',
        city: 'Bulawayo',
      ),
      Merchant(
        id: 2,
        name: 'Mbare Fresh Produce',
        category: 'Groceries',
        city: 'Harare',
      ),
      Merchant(
        id: 1,
        name: "Rudo's Tuckshop",
        category: 'Tuckshop',
        city: 'Harare',
      ),
      Merchant(
        id: 5,
        name: 'Town Grocer',
        category: 'Groceries',
        city: 'Mutare',
      ),
    ];
  }

  ReceiptExtraction _extractionFor(ReceiptSample sample) {
    if (sample.filename == 'green-basket.png') {
      return const ReceiptExtraction(
        vendor: 'Green Basket Grocer',
        date: '2026-10-18',
        currency: 'USD',
        totalCents: 350,
        display: 'US\$ 3.50',
        items: [
          ReceiptItem(description: 'Cabbage', amountCents: 200),
          ReceiptItem(description: 'Eggs', amountCents: 150),
        ],
        note: 'Synthetic till slip. Not a real grocer.',
        source: 'sample',
      );
    }
    if (sample.filename == 'qr-pay.png') {
      return const ReceiptExtraction(
        vendor: 'Mbare Fresh Produce',
        date: '',
        currency: 'USD',
        totalCents: 550,
        display: 'US\$ 5.50',
        items: [],
        note: 'Merchant pay QR. It does not send money. Prepare a review, then confirm.',
        source: 'sample',
      );
    }
    return const ReceiptExtraction(
      vendor: 'Mbare Fresh Produce',
      date: '2026-10-20',
      currency: 'USD',
      totalCents: 550,
      display: 'US\$ 5.50',
      items: [
        ReceiptItem(description: 'Tomatoes 2kg', amountCents: 400),
        ReceiptItem(description: 'Onions 1kg', amountCents: 150),
      ],
      note: 'Synthetic till slip for the tuckshop ledger.',
      source: 'sample',
    );
  }
}

String scrubSecrets(String text) {
  var out = text.replaceAll(
    RegExp(r'\b0(?:[\s-]?\d){8,10}\b'),
    '[phone]',
  );
  out = out.replaceAllMapped(RegExp(r'\b\d{4,6}\b'), (match) {
    final raw = match.group(0)!;
    final value = int.tryParse(raw);
    if (value != null && raw.length == 4 && value >= 2020 && value <= 2035) {
      return raw;
    }
    return '[redacted]';
  });
  return out;
}

String _verdictLabel(String verdict) {
  switch (verdict) {
    case 'likely_scam':
      return 'Likely scam';
    case 'suspicious':
      return 'Suspicious';
    default:
      return 'Looks safe';
  }
}

String _initials(String name) {
  final parts = name.split(' ').where((part) => part.isNotEmpty).toList();
  if (parts.isEmpty) return '•';
  if (parts.length == 1) {
    final word = parts.first;
    return (word.length >= 2 ? word.substring(0, 2) : word).toUpperCase();
  }
  return (parts[0][0] + parts[1][0]).toUpperCase();
}

String _iso(DateTime value) {
  final utc = value.toUtc();
  String two(int number) => number.toString().padLeft(2, '0');
  return '${utc.year}-${two(utc.month)}-${two(utc.day)}T${two(utc.hour)}:${two(utc.minute)}:${two(utc.second)}Z';
}

String _date(DateTime value) {
  final local = value.toLocal();
  String two(int number) => number.toString().padLeft(2, '0');
  return '${local.year}-${two(local.month)}-${two(local.day)}';
}

String _weekday(DateTime value) {
  const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return names[value.weekday - 1];
}

class _Pot {
  _Pot(this.balance, this.pending);
  int balance;
  int pending;
}

class _Day {
  _Day(this.label, this.date, this.amountCents);
  final String label;
  final String date;
  int amountCents;
}

class _PulseDay {
  _PulseDay(this.date, this.total, this.negative);
  final String date;
  int total;
  int negative;
}

class _ThemeCount {
  _ThemeCount(this.label, this.count);
  final String label;
  int count;
}

class _RegionCount {
  _RegionCount(this.region, this.negative, this.neutral, this.positive);
  final String region;
  int negative;
  int neutral;
  int positive;
  int get volume => negative + neutral + positive;
}

class _DemoProgress {
  _DemoProgress({required this.started, this.index, this.done = false});
  final bool started;
  final int? index;
  final bool done;
}

PulseItem _feedItem(
  int id,
  String source,
  String text,
  String theme,
  String label,
  String sentiment,
  String region,
  String at,
) {
  return PulseItem(
    id: id,
    source: source,
    text: text,
    theme: theme,
    themeLabel: label,
    sentiment: sentiment,
    region: region,
    createdAt: at,
  );
}

const _contacts = [
  Contact(id: 1, name: 'Mai Tendai', city: 'Chitungwiza', customerId: 2),
  Contact(id: 2, name: 'Farai Ncube', city: 'Bulawayo', customerId: 3),
  Contact(id: 3, name: 'Nomsa Ndlovu', city: 'Bulawayo', customerId: 4),
  Contact(id: 4, name: 'Baba Joseph', city: 'Harare', customerId: 5),
];

const _phrases = [
  VoicePhrase(
    language: 'sn',
    label: 'Shona',
    text: 'tumira madhora makumi maviri kuna Mai Tendai',
    hint: 'Send twenty dollars to Mai Tendai',
  ),
  VoicePhrase(
    language: 'sn',
    label: 'Shona',
    text: 'ndiratidze mari yangu',
    hint: 'Show my balance',
  ),
  VoicePhrase(
    language: 'sn',
    label: 'Shona',
    text: 'tenga airtime yemadhora mashanu',
    hint: 'Buy five dollars of airtime',
  ),
  VoicePhrase(
    language: 'nd',
    label: 'Ndebele',
    text: 'thumela amadola angamatshumi amabili ku Mai Tendai',
    hint: 'Send twenty dollars to Mai Tendai',
  ),
  VoicePhrase(
    language: 'nd',
    label: 'Ndebele',
    text: 'ngibonise imali yami',
    hint: 'Show my balance',
  ),
  VoicePhrase(
    language: 'nd',
    label: 'Ndebele',
    text: 'thenga airtime yamadola amahlanu',
    hint: 'Buy five dollars of airtime',
  ),
  VoicePhrase(
    language: 'en',
    label: 'English',
    text: 'send twenty dollars to Mai Tendai',
    hint: 'Send twenty dollars to Mai Tendai',
  ),
  VoicePhrase(
    language: 'en',
    label: 'English',
    text: 'check my balance',
    hint: 'Show both wallets',
  ),
  VoicePhrase(
    language: 'en',
    label: 'English',
    text: 'buy airtime for five dollars',
    hint: 'Buy five dollars of airtime',
  ),
];

const _scamSamples = [
  ScamSample(
    id: 'reversal',
    title: 'Fake reversal',
    text: 'EcoCash: reversal of USD 20.00 to Mai Tendai failed. I am an agent. Send your PIN within 15 minutes or the wallet will be blocked.',
  ),
  ScamSample(
    id: 'prize',
    title: 'Prize bait',
    text: 'CONGRATULATIONS you have won USD 500 airtime. Share this SMS and send your EcoCash PIN to 0771 000 000 to claim before midnight. This is a synthetic lure.',
  ),
  ScamSample(
    id: 'agent',
    title: 'Fake agent',
    text: 'Good morning, this is Agent Tafadzwa from EcoCash Copacabana. Your line has a pending reversal. Please read me your PIN so I can release the funds.',
  ),
  ScamSample(
    id: 'family',
    title: 'Ordinary family note',
    text: 'Mai Tendai: ndasvika kuChitungwiza. Please send twenty dollars when you can. Love, Amai.',
  ),
  ScamSample(
    id: 'pressure',
    title: 'Pressure, no PIN yet',
    text: 'Your EcoCash wallet will be suspended within 10 minutes. Call this agent now to avoid a block. Do not tell anyone.',
  ),
];

const _receiptSamples = [
  ReceiptSample(
    filename: 'mbare-fresh.png',
    vendor: 'Mbare Fresh Produce',
    date: '2026-10-20',
    currency: 'USD',
    note: 'Synthetic till slip for the tuckshop ledger.',
    title: '',
    payload: '',
  ),
  ReceiptSample(
    filename: 'green-basket.png',
    vendor: 'Green Basket Grocer',
    date: '2026-10-18',
    currency: 'USD',
    note: 'Synthetic till slip. Not a real grocer.',
    title: '',
    payload: '',
  ),
  ReceiptSample(
    filename: 'qr-till.png',
    vendor: '',
    date: '',
    currency: '',
    note: '',
    title: 'Till slip QR',
    payload: 'SYNTHETIC TILL SLIP\nVendor: Mbare Fresh Produce\nDate: 20 Oct 2026\nTomatoes 2kg USD 4.00\nOnions 1kg USD 1.50\nTotal USD 5.50',
  ),
  ReceiptSample(
    filename: 'qr-pay.png',
    vendor: '',
    date: '',
    currency: '',
    note: '',
    title: 'Merchant pay QR',
    payload:
        'SHAMWARI-PAY\nmerchant=Mbare Fresh Produce\namount=5.50\ncurrency=USD',
  ),
];

const _customerSearch = [
  SearchHit(
    label: 'Send money',
    group: 'Actions',
    hint: 'Move USD or ZiG. It stays pending until yes.',
    apiPath: '/api/v1/transfers',
  ),
  SearchHit(
    label: 'Voice pay',
    group: 'Actions',
    hint: 'Shona, Ndebele, English',
    apiPath: '/api/v1/voice/interpret',
  ),
  SearchHit(
    label: 'Financial coach',
    group: 'Grow',
    hint: 'School fees and airtime',
    apiPath: '/api/v1/coach',
  ),
  SearchHit(
    label: 'Scam check',
    group: 'Protect',
    hint: 'SMS and call notes',
    apiPath: '/api/v1/scam/check',
  ),
  SearchHit(
    label: 'Receipts',
    group: 'Money',
    hint: "Rudo's tuckshop slips",
    apiPath: '/api/v1/receipts',
  ),
  SearchHit(
    label: 'Accessibility',
    group: 'Settings',
    hint: 'Type, contrast, spoken balance',
    apiPath: '/api/v1/accessibility',
  ),
  SearchHit(
    label: 'Wallet',
    group: 'Money',
    hint: 'Balances and the week',
    apiPath: '/api/v1/wallet',
  ),
  SearchHit(
    label: 'Activity',
    group: 'Money',
    hint: 'Recent rows',
    apiPath: '/api/v1/activity',
  ),
  SearchHit(
    label: 'Mai Tendai',
    group: 'People',
    hint: 'Chitungwiza',
    apiPath: '/api/v1/transfers',
  ),
  SearchHit(
    label: "Walk Rudo's morning",
    group: 'Demo',
    hint: 'Guided script',
    apiPath: '/api/v1/demo',
  ),
];

const _staffSearch = [
  SearchHit(
    label: 'Customer Pulse',
    group: 'Insights',
    hint: 'Live themes and sentiment',
    apiPath: '/api/v1/pulse',
  ),
  SearchHit(
    label: 'Onboarding buddy',
    group: 'Team',
    hint: 'Fictional SOPs and the quiz',
    apiPath: '/api/v1/onboarding/ask',
  ),
  SearchHit(
    label: 'Ledger',
    group: 'Insights',
    hint: 'Customers, tills, and the book',
    apiPath: '/api/v1/ledger',
  ),
  SearchHit(
    label: 'AI log',
    group: 'Insights',
    hint: 'Model call metadata',
    apiPath: '/api/v1/ai-log',
  ),
  SearchHit(
    label: 'Open pulse',
    group: 'Actions',
    hint: 'Publish the next note',
    apiPath: '/api/v1/pulse/publish',
  ),
  SearchHit(
    label: 'Merchants',
    group: 'Book',
    hint: 'Synthetic tills',
    apiPath: '/api/v1/merchants',
  ),
  SearchHit(
    label: "Walk Rudo's morning",
    group: 'Demo',
    hint: 'Guided script',
    apiPath: '/api/v1/demo',
  ),
];

const _steps = [
  DemoStep(
    number: 1,
    slug: 'voice',
    role: 'customer',
    kicker: 'About 1 min',
    title: 'Rudo sends twenty dollars in Shona',
    narration: 'Rudo Moyo is packing tomatoes in Mbare. Her mother, Mai Tendai, needs groceries in Chitungwiza. Rudo speaks instead of typing.',
    action: 'Press the Shona send phrase. Shamwari resolves Mai Tendai and speaks a confirmation. Prepare the transfer so it sits as pending, then type hongu and the demo PIN 2580 to post it. The PIN stays in that form. It is not sent to the model.',
    calls: [
      'GET /api/v1/voice/phrases',
      'POST /api/v1/voice/interpret',
      'POST /api/v1/voice/prepare',
      'POST /api/v1/transfers/{id}/confirm',
    ],
  ),
  DemoStep(
    number: 2,
    slug: 'access',
    role: 'customer',
    kicker: 'About 1 min',
    title: 'Make the book easier to see',
    narration: 'The stall is bright. Rudo turns on large type and high contrast, and listens to the balance line.',
    action: 'Open accessibility. Turn on large type and high contrast. The spoken line quotes the available dollars. The PIN is still not part of this screen.',
    calls: ['GET /api/v1/accessibility', 'PUT /api/v1/accessibility'],
  ),
  DemoStep(
    number: 3,
    slug: 'coach',
    role: 'customer',
    kicker: 'About 1 min',
    title: 'Ask about Term 2 school fees',
    narration: 'Rudo wants to know if the school-fees mark can still be reached. The figures are counted in the book. The coach only phrases them.',
    action: 'Send “Can I still make my school fees goal?” Do not type the PIN here. A PIN-like number would be scrubbed before it is saved.',
    calls: ['GET /api/v1/coach', 'POST /api/v1/coach/messages'],
  ),
  DemoStep(
    number: 4,
    slug: 'scam',
    role: 'customer',
    kicker: 'About 1 min',
    title: 'Check the reversal SMS',
    narration: 'A text claims a reversal failed and asks for a PIN. Rudo does not reply. She pastes it into Shamwari.',
    action: 'Open the fake reversal sample. The rules say likely scam, and the final verdict is never softer than the rules.',
    calls: ['GET /api/v1/scam/samples', 'POST /api/v1/scam/check'],
  ),
  DemoStep(
    number: 5,
    slug: 'receipts',
    role: 'customer',
    kicker: 'About 1 min',
    title: 'File the Mbare till slip',
    narration: 'The tomatoes are in. Rudo keeps the till slip on the tuckshop book, not in the wallet.',
    action: 'Read mbare-fresh.png, check the lines, and save it. The pay QR does not send money.',
    calls: [
      'GET /api/v1/receipts/samples',
      'POST /api/v1/receipts/read',
      'POST /api/v1/receipts',
    ],
  ),
  DemoStep(
    number: 6,
    slug: 'pulse',
    role: 'staff',
    kicker: 'Care desk',
    title: 'Read the live customer pulse',
    narration: 'The care desk watches Harare, Bulawayo, and the other towns. Themes come from a local classifier.',
    action: 'Sign in as care. Open Customer Pulse. The charts are the JSON series. Publish a note or rewrite the highlight. A customer token cannot open this desk.',
    calls: ['GET /api/v1/pulse', 'POST /api/v1/pulse/highlight'],
  ),
  DemoStep(
    number: 7,
    slug: 'onboarding',
    role: 'staff',
    kicker: 'Care desk',
    title: 'Ask the onboarding buddy',
    narration: 'A new agent asks what to do when a customer is asked for a PIN. The answer cites fictional SOPs. It is not EcoCash policy.',
    action: 'Ask the PIN question, then start the quiz. The answer key stays on the server until you score.',
    calls: [
      'POST /api/v1/onboarding/ask',
      'POST /api/v1/onboarding/quiz',
      'POST /api/v1/onboarding/quiz/score',
    ],
  ),
];

const _docs = [
  SopDoc(
    docId: 'pin-handling',
    title: 'PIN handling',
    body: '# PIN handling\n\n## Never ask for a PIN\n\nAn agent never asks a customer for a PIN, OTP or password. If a customer starts to say one, stop them and ask them to enter it only on their own confirm screen.',
  ),
  SopDoc(
    docId: 'reversal-scams',
    title: 'Reversal scams',
    body: '# Reversal scams\n\n## Stop the call\n\nA reversal text that asks for a PIN is a lure. The customer should not call the number in the SMS. Shamwari can check the wording. The pattern list still answers if a model refuses the text.',
  ),
  SopDoc(
    docId: 'accessibility-at-the-booth',
    title: 'Accessibility at the booth',
    body: '# Accessibility at the booth\n\n## Read the review aloud\n\nRead the vendor and the total before anything is confirmed. The customer reviews the vendor and total, then confirms with a yes and their own PIN. Scanning a QR does not post money.',
  ),
  SopDoc(
    docId: 'voice-payments',
    title: 'Voice payments',
    body: '# Voice payments\n\n## Language and the hold\n\nShona, Ndebele, and English phrases prepare a pending transfer. Money posts only after a yes word and the customer PIN.',
  ),
  SopDoc(
    docId: 'confirming-a-payment',
    title: 'Confirming a payment',
    body: '# Confirming a payment\n\n## Yes, then PIN\n\nYes words are yes, hongu, yebo, ewe, and ehe. The PIN is checked on the confirm step and is not sent to the model.',
  ),
];

const _quiz = [
  QuizQuestion(
    question: 'A customer asks you to scan a payment QR and "just send it". What has to happen before money moves?',
    docId: 'accessibility-at-the-booth',
    docTitle: 'Accessibility at the booth',
    choices: [
      QuizChoice(
        key: 'A',
        text: 'Scanning the QR posts the payment immediately',
      ),
      QuizChoice(
        key: 'B',
        text: 'You enter your staff PIN to approve the scan',
      ),
      QuizChoice(
        key: 'C',
        text: 'The customer reviews the vendor and total, then confirms with a yes and their own PIN',
      ),
      QuizChoice(
        key: 'D',
        text: 'You read the QR aloud and the payment posts when you finish speaking',
      ),
    ],
  ),
  QuizQuestion(
    question: 'A caller says they are an EcoCash agent and asks the customer to read a PIN so a reversal can finish. What do you do?',
    docId: 'pin-handling',
    docTitle: 'PIN handling',
    choices: [
      QuizChoice(
        key: 'A',
        text: 'Stop. An agent never asks for a PIN, and the customer should not say it',
      ),
      QuizChoice(
        key: 'B',
        text: 'Write the PIN down and call the number in the SMS',
      ),
      QuizChoice(
        key: 'C',
        text: 'Enter the PIN on the care laptop to speed the reversal up',
      ),
      QuizChoice(
        key: 'D',
        text: 'Ask the customer to repeat the PIN slowly for the recording',
      ),
    ],
  ),
  QuizQuestion(
    question: 'Rudo says a Shona send phrase and Shamwari prepares twenty dollars to Mai Tendai. When does the money post?',
    docId: 'voice-payments',
    docTitle: 'Voice payments',
    choices: [
      QuizChoice(key: 'A', text: 'As soon as the phrase is understood'),
      QuizChoice(
        key: 'B',
        text: 'After a yes word and Rudo\'s own PIN on the confirm step',
      ),
      QuizChoice(key: 'C', text: 'When the care desk approves the voice log'),
      QuizChoice(key: 'D', text: 'When the coach repeats the amount'),
    ],
  ),
];

const _png =
    'iVBORw0KGgoAAAANSUhEUgAAAHgAAACgCAYAAADHCaiQAAABN0lEQVR42u3RQQkAIBREQc9ehZ/BMqYxvSfNoCCIDOwrsJNy1Kl/S04ALMACLMACLMDaAh497Gx+97vf/e53v/vd7343v/vdLv5eatPjAQYMGLAAC7AAC7AAAwYMGDBgARZgARZgwIABAwYswAIswAIswIABAxZgARZgARZgwIABAwYswAIswAIMGDBgwIAFWIAFWIAFGDBgwA4ELMACLMACDBgwYMCABViABViAAQMGDBiwAAuwAAuwAAMGDBgwYAEWYAEWYMCAAQMGLMACLMACLMCAAQMWYAEWYAEWYMCAAQMGLMACLMACDBgwYMCABViABViABRgwYMAOBCzAAizAAgwYMGDAgAVYgAVYgAEDBgwYsAALsAALsAADBgwYMGABFmABFmDAgAHrqwADFmABFmAB1m4LsWudMb9xuZwAAAAASUVORK5CYII=';
