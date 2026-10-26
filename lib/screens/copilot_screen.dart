import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/api/api_exception.dart';
import '../core/models/models.dart';
import '../core/session/session.dart';
import '../core/theme/shamwari_theme.dart';
import '../dev/capture_cue.dart';
import '../widgets/glass_card.dart';
import '../widgets/states.dart';

class CopilotScreen extends ConsumerStatefulWidget {
  const CopilotScreen({super.key, required this.itemId});

  final int itemId;

  @override
  ConsumerState<CopilotScreen> createState() => _CopilotScreenState();
}

class _CopilotScreenState extends ConsumerState<CopilotScreen> {
  final _reply = TextEditingController();
  CopilotCase? _case;
  bool _loading = true;
  bool _busy = false;
  Object? _error;
  String? _notice;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final pace = ref.read(loadPaceProvider);
      final opened = await ref.read(shamwariApiProvider).copilot(widget.itemId);
      await Future<void>.delayed(pace);
      if (!mounted) return;
      _reply.text = opened.suggestion.drafts.isEmpty
          ? ''
          : opened.suggestion.drafts.first;
      setState(() {
        _case = opened;
        _loading = false;
      });
      if (captureTourActive) {
        await WidgetsBinding.instance.endOfFrame;
        if (!mounted) return;
        await captureReveal(
          context,
          (element) => element.widget.key == const Key('copilot-approve'),
        );
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  Future<void> _decide(String action) async {
    setState(() {
      _busy = true;
      _notice = null;
    });
    try {
      final result = await ref
          .read(shamwariApiProvider)
          .decidePulse(widget.itemId, action: action, text: _reply.text);
      if (!mounted) return;
      setState(() => _notice = result.detail);
    } catch (error) {
      if (mounted) setState(() => _notice = friendlyError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    if (_loading) {
      return const Padding(padding: EdgeInsets.all(16), child: SkeletonColumn());
    }
    if (_error != null || _case == null) {
      return ErrorPane(error: _error ?? 'This case did not open.', onRetry: _load);
    }
    final item = _case!.item;
    final suggestion = _case!.suggestion;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
      children: [
        const SectionLabel('Copilot'),
        Text('A person approves the reply.', style: Theme.of(context).textTheme.headlineMedium),
        Text(
          suggestion.offline
              ? 'Draft only. Nothing reaches the customer until you approve, edit, or discard.'
              : 'Draft from ${suggestion.provider}. A person still decides.',
          style: TextStyle(color: context.inkMuted, height: 1.35),
        ),
        const SizedBox(height: 12),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${item.source} · ${item.region} · ${item.sentiment} · ${item.themeLabel}',
                style: TextStyle(
                  color: palette.teal,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text('Customer note', style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(item.text),
            ],
          ),
        ),
        const SizedBox(height: 10),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                suggestion.summary,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 6),
              Text(suggestion.contextText, style: TextStyle(color: context.inkMuted)),
              const SizedBox(height: 8),
              Text('Next action', style: TextStyle(color: palette.teal, fontWeight: FontWeight.w800)),
              Text(suggestion.nextAction),
              const SizedBox(height: 10),
              const Text('Drafts', style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              for (final draft in suggestion.drafts)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GlassCard(
                    onTap: () => setState(() => _reply.text = draft),
                    padding: const EdgeInsets.all(12),
                    child: Text(draft),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          key: const Key('copilot-reply'),
          controller: _reply,
          minLines: 3,
          maxLines: 6,
          decoration: const InputDecoration(labelText: 'Reply a person can edit'),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton(
              key: const Key('copilot-approve'),
              onPressed: _busy ? null : () => _decide('approve'),
              child: const Text('Approve & send'),
            ),
            OutlinedButton(
              key: const Key('copilot-edit'),
              onPressed: _busy ? null : () => _decide('edit'),
              child: const Text('Edit'),
            ),
            TextButton(
              key: const Key('copilot-discard'),
              onPressed: _busy ? null : () => _decide('discard'),
              child: Text('Discard', style: TextStyle(color: palette.danger)),
            ),
          ],
        ),
        if (_notice != null) ...[
          const SizedBox(height: 8),
          Text(_notice!, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
        TextButton(
          onPressed: () => context.go('/pulse'),
          child: const Text('Back to pulse'),
        ),
      ],
    );
  }
}
