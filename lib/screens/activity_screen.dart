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
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: SkeletonColumn(),
      );
    }
    if (_error != null) return ErrorPane(error: _error!, onRetry: _load);
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
        itemCount: _rows.isEmpty ? 1 : _rows.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionLabel('Money'),
                Text(
                  'History',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
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
              ],
            );
          }
          return _HistoryCard(txn: _rows[index - 1]);
        },
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.txn});

  final Txn txn;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final sent = txn.outgoing != false && txn.kind != 'cash_in';
    final when = txn.createdAt.replaceFirst('T', ' ').replaceFirst('Z', '');
    final tone = txn.status == 'pending'
        ? palette.warning
        : sent
        ? palette.danger
        : palette.ok;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(14, 8, 16, 8),
                  decoration: BoxDecoration(
                    color: palette.highContrast ? Colors.black : palette.forest,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(28),
                      bottomRight: Radius.circular(18),
                    ),
                  ),
                  child: Text(
                    sent ? 'Sent' : 'Received',
                    style: TextStyle(
                      color: palette.highContrast ? palette.orange : Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: Text(
                    when,
                    style: TextStyle(
                      color: context.inkMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: palette.forest.withValues(alpha: 0.1),
                    child: Text(
                      txn.initials ?? txn.counterparty.characters.first,
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
                          txn.counterparty,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          '${txn.reference} · ${txn.status}',
                          style: TextStyle(color: context.inkMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    txn.display,
                    style: TextStyle(fontWeight: FontWeight.w800, color: tone),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
