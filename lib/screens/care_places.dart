import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/models/models.dart';
import '../core/session/session.dart';
import '../core/theme/shamwari_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/motion.dart';
import '../widgets/states.dart';

class QueueScreen extends ConsumerStatefulWidget {
  const QueueScreen({super.key});

  @override
  ConsumerState<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends ConsumerState<QueueScreen> {
  PulseSnapshot? _pulse;
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
      final pace = ref.read(loadPaceProvider);
      final pulse = await ref.read(shamwariApiProvider).pulse();
      await Future<void>.delayed(pace);
      if (!mounted) return;
      setState(() {
        _pulse = pulse;
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
      return const Padding(padding: EdgeInsets.all(16), child: SkeletonColumn());
    }
    if (_error != null || _pulse == null) {
      return ErrorPane(error: _error ?? 'The queue did not load.', onRetry: _load);
    }
    final feed = _pulse!.feed;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          const Text(
            'Queue',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
          ),
          Text(
            'Open a note to draft a reply.',
            style: TextStyle(color: context.inkMuted),
          ),
          const SizedBox(height: 12),
          if (feed.isEmpty)
            const EmptyPane(
              title: 'Queue is clear',
              body: 'Published notes will land here.',
            ),
          for (final item in feed) _CaseRow(item: item),
        ],
      ),
    );
  }
}

class CopilotHubScreen extends ConsumerStatefulWidget {
  const CopilotHubScreen({super.key});

  @override
  ConsumerState<CopilotHubScreen> createState() => _CopilotHubScreenState();
}

class _CopilotHubScreenState extends ConsumerState<CopilotHubScreen> {
  PulseSnapshot? _pulse;
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
      final pace = ref.read(loadPaceProvider);
      final pulse = await ref.read(shamwariApiProvider).pulse();
      await Future<void>.delayed(pace);
      if (!mounted) return;
      setState(() {
        _pulse = pulse;
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
      return const Padding(padding: EdgeInsets.all(16), child: SkeletonColumn());
    }
    if (_error != null || _pulse == null) {
      return ErrorPane(error: _error ?? 'Copilot did not load.', onRetry: _load);
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          const Text(
            'Copilot',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
          ),
          Text(
            'Pick a case. Nothing is sent until you approve it.',
            style: TextStyle(color: context.inkMuted),
          ),
          const SizedBox(height: 12),
          for (final item in _pulse!.feed) _CaseRow(item: item),
        ],
      ),
    );
  }
}

class ImpactScreen extends ConsumerStatefulWidget {
  const ImpactScreen({super.key});

  @override
  ConsumerState<ImpactScreen> createState() => _ImpactScreenState();
}

class _ImpactScreenState extends ConsumerState<ImpactScreen> {
  ImpactReport? _report;
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
      final pace = ref.read(loadPaceProvider);
      final report = await ref.read(shamwariApiProvider).impact();
      await Future<void>.delayed(pace);
      if (!mounted) return;
      setState(() {
        _report = report;
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
      return const Padding(padding: EdgeInsets.all(16), child: SkeletonColumn());
    }
    if (_error != null || _report == null) {
      return ErrorPane(error: _error ?? 'Impact did not load.', onRetry: _load);
    }
    final report = _report!;
    final tiles = [
      (report.timeSavedMinutes, 'minutes saved'),
      (report.ticketsDeflected, 'tickets deflected'),
      (report.scamsBlocked, 'scams blocked'),
      (report.transfersViaAi, 'AI transfers'),
    ];
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          const Text(
            'Impact',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          GlassCard(
            navy: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'This week',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(height: 12),
                for (final tile in tiles)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Expanded(child: Text(tile.$2)),
                        CountUpText(
                          '${tile.$1.total}',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                Text(
                  report.disclaimer,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CaseRow extends StatelessWidget {
  const _CaseRow({required this.item});

  final PulseItem item;

  @override
  Widget build(BuildContext context) {
    final letter = item.region.isEmpty ? '•' : item.region[0];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        navy: true,
        onTap: () => context.go('/pulse/case/${item.id}'),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white.withValues(alpha: 0.16),
              child: Text(
                letter,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.themeLabel,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    item.text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
