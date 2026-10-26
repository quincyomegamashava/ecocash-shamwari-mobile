import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/models/models.dart';
import '../core/session/session.dart';
import '../core/theme/shamwari_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/states.dart';

class AiLogScreen extends ConsumerStatefulWidget {
  const AiLogScreen({super.key});

  @override
  ConsumerState<AiLogScreen> createState() => _AiLogScreenState();
}

class _AiLogScreenState extends ConsumerState<AiLogScreen> {
  List<AiCall> _calls = const [];
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
      final calls = await ref.read(shamwariApiProvider).aiLog();
      await Future<void>.delayed(pace);
      if (!mounted) return;
      setState(() {
        _calls = calls;
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
          const SectionLabel('Model calls'),
          Text(
            'Metadata only.',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          Text(
            'The prompt text is never stored. A PIN does not belong in these rows.',
            style: TextStyle(color: context.inkMuted),
          ),
          const SizedBox(height: 12),
          if (_calls.isEmpty)
            const EmptyPane(
              title: 'No calls yet',
              body: 'Coach, scam, voice, and the buddy write a row when they run.',
            ),
          for (final call in _calls)
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
                            '${call.module} · ${call.operation}',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            '${call.provider} · ${call.promptChars} chars · ${call.latencyMs} ms',
                            style: TextStyle(
                              color: context.inkMuted,
                              fontSize: 12,
                            ),
                          ),
                          if (call.error.isNotEmpty)
                            Text(
                              call.error,
                              style: TextStyle(
                                color: palette.danger,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      call.status,
                      style: TextStyle(
                        color: call.status == 'ok'
                            ? palette.ok
                            : palette.danger,
                        fontWeight: FontWeight.w800,
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
