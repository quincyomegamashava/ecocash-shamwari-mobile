import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/api_exception.dart';
import '../core/models/models.dart';
import '../core/money.dart';
import '../core/session/session.dart';
import '../dev/capture_cue.dart';
import '../core/theme/shamwari_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/motion.dart';
import '../widgets/pin_pad.dart';
import '../widgets/risk_card.dart';
import '../widgets/states.dart';

class SendMoneyScreen extends ConsumerStatefulWidget {
  const SendMoneyScreen({super.key});

  @override
  ConsumerState<SendMoneyScreen> createState() => _SendMoneyScreenState();
}

class _SendMoneyScreenState extends ConsumerState<SendMoneyScreen> {
  final _amount = TextEditingController(text: '20');
  String _kind = 'transfer';
  String _currency = 'USD';
  Contact? _contact;
  Merchant? _merchant;
  List<Contact> _contacts = const [];
  List<Merchant> _merchants = const [];
  WalletSnapshot? _wallet;
  bool _loading = true;
  bool _busy = false;
  Object? _error;
  Txn? _pending;
  String _yes = 'hongu';
  String _pin = '';
  bool _riskAck = false;
  String? _formError;
  ConfirmResult? _posted;
  int _shakes = 0;
  var _captureSuccessStarted = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ref.read(shamwariApiProvider);
      final pace = ref.read(loadPaceProvider);
      final results = await Future.wait([
        api.contacts(),
        api.merchants(),
        api.wallet(),
        Future<void>.delayed(pace),
      ]);
      if (!mounted) return;
      final contacts = results[0] as List<Contact>;
      setState(() {
        _contacts = contacts;
        _merchants = results[1] as List<Merchant>;
        _wallet = results[2] as WalletSnapshot;
        _contact ??= contacts.isEmpty ? null : contacts.first;
        _loading = false;
      });
      if (captureTourActive && CaptureCue.phase.value == 'pin') {
        await _prepare();
      }
      if (captureTourActive && CaptureCue.phase.value == 'send-risk') {
        await _prize();
        if (!mounted || CaptureCue.phase.value != 'send-risk') return;
        await WidgetsBinding.instance.endOfFrame;
        if (!mounted) return;
        await captureReveal(
          context,
          (element) => element.widget.key == const Key('risk-warning'),
        );
        CaptureCue.ready.value = 'send-risk-ready';
      }
      if (captureTourActive &&
          CaptureCue.phase.value == 'success' &&
          !_captureSuccessStarted) {
        _captureSuccessStarted = true;
        await _prepare();
        if (!mounted || _pending == null) return;
        _pin = '2580';
        _yes = 'yes';
        await _confirm();
        if (!mounted || _posted == null) return;
        CaptureCue.ready.value = 'success-ready';
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  Future<void> _prepare() async {
    final cents = parseCents(_amount.text);
    if (cents == null) {
      setState(() => _formError = 'Enter an amount like 20 or 20.50.');
      return;
    }
    setState(() {
      _busy = true;
      _formError = null;
    });
    try {
      final result = await ref
          .read(shamwariApiProvider)
          .createTransfer(
            amountCents: cents,
            currency: _currency,
            kind: _kind,
            recipientName: _kind == 'transfer' ? _contact?.name : null,
            recipientId: _kind == 'transfer' ? _contact?.customerId : null,
            merchantName: _kind == 'merchant_pay' ? _merchant?.name : null,
            merchantId: _kind == 'merchant_pay' ? _merchant?.id : null,
          );
      if (!mounted) return;
      setState(() {
        _pending = result.transaction;
        _pin = '';
        _riskAck = false;
      });
      if (captureTourActive && CaptureCue.phase.value == 'pin') {
        await WidgetsBinding.instance.endOfFrame;
        if (!mounted) return;
        await captureReveal(
          context,
          (element) => element.widget.key == const Key('pin-pad'),
        );
        CaptureCue.phase.value = 'pin-ready';
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _formError = friendlyError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirm() async {
    final pending = _pending;
    if (pending == null) return;
    setState(() => _busy = true);
    try {
      final result = await ref
          .read(shamwariApiProvider)
          .confirmTransfer(
            pending.id,
            confirmWord: _yes,
            pin: _pin,
            riskAck: _riskAck,
          );
      if (!mounted) return;
      setState(() {
        _posted = result;
        _pin = '';
        _pending = null;
      });
      await _load();
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _formError = friendlyError(error);
        _pin = '';
        if (error.code == 'bad_pin') _shakes += 1;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _prize() async {
    setState(() {
      _busy = true;
      _formError = null;
    });
    try {
      final result = await ref.read(shamwariApiProvider).prizeRiskTransfer();
      if (!mounted) return;
      setState(() {
        _pending = result.transaction;
        _pin = '';
        _riskAck = false;
        _posted = null;
      });
    } catch (error) {
      if (mounted) setState(() => _formError = friendlyError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel() async {
    final pending = _pending;
    if (pending == null) return;
    setState(() => _busy = true);
    try {
      await ref.read(shamwariApiProvider).cancelTransfer(pending.id);
      if (!mounted) return;
      setState(() {
        _pending = null;
        _pin = '';
        _formError = null;
      });
      await _load();
    } catch (error) {
      if (mounted) setState(() => _formError = friendlyError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    if (_loading && _wallet == null) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: SkeletonColumn(),
      );
    }
    if (_error != null && _wallet == null) {
      return ErrorPane(error: _error!, onRetry: _load);
    }
    if (_posted != null) return _done(context);
    if (_pending != null) return _confirmStage(context);
    final available = _wallet?.wallet(_currency);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
      children: [
        const SectionLabel('Money'),
        Text(
          'Send. Then confirm.',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        Text(
          'Nothing posts until a yes word and the PIN.',
          style: TextStyle(color: context.inkMuted),
        ),
        const SizedBox(height: 14),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'transfer', label: Text('Person')),
            ButtonSegment(value: 'airtime', label: Text('Airtime')),
            ButtonSegment(value: 'merchant_pay', label: Text('Merchant')),
          ],
          selected: {_kind},
          onSelectionChanged: (value) => setState(() => _kind = value.first),
        ),
        const SizedBox(height: 14),
        TextField(
          key: const Key('amount'),
          controller: _amount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
          decoration: InputDecoration(
            prefixText: '${currencyMark(_currency)}  ',
            labelText: 'Amount',
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ChoiceChip(
              label: const Text('USD'),
              selected: _currency == 'USD',
              onSelected: (_) => setState(() => _currency = 'USD'),
            ),
            ChoiceChip(
              label: const Text('ZiG'),
              selected: _currency == 'ZIG',
              onSelected: (_) => setState(() => _currency = 'ZIG'),
            ),
            if (available != null)
              Text(
                'Available ${available.displayAvailable}',
                style: TextStyle(color: context.inkMuted, fontSize: 12),
              ),
          ],
        ),
        const SizedBox(height: 14),
        if (_kind == 'transfer') ...[
          const SectionLabel('To'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final contact in _contacts)
                ChoiceChip(
                  label: Text(contact.name),
                  selected: _contact?.id == contact.id,
                  onSelected: (_) => setState(() => _contact = contact),
                ),
            ],
          ),
        ],
        if (_kind == 'merchant_pay') ...[
          const SectionLabel('Merchant'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final merchant in _merchants.where((item) => item.id != 1))
                ChoiceChip(
                  label: Text(merchant.name),
                  selected: _merchant?.id == merchant.id,
                  onSelected: (_) => setState(() => _merchant = merchant),
                ),
            ],
          ),
        ],
        if (_kind == 'airtime')
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Airtime stays under the demo cap of US\$ 100.',
              style: TextStyle(color: context.inkMuted),
            ),
          ),
        if (_formError != null) ...[
          const SizedBox(height: 10),
          Text(
            _formError!,
            style: TextStyle(
              color: palette.danger,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: 16),
        FilledButton(
          key: const Key('prepare-transfer'),
          onPressed: _busy ? null : _prepare,
          child: Text(_busy ? 'Holding…' : 'Prepare pending'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          key: const Key('prize-desk'),
          onPressed: _busy ? null : _prize,
          child: const Text('Load the prize-desk scam warning'),
        ),
      ],
    );
  }

  Widget _confirmStage(BuildContext context) {
    final palette = context.palette;
    final pending = _pending!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
      children: [
        const SectionLabel('Confirm'),
        Text(
          'Still pending.',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        Text(
          '${pending.display} to ${pending.counterparty}',
          style: TextStyle(color: context.inkMuted),
        ),
        Text(
          pending.reference,
          style: TextStyle(color: palette.faint, fontSize: 12),
        ),
        const SizedBox(height: 8),
        Text(
          'The PIN is sent only with this confirm. It is not written to the AI log.',
          style: TextStyle(color: context.inkMuted, fontSize: 13),
        ),
        if (pending.risk.notable) ...[
          const SizedBox(height: 12),
          RiskWarning(
            risk: pending.risk,
            acknowledged: _riskAck,
            busy: _busy,
            onAcknowledge: () => setState(() => _riskAck = true),
            onCancel: _cancel,
          ),
        ],
        if (!pending.risk.requiresAck || _riskAck) ...[
        const SizedBox(height: 12),
        const SectionLabel('Yes word'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final word in const ['hongu', 'yes', 'yebo', 'ewe', 'ehe'])
              ChoiceChip(
                label: Text(word),
                selected: _yes == word,
                onSelected: (_) => setState(() => _yes = word),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Shake(
          token: _shakes,
          child: PinPad(
            pin: _pin,
            onChanged: (value) => setState(() => _pin = value),
          ),
        ),
        if (_formError != null) ...[
          const SizedBox(height: 8),
          Text(
            _formError!,
            style: TextStyle(
              color: palette.danger,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: 8),
        FilledButton(
          key: const Key('pin-confirm'),
          onPressed: _busy || _pin.length != 4 ? null : _confirm,
          child: Text(_busy ? 'Checking…' : 'Confirm with $_yes'),
        ),
        TextButton(
          onPressed: _busy ? null : _cancel,
          child: const Text('Cancel the hold'),
        ),
        ],
      ],
    );
  }

  Widget _done(BuildContext context) {
    final posted = _posted!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        const SectionLabel('Posted'),
        const SuccessMark(),
        const SizedBox(height: 12),
        Text(
          'The book moved.',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 12),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                posted.transaction.display,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                posted.transaction.reference,
                style: TextStyle(color: context.inkMuted),
              ),
              const SizedBox(height: 8),
              Text(
                'PIN checked on this device’s request. Sent to the model: ${posted.pinSentToModel ? 'yes' : 'no'}.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => setState(() => _posted = null),
          child: const Text('Send another'),
        ),
      ],
    );
  }
}
