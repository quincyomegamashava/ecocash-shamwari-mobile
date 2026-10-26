import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/models/models.dart';
import '../core/session/session.dart';
import '../core/theme/shamwari_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/states.dart';

class AuditScreen extends ConsumerStatefulWidget {
  const AuditScreen({super.key});

  @override
  ConsumerState<AuditScreen> createState() => _AuditScreenState();
}

class _AuditScreenState extends ConsumerState<AuditScreen> {
  List<AuditEntry>? _rows;
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
      final rows = await ref.read(shamwariApiProvider).audit();
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
      return const Padding(padding: EdgeInsets.all(16), child: SkeletonColumn());
    }
    if (_error != null || _rows == null) {
      return ErrorPane(error: _error ?? 'The audit log did not load.', onRetry: _load);
    }
    final rows = _rows!;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
        children: [
          const SectionLabel('Team'),
          Text('Audit log', style: Theme.of(context).textTheme.headlineMedium),
          Text(
            'Newest first. Approvals, edits, discards, and risk decisions. No PIN and no prompt text.',
            style: TextStyle(color: context.inkMuted, height: 1.35),
          ),
          const SizedBox(height: 12),
          if (rows.isEmpty)
            const EmptyPane(
              title: 'No decisions yet',
              body: 'Open a pulse case and approve, edit, or discard a draft. The row lands here.',
            )
          else
            for (final row in rows)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GlassCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${row.module} · ${row.action}',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${row.actorName} · ${row.createdAt}',
                        style: TextStyle(color: context.inkMuted, fontSize: 12),
                      ),
                      if (row.detail.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(row.detail),
                      ],
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
