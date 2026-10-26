import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/api/api_exception.dart';
import '../core/models/models.dart';
import '../core/session/session.dart';
import '../core/theme/shamwari_theme.dart';
import '../widgets/charts.dart';
import '../widgets/glass_card.dart';
import '../widgets/motion.dart';
import '../widgets/states.dart';

class PulseScreen extends ConsumerStatefulWidget {
  const PulseScreen({super.key});

  @override
  ConsumerState<PulseScreen> createState() => _PulseScreenState();
}

class _PulseScreenState extends ConsumerState<PulseScreen> {
  PulseSnapshot? _pulse;
  ImpactReport? _impact;
  String? _prose;
  bool _loading = true;
  bool _busy = false;
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
      final pace = ref.read(loadPaceProvider);
      final api = ref.read(shamwariApiProvider);
      final pulse = await api.pulse();
      final impact = await api.impact();
      await Future<void>.delayed(pace);
      if (!mounted) return;
      setState(() {
        _pulse = pulse;
        _impact = impact;
        _prose ??= pulse.points.join(' ');
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

  Future<void> _publish() async {
    setState(() => _busy = true);
    try {
      final published = await ref.read(shamwariApiProvider).publishPulse();
      final fresh = await ref.read(shamwariApiProvider).pulse();
      if (!mounted) return;
      setState(() => _pulse = fresh);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(published.item.text)));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(friendlyError(error))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _highlight() async {
    setState(() => _busy = true);
    try {
      final highlight = await ref.read(shamwariApiProvider).highlightPulse();
      if (!mounted) return;
      setState(() => _prose = highlight.prose);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(friendlyError(error))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: SkeletonColumn(),
      );
    }
    if (_error != null || _pulse == null) {
      return ErrorPane(error: _error ?? 'Pulse did not load.', onRetry: _load);
    }
    final pulse = _pulse!;
    final total = pulse.series.daily.fold<int>(
      0,
      (sum, day) => sum + day.total,
    );
    final negative = pulse.series.daily.fold<int>(
      0,
      (sum, day) => sum + day.negative,
    );
    final calm = total == 0 ? 0.0 : (total - negative) / total;
    final reversal = pulse.series.themes.where(
      (theme) => theme.label.toLowerCase().contains('reversal'),
    );
    final reversalCount = reversal.isEmpty ? 0 : reversal.first.count;
    final weekNegative = pulse.series.daily.length < 7
        ? negative
        : pulse.series.daily
              .sublist(pulse.series.daily.length - 7)
              .fold<int>(0, (sum, day) => sum + day.negative);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
        children: [
          const SectionLabel('Care desk'),
          Text(
            'Live customer pulse.',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          Text(
            'Harare, Bulawayo, Mutare and the other towns. Charts are drawn from the JSON series.',
            style: TextStyle(color: context.inkMuted),
          ),
          if (_impact != null) ...[
            const SizedBox(height: 12),
            _ImpactCard(report: _impact!),
          ],
          const SizedBox(height: 12),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HARARE · BUSIEST',
                  style: TextStyle(
                    color: palette.teal,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                Text(
                  '$total',
                  style: const TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                Text('Published notes', style: TextStyle(color: context.inkMuted)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    FilledButton(
                      onPressed: _busy ? null : _publish,
                      child: const Text('Open pulse'),
                    ),
                    OutlinedButton(
                      onPressed: _busy ? null : _highlight,
                      child: const Text('Rewrite the highlight'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _Stat(
                  label: 'Calm share',
                  value: '${(calm * 100).round()}%',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Stat(label: 'Reversal notes', value: '$reversalCount'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Stat(
                  label: 'Complaints, 7 days',
                  value: '$weekNegative',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionLabel('Executive highlight'),
                const SizedBox(height: 6),
                Text(
                  _prose ?? pulse.points.join('\n'),
                  style: const TextStyle(height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Messages per day',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
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
          Text(
            'The wave is everything published. Orange is the negative share.',
            style: TextStyle(color: context.inkMuted, fontSize: 12),
          ),
          const SizedBox(height: 6),
          GlassCard(child: PulseLine(daily: pulse.series.daily)),
          const SizedBox(height: 12),
          Text(
            'Volume by theme',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          GlassCard(child: ThemeBars(themes: pulse.series.themes)),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Sentiment by region',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              _Legend(color: palette.orange, label: 'Neg'),
              _Legend(color: palette.teal, label: 'Neu'),
              _Legend(color: palette.ok, label: 'Pos'),
            ],
          ),
          const SizedBox(height: 6),
          GlassCard(
            child: Column(
              children: [
                RegionBars(regions: pulse.series.regions),
                const SizedBox(height: 8),
                RingGauge(
                  progress: calm,
                  center: '${(calm * 100).round()}%',
                  caption: 'Calm',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text('Live feed', style: Theme.of(context).textTheme.titleMedium),
          if (pulse.feed.isEmpty)
            const EmptyPane(
              title: 'The feed is quiet',
              body: 'Publish the next synthetic note.',
            )
          else
            for (final item in pulse.feed)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: GlassCard(
                  key: Key('pulse-${item.id}'),
                  onTap: () => context.go('/pulse/case/${item.id}'),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${item.region} · ${item.themeLabel}',
                        style: TextStyle(
                          color: item.sentiment == 'negative'
                              ? palette.orange
                              : palette.teal,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(item.text),
                      const SizedBox(height: 6),
                      Text(
                        'Open copilot',
                        style: TextStyle(
                          color: palette.teal,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _ImpactCard extends StatelessWidget {
  const _ImpactCard({required this.report});

  final ImpactReport report;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      ('${report.timeSavedMinutes.total}', 'minutes saved', report.timeSavedMinutes.label),
      ('${report.ticketsDeflected.total}', 'tickets deflected', report.ticketsDeflected.label),
      ('${report.scamsBlocked.total}', 'scams blocked', report.scamsBlocked.label),
      ('${report.transfersViaAi.total}', 'AI transfers', report.transfersViaAi.label),
    ];
    return GlassCard(
      key: const Key('impact-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Impact this week',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ),
              if (report.simulated)
                Text(
                  'Simulated demo',
                  style: TextStyle(
                    color: context.inkMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tile in tiles)
                SizedBox(
                  width: 150,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CountUpText(
                          tile.$1,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tile.$2,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          tile.$3,
                          style: TextStyle(
                            color: context.inkMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            report.disclaimer,
            style: TextStyle(color: context.inkMuted, fontSize: 12, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          Text(
            label,
            style: TextStyle(color: context.inkMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 10)),
        ],
      ),
    );
  }
}
