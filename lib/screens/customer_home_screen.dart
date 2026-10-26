import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../core/models/models.dart';
import '../core/session/session.dart';
import '../core/theme/shamwari_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/motion.dart';
import '../widgets/states.dart';

class CustomerHomeScreen extends ConsumerStatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  ConsumerState<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends ConsumerState<CustomerHomeScreen> {
  WalletSnapshot? _wallet;
  List<Txn> _activity = const [];
  CoachState? _coach;
  int _slips = 0;
  Object? _error;
  bool _loading = true;
  String _currency = 'USD';

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
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
        api.wallet(),
        api.activity(),
        api.coach(),
        api.receipts(),
        Future<void>.delayed(pace),
      ]);
      if (!mounted) return;
      setState(() {
        _wallet = results[0] as WalletSnapshot;
        _activity = results[1] as List<Txn>;
        _coach = results[2] as CoachState;
        _slips = (results[3] as ReceiptBook).entries.length;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final first = (auth.user?.displayName ?? 'Rudo').split(' ').first;
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: SkeletonColumn(),
      );
    }
    if (_error != null || _wallet == null) {
      return ErrorPane(
        error: _error ?? 'The book did not load.',
        onRetry: _load,
      );
    }
    final wallet = _wallet!;
    final selected = wallet.wallet(_currency) ?? wallet.wallets.first;
    final hour = DateTime.now().hour;
    final hello = hour < 12
        ? 'Mangwanani · Good morning'
        : hour < 17
        ? 'Masikati · Good afternoon'
        : 'Manheru · Good evening';
    final airtime = _coach?.categories.where((item) => item.key == 'airtime');
    final airtimeShare = (airtime == null || airtime.isEmpty)
        ? null
        : airtime.first;

    final delta = wallet.week.deltaPct;
    final goalName = wallet.goal?.name;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Text(
            'Mhoro, $first',
            style: TextStyle(
              color: context.inkMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            hello,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          GlassCard(
            navy: true,
            radius: 28,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Your available balance',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xB3FFFFFF),
                        ),
                      ),
                    ),
                    _CurrencyToggle(
                      value: _currency,
                      onChanged: (value) => setState(() => _currency = value),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${wallet.customer.city} · ${wallet.customer.role}',
                  style: const TextStyle(
                    color: Color(0xB3FFFFFF),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Hero(
                  tag: 'shamwari-balance',
                  child: Material(
                    type: MaterialType.transparency,
                    child: MoneyHero(selected.displayAvailable),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FadeSlideIn(
                      child: _DeltaChip(
                        delta == null ? 'No prior week' : '+$delta% this week',
                        positive: delta == null || delta >= 0,
                      ),
                    ),
                    if (goalName != null)
                      FadeSlideIn(
                        index: 1,
                        child: _DeltaChip(goalName, positive: true),
                      ),
                    if (airtimeShare != null)
                      FadeSlideIn(
                        index: 2,
                        child: _DeltaChip(
                          'Airtime ${(airtimeShare.share * 100).round()}%',
                          positive: true,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _QuickAction(
                      icon: Icons.arrow_upward_rounded,
                      label: 'Send',
                      onTap: () => context.go('/send'),
                    ),
                    const SizedBox(width: 8),
                    _QuickAction(
                      icon: Icons.add_rounded,
                      label: 'Top up',
                      onTap: () => _gap(context, 'Top-up'),
                    ),
                    const SizedBox(width: 8),
                    _QuickAction(
                      icon: Icons.arrow_downward_rounded,
                      label: 'Withdraw',
                      onTap: () => _gap(context, 'Withdraw'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Also in the wallet',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final entry in [
                ('/voice', 'Voice notes', Icons.mic_rounded),
                ('/chat', 'Chat', Icons.chat_bubble_outline_rounded),
                ('/ussd', 'USSD', Icons.dialpad_rounded),
                ('/coach', 'Coach', Icons.auto_awesome_rounded),
                ('/scam', 'Scam check', Icons.shield_rounded),
              ])
                FadeSlideIn(
                  child: ActionChip(
                    avatar: Icon(entry.$3, size: 16),
                    label: Text(entry.$2),
                    onPressed: () => context.go(entry.$1),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  _slips == 0
                      ? 'Recent activity'
                      : 'Recent activity · $_slips slips',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
              TextButton(
                onPressed: () => context.go('/activity'),
                child: const Text('See all'),
              ),
            ],
          ),
          if (_activity.isEmpty)
            const EmptyPane(
              title: 'No rows yet',
              body: 'A confirmed payment will land here.',
            )
          else
            for (final item in _activity.take(4)) _ActivityTile(txn: item),
          if (_coach != null && _coach!.warnings.isNotEmpty) ...[
            const SizedBox(height: 8),
            GlassCard(
              onTap: () => context.go('/coach'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Coach insight',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(_coach!.warnings.first),
                ],
              ),
            ),
          ],
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => _safety(context),
              child: const Text('PIN and safety'),
            ),
          ),
        ],
      ),
    );
  }

  void _safety(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => const Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 28),
        child: Text(
          'Sign-in is not the payment PIN. The demo PIN is 2580, and it is sent only when you confirm a pending transfer. Coach, scam check, voice interpret, and onboarding never receive it.',
        ),
      ),
    );
  }

  void _gap(BuildContext context, String name) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$name is a booth action in this prototype. The mobile book can send, pay a merchant, or buy airtime.',
        ),
      ),
    );
  }
}

class _CurrencyToggle extends StatelessWidget {
  const _CurrencyToggle({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      decoration: BoxDecoration(
        color: palette.highContrast
            ? Colors.black
            : Colors.white.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          for (final code in ['USD', 'ZIG'])
            GestureDetector(
              onTap: () => onChanged(code),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: value == code
                      ? (palette.highContrast ? palette.orange : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  code == 'ZIG' ? 'ZiG' : 'USD',
                  style: TextStyle(
                    color: value == code
                        ? (palette.highContrast ? Colors.black : palette.forest)
                        : Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DeltaChip extends StatelessWidget {
  const _DeltaChip(this.label, {required this.positive});

  final String label;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final color = positive ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Pressable(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
          ),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.txn});
  final Txn txn;

  @override
  Widget build(BuildContext context) {
    final outgoing = txn.outgoing ?? true;
    final amountColor = outgoing ? const Color(0xFFFDA4AF) : const Color(0xFF6EE7B7);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        navy: true,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white.withValues(alpha: 0.16),
              child: Text(
                txn.initials ?? '•',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    txn.title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    _when(txn.createdAt),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${outgoing ? '−' : '+'} ${txn.display}',
              style: TextStyle(fontWeight: FontWeight.w800, color: amountColor),
            ),
          ],
        ),
      ),
    );
  }
}

String _when(String iso) {
  final time = DateTime.tryParse(iso);
  if (time == null) return '';
  final delta = DateTime.now().toUtc().difference(time.toUtc());
  if (delta.inMinutes < 1) return 'Just now';
  if (delta.inHours < 1) return '${delta.inMinutes}m ago';
  if (delta.inHours < 24) return '${delta.inHours}h ago';
  if (delta.inDays < 14) return '${delta.inDays}d ago';
  return DateFormat('d MMM').format(time.toLocal());
}
