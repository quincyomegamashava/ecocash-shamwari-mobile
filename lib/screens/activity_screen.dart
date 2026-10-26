import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/models/models.dart';
import '../core/session/session.dart';
import '../core/theme/shamwari_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/states.dart';

class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({super.key});

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen> {
  List<Txn> _rows = const [];
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
      final rows = await ref.read(shamwariApiProvider).transactions(limit: 30);
      await Future<void>.delayed(pace);
      if (!mounted) return;
      setState(() {
        _rows = rows;
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
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: SkeletonColumn(),
      );
    }
    if (_error != null) return ErrorPane(error: _error!, onRetry: _load);
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
        children: [
          const SectionLabel('Money'),
          Text('Activity', style: Theme.of(context).textTheme.headlineMedium),
          Text(
            'Newest first. Pending holds are not posted yet.',
            style: TextStyle(color: context.inkMuted),
          ),
          const SizedBox(height: 12),
          if (_rows.isEmpty)
            const EmptyPane(
              title: 'No transactions',
              body: 'Send money and confirm it to see a row.',
            ),
          for (final txn in _rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GlassCard(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            txn.counterparty,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            '${txn.reference} · ${txn.status} · ${txn.kind}',
                            style: TextStyle(
                              color: context.inkMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      txn.display,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: txn.status == 'pending'
                            ? palette.warning
                            : context.ink,
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
