import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../core/models/models.dart';
import '../core/session/session.dart';
import '../core/theme/shamwari_theme.dart';
import '../widgets/charts.dart';
import '../widgets/glass_card.dart';
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
    final palette = context.palette;
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

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
        children: [
          Text(
            'Welcome, $first! here’s your money snapshot for today',
            style: const TextStyle(
              fontSize: 28,
              height: 1.15,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Today is ${DateFormat('d MMMM y').format(DateTime.now())}',
            style: TextStyle(color: context.inkMuted, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text('Mhoro · $hello', style: TextStyle(color: palette.faint)),
          const SizedBox(height: 14),
          GlassCard(
            radius: 999,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            onTap: () => context.go('/search'),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: palette.highContrast ? Colors.black : Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.search_rounded,
                    size: 18,
                    color: palette.highContrast ? context.ink : palette.forest,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Search the book',
                  style: TextStyle(color: palette.onCardMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(
                child: Text(
                  "Today's stats",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
              TextButton(
                onPressed: () => context.go('/activity'),
                style: TextButton.styleFrom(
                  foregroundColor: context.ink,
                  textStyle: const TextStyle(fontWeight: FontWeight.w800),
                ),
                child: const Text('View more'),
              ),
            ],
          ),
          SizedBox(
            height: 168,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _StatCard(
                  label: 'Spent',
                  value: wallet.week.display,
                  chip: wallet.week.deltaPct == null
                      ? 'No prior week'
                      : '+${wallet.week.deltaPct}%',
                  progress: (wallet.week.totalCents / 8000).clamp(0, 1),
                  accent: true,
                ),
                _StatCard(
                  label: 'Saved',
                  value: wallet.goal?.displaySaved ?? '—',
                  chip: wallet.goal?.name ?? 'No goal',
                  progress: wallet.goal?.progress ?? 0,
                ),
                _StatCard(
                  label: 'Airtime',
                  value: airtimeShare == null
                      ? '—'
                      : '${(airtimeShare.share * 100).round()}%',
                  chip: airtimeShare?.display ?? 'Open coach',
                  progress: airtimeShare?.share ?? 0,
                ),
                _StatCard(
                  label: 'Coach',
                  value: '${_coach?.warnings.length ?? 0}',
                  chip: 'Tips',
                  progress: ((_coach?.warnings.length ?? 0) / 4).clamp(0, 1),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          GlassCard(
            radius: 30,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${wallet.customer.city} · ${wallet.customer.role}',
                        style: TextStyle(
                          color: palette.onCardMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    _CurrencyToggle(
                      value: _currency,
                      onChanged: (value) => setState(() => _currency = value),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  selected.displayBalance,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                  ),
                ),
                Text(
                  'Available ${selected.displayAvailable}',
                  style: TextStyle(color: palette.onCardMuted),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton(
                      onPressed: () => context.go('/send'),
                      child: const Text('Send'),
                    ),
                    _Pill(
                      'Pay',
                      Icons.storefront_rounded,
                      () => context.go('/send'),
                    ),
                    _Pill(
                      'Top-up',
                      Icons.add_card_rounded,
                      () => _gap(context, 'Top-up'),
                    ),
                    _Pill(
                      'Request',
                      Icons.call_received_rounded,
                      () => _gap(context, 'Request'),
                    ),
                    TextButton(
                      onPressed: () => _safety(context),
                      child: const Text('PIN and safety'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text(
                'Spending',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: palette.highContrast ? Colors.black : Colors.white,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'This Week',
                  style: TextStyle(
                    color: palette.highContrast ? context.ink : palette.forest,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GlassCard(child: WeekBars(days: wallet.week.days)),
          const SizedBox(height: 12),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  wallet.goal?.name ?? 'This week',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  'The marker sits on the peak day.',
                  style: TextStyle(color: palette.onCardMuted, fontSize: 12),
                ),
                const SizedBox(height: 8),
                WeekWave(days: wallet.week.days),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Recent activity · $_slips slips',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => context.go('/activity'),
                style: TextButton.styleFrom(
                  foregroundColor: context.ink,
                  textStyle: const TextStyle(fontWeight: FontWeight.w800),
                ),
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
                  Text(
                    _coach!.warnings.first,
                    style: const TextStyle(height: 1.35),
                  ),
                ],
              ),
            ),
          ],
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
                        : palette.onCard,
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

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.chip,
    required this.progress,
    this.accent = false,
  });

  final String label;
  final String value;
  final String chip;
  final double progress;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final ring = palette.highContrast
        ? palette.orange
        : (accent ? palette.orange : palette.forest);
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: SizedBox(
        width: 148,
        child: GlassCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: palette.onCardMuted, fontSize: 12)),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: CustomPaint(
                      painter: _MiniRing(progress: progress, color: ring),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: palette.highContrast
                      ? Colors.black
                      : palette.forest.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  chip,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: palette.onCard,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniRing extends CustomPainter {
  _MiniRing({required this.progress, required this.color});
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    final rect = Offset.zero & size;
    canvas.drawArc(
      rect.deflate(4),
      -1.5708,
      6.2832,
      false,
      paint..color = color.withValues(alpha: 0.18),
    );
    canvas.drawArc(
      rect.deflate(4),
      -1.5708,
      6.2832 * progress.clamp(0, 1),
      false,
      paint..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _MiniRing oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

class _Pill extends StatelessWidget {
  const _Pill(this.label, this.icon, this.onTap);
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final foreground = palette.highContrast ? palette.orange : palette.forest;
    return Material(
      color: palette.highContrast ? Colors.black : Colors.white,
      elevation: palette.highContrast ? 0 : 2,
      shadowColor: const Color(0x400F3B33),
      shape: StadiumBorder(
        side: BorderSide(
          color: palette.highContrast
              ? palette.border
              : palette.forest.withValues(alpha: 0.16),
          width: palette.highContrast ? 2 : 1,
        ),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: foreground),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: foreground,
                  fontWeight: FontWeight.w800,
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: palette.orange.withValues(alpha: 0.15),
              child: Text(
                txn.initials ?? '•',
                style: TextStyle(
                  color: palette.orange,
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
                    style: TextStyle(color: context.inkMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            Text(
              '${outgoing ? '−' : '+'} ${txn.display}',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: outgoing ? palette.orange : palette.ok,
              ),
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
