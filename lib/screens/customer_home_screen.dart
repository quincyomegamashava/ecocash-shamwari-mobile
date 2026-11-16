import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../core/layout.dart';
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
      // First paint: wallet + activity only. Coach/receipts enrich afterward.
      final results = await Future.wait([
        api.wallet(),
        api.activity(),
        Future<void>.delayed(pace),
      ]);
      if (!mounted) return;
      setState(() {
        _wallet = results[0] as WalletSnapshot;
        _activity = results[1] as List<Txn>;
        _loading = false;
      });
      unawaited(_loadExtras());
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  Future<void> _loadExtras() async {
    try {
      final api = ref.read(shamwariApiProvider);
      final results = await Future.wait([api.coach(), api.receipts()]);
      if (!mounted) return;
      setState(() {
        _coach = results[0] as CoachState;
        _slips = (results[1] as ReceiptBook).entries.length;
      });
    } catch (_) {
      // Secondary panes are optional for the home shell.
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
    final expanded = context.isExpanded;
    final sidePad = expanded ? 24.0 : 16.0;

    final greeting = <Widget>[
      Text(
        'Mhoro, $first',
        style: TextStyle(
          color: context.inkMuted,
          fontWeight: FontWeight.w700,
        ),
      ),
      Text(
        hello,
        style: TextStyle(
          fontSize: expanded ? 30 : 26,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
          height: 1.15,
        ),
      ),
    ];

    final walletCard = _WalletCard(
      selected: selected,
      wallet: wallet,
      currency: _currency,
      onCurrencyChanged: (value) => setState(() => _currency = value),
      delta: delta,
      goalName: goalName,
      airtimeShare: airtimeShare?.share,
      onSend: () => context.go('/send'),
      onTopUp: () => _gap(context, 'Top-up'),
      onWithdraw: () => _gap(context, 'Withdraw'),
    );

    final services = _ServicesGrid(columns: expanded ? 3 : 2);

    final activityPane = _ActivityPane(
      slips: _slips,
      activity: _activity,
      coach: _coach,
      onSeeAll: () => context.go('/activity'),
      onCoach: () => context.go('/coach'),
      onSafety: () => _safety(context),
    );

    return RefreshIndicator(
      onRefresh: _load,
      child: expanded
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(sidePad, 8, sidePad, 28),
              children: [
                ...greeting,
                const SizedBox(height: 18),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 11,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            walletCard,
                            const SizedBox(height: 22),
                            const Text(
                              'Services',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Quick tools in your wallet.',
                              style: TextStyle(
                                color: context.inkMuted,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 12),
                            services,
                          ],
                        ),
                      ),
                      const SizedBox(width: ShamwariBreakpoints.homePaneGap),
                      Expanded(flex: 9, child: activityPane),
                    ],
                  ),
                ),
              ],
            )
          : ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(sidePad, 8, sidePad, 28),
              children: [
                ...greeting,
                const SizedBox(height: 18),
                walletCard,
                const SizedBox(height: 22),
                const Text(
                  'Services',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  'Quick tools in your wallet.',
                  style: TextStyle(
                    color: context.inkMuted,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                services,
                const SizedBox(height: 22),
                activityPane,
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

class _WalletCard extends StatelessWidget {
  const _WalletCard({
    required this.selected,
    required this.wallet,
    required this.currency,
    required this.onCurrencyChanged,
    required this.delta,
    required this.goalName,
    required this.airtimeShare,
    required this.onSend,
    required this.onTopUp,
    required this.onWithdraw,
  });

  final Wallet selected;
  final WalletSnapshot wallet;
  final String currency;
  final ValueChanged<String> onCurrencyChanged;
  final num? delta;
  final String? goalName;
  final double? airtimeShare;
  final VoidCallback onSend;
  final VoidCallback onTopUp;
  final VoidCallback onWithdraw;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      navy: true,
      radius: 32,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 26,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.55),
                      Colors.white.withValues(alpha: 0.2),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              _CurrencyToggle(value: currency, onChanged: onCurrencyChanged),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Available balance',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xB3FFFFFF),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Hero(
            tag: 'shamwari-balance',
            child: Material(
              type: MaterialType.transparency,
              child: MoneyHero(selected.displayAvailable),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${wallet.customer.city} · ${wallet.customer.role}',
            style: const TextStyle(
              color: Color(0xB3FFFFFF),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FadeSlideIn(
                child: _DeltaChip(
                  delta == null ? 'No prior week' : '+$delta% this week',
                  positive: delta == null || delta! >= 0,
                ),
              ),
              if (goalName != null)
                FadeSlideIn(
                  index: 1,
                  child: _DeltaChip(goalName!, positive: true),
                ),
              if (airtimeShare != null)
                FadeSlideIn(
                  index: 2,
                  child: _DeltaChip(
                    'Airtime ${(airtimeShare! * 100).round()}%',
                    positive: true,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _QuickAction(
                icon: Icons.arrow_upward_rounded,
                label: 'Send',
                onTap: onSend,
              ),
              const SizedBox(width: 8),
              _QuickAction(
                icon: Icons.add_rounded,
                label: 'Top up',
                onTap: onTopUp,
              ),
              const SizedBox(width: 8),
              _QuickAction(
                icon: Icons.arrow_downward_rounded,
                label: 'Withdraw',
                onTap: onWithdraw,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ServicesGrid extends StatelessWidget {
  const _ServicesGrid({required this.columns});

  final int columns;

  static const _services = [
    ('/voice', 'Voice notes', 'Speak a payment', Icons.mic_rounded),
    ('/chat', 'Chat', 'Ask Shamwari', Icons.chat_bubble_outline_rounded),
    ('/ussd', 'USSD', 'Classic codes', Icons.dialpad_rounded),
    ('/coach', 'Coach', 'Spend smarter', Icons.auto_awesome_rounded),
    ('/scam', 'Scam check', 'Stay protected', Icons.shield_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gaps = 10.0 * (columns - 1);
        final tileWidth = (constraints.maxWidth - gaps) / columns;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (var i = 0; i < _services.length; i++)
              SizedBox(
                width: tileWidth,
                child: FadeSlideIn(
                  index: i,
                  child: _ServiceCard(
                    title: _services[i].$2,
                    body: _services[i].$3,
                    icon: _services[i].$4,
                    onTap: () => context.go(_services[i].$1),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ActivityPane extends StatelessWidget {
  const _ActivityPane({
    required this.slips,
    required this.activity,
    required this.coach,
    required this.onSeeAll,
    required this.onCoach,
    required this.onSafety,
  });

  final int slips;
  final List<Txn> activity;
  final CoachState? coach;
  final VoidCallback onSeeAll;
  final VoidCallback onCoach;
  final VoidCallback onSafety;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                slips == 0 ? 'Recent activity' : 'Recent activity · $slips slips',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            TextButton(onPressed: onSeeAll, child: const Text('See all')),
          ],
        ),
        if (activity.isEmpty)
          const EmptyPane(
            title: 'No rows yet',
            body: 'A confirmed payment will land here.',
          )
        else
          for (final item in activity.take(6)) _ActivityTile(txn: item),
        if (coach != null && coach!.warnings.isNotEmpty) ...[
          const SizedBox(height: 8),
          GlassCard(
            radius: 24,
            onTap: onCoach,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Coach insight',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(coach!.warnings.first),
              ],
            ),
          ),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: onSafety,
            child: const Text('PIN and safety'),
          ),
        ),
      ],
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.title,
    required this.body,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String body;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return GlassCard(
      radius: 24,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: palette.forest.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: palette.forest, size: 20),
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(
            body,
            style: TextStyle(
              color: palette.onCardMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
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
    final palette = context.palette;
    final outgoing = txn.outgoing ?? true;
    final amountColor = outgoing ? palette.danger : palette.ok;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        radius: 22,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: palette.forest.withValues(alpha: 0.1),
              child: Text(
                txn.initials ?? '•',
                style: TextStyle(
                  color: palette.forest,
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
                      color: palette.onCardMuted,
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
