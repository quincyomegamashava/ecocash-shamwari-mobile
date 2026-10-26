import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/models/models.dart';
import '../core/session/session.dart';
import '../core/theme/shamwari_theme.dart';
import '../widgets/charts.dart';
import '../widgets/glass_card.dart';
import '../widgets/motion.dart';
import '../widgets/states.dart';

class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  WalletSnapshot? _wallet;
  CoachState? _coach;
  bool _loading = true;
  Object? _error;

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
        api.coach(),
        Future<void>.delayed(pace),
      ]);
      if (!mounted) return;
      setState(() {
        _wallet = results[0] as WalletSnapshot;
        _coach = results[1] as CoachState;
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
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: SkeletonColumn(),
      );
    }
    if (_error != null || _wallet == null) {
      return ErrorPane(error: _error ?? 'Insights did not load.', onRetry: _load);
    }
    final wallet = _wallet!;
    final colors = [
      const Color(0xFF0E2A56),
      const Color(0xFF3D6FB5),
      const Color(0xFF7EB6FF),
      const Color(0xFF0B4F8A),
      const Color(0xFF9CC4FF),
    ];
    final categories = _coach?.categories ?? const <SpendCategory>[];
    final segments = <RingSegment>[];
    if (categories.isNotEmpty) {
      for (var i = 0; i < categories.length; i++) {
        segments.add(
          RingSegment(
            categories[i].label,
            categories[i].share <= 0 ? 0.05 : categories[i].share,
            colors[i % colors.length],
          ),
        );
      }
    } else {
      final days = wallet.week.days;
      final total = days.fold<int>(0, (sum, day) => sum + day.amountCents);
      for (var i = 0; i < days.length; i++) {
        segments.add(
          RingSegment(
            days[i].label,
            total == 0 ? 1 : days[i].amountCents.toDouble(),
            colors[i % colors.length],
          ),
        );
      }
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          const Text(
            'Insights',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
          ),
          Text(
            'Where this week went.',
            style: TextStyle(color: context.inkMuted),
          ),
          const SizedBox(height: 8),
          GlassCard(
            child: SpendRing(
              segments: segments,
              center: wallet.week.display,
              caption: 'Spent',
            ),
          ),
          const SizedBox(height: 12),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Spending',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(height: 8),
                WeekBars(days: wallet.week.days),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
