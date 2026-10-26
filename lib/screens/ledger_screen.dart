import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/models/models.dart';
import '../core/session/session.dart';
import '../core/theme/shamwari_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/states.dart';

class LedgerScreen extends ConsumerStatefulWidget {
  const LedgerScreen({super.key});

  @override
  ConsumerState<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends ConsumerState<LedgerScreen> {
  LedgerBook? _book;
  bool _loading = true;
  Object? _error;
  int _tab = 0;

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
      final book = await ref.read(shamwariApiProvider).ledger();
      await Future<void>.delayed(pace);
      if (!mounted) return;
      setState(() {
        _book = book;
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
    if (_error != null || _book == null) {
      return ErrorPane(
        error: _error ?? 'The ledger did not load.',
        onRetry: _load,
      );
    }
    final book = _book!;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
        children: [
          const SectionLabel('Care book'),
          Text(
            'Masked phones. No PIN hashes.',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 10),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('People')),
              ButtonSegment(value: 1, label: Text('Tills')),
              ButtonSegment(value: 2, label: Text('Book')),
            ],
            selected: {_tab},
            onSelectionChanged: (value) => setState(() => _tab = value.first),
          ),
          const SizedBox(height: 12),
          if (_tab == 0)
            for (final person in book.customers)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        person.profile.fullName,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        '${person.profile.city} · ${person.profile.role} · ${person.profile.phoneMasked}',
                        style: TextStyle(color: context.inkMuted, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        person.wallets
                            .map((wallet) => wallet.displayBalance)
                            .join('   '),
                      ),
                    ],
                  ),
                ),
              ),
          if (_tab == 1) ...[
            for (final merchant in book.merchants)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  merchant.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text('${merchant.category} · ${merchant.city}'),
              ),
            const Divider(),
            for (final agent in book.agents)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  agent.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text('${agent.booth} · ${agent.city}'),
              ),
          ],
          if (_tab == 2) ...[
            if (book.transactions.isEmpty)
              const EmptyPane(title: 'No rows', body: 'The book is quiet.'),
            for (final txn in book.transactions.take(20))
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  txn.counterparty,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text('${txn.reference} · ${txn.status}'),
                trailing: Text(
                  txn.display,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            if (book.receipts.isNotEmpty) ...[
              const SizedBox(height: 8),
              const SectionLabel('Tuckshop slips'),
              for (final slip in book.receipts)
                Text('${slip.vendor} · ${slip.display}'),
            ],
          ],
        ],
      ),
    );
  }
}
