import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/api_exception.dart';
import '../core/models/models.dart';
import '../core/session/session.dart';
import '../dev/capture_cue.dart';
import '../core/theme/shamwari_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/states.dart';

class CoachScreen extends ConsumerStatefulWidget {
  const CoachScreen({super.key});

  @override
  ConsumerState<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends ConsumerState<CoachScreen> {
  final _text = TextEditingController();
  CoachState? _state;
  bool _loading = true;
  bool _busy = false;
  Object? _error;
  String? _note;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final pace = ref.read(loadPaceProvider);
      final state = await ref.read(shamwariApiProvider).coach();
      await Future<void>.delayed(pace);
      if (!mounted) return;
      setState(() {
        _state = state;
        _loading = false;
      });
      if (captureTourActive && CaptureCue.phase.value == 'coach') {
        await _send('Can I still make my school fees goal?');
        if (!mounted) return;
        await WidgetsBinding.instance.endOfFrame;
        if (!mounted) return;
        await captureReveal(context, (element) {
          final widget = element.widget;
          return widget is Text &&
              (widget.data?.contains('straight-line') ?? false);
        });
        CaptureCue.phase.value = 'coach-ready';
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  Future<void> _send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    setState(() => _busy = true);
    try {
      final reply = await ref.read(shamwariApiProvider).coachSend(trimmed);
      if (!mounted) return;
      _text.clear();
      setState(() {
        _note = reply.note.isEmpty ? null : reply.note;
        _state = CoachState(
          suggestions: _state?.suggestions ?? const [],
          warnings: _state?.warnings ?? const [],
          categories: _state?.categories ?? const [],
          goal: _state?.goal,
          messages: reply.messages,
        );
      });
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
    if (_error != null || _state == null) {
      return ErrorPane(error: _error ?? 'Coach did not load.', onRetry: _load);
    }
    final state = _state!;
    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              children: [
                const SectionLabel('Grow'),
                Text(
                  'A coach inside the book.',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                Text(
                  'Figures are counted here. The reply only phrases them.',
                  style: TextStyle(color: context.inkMuted),
                ),
                const SizedBox(height: 12),
                for (final warning in state.warnings)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GlassCard(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        warning,
                        style: const TextStyle(height: 1.35),
                      ),
                    ),
                  ),
                const SizedBox(height: 4),
                for (final category in state.categories)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 88,
                          child: Text(
                            category.label,
                            style: TextStyle(
                              color: context.inkMuted,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: LinearProgressIndicator(
                              value: category.share.clamp(0, 1),
                              minHeight: 8,
                              backgroundColor: palette.border,
                              color: category.key == 'airtime'
                                  ? palette.orange
                                  : palette.teal,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          category.display,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final suggestion in state.suggestions)
                      ActionChip(
                        label: Text(suggestion),
                        onPressed: _busy ? null : () => _send(suggestion),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                for (final message in state.messages) _Bubble(message: message),
                if (state.messages.isEmpty)
                  const EmptyPane(
                    title: 'The thread is quiet',
                    body: 'Ask about school fees or airtime.',
                  ),
              ],
            ),
          ),
        ),
        if (_note != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _note!,
              style: TextStyle(color: palette.warning, fontSize: 12),
            ),
          ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('coach-text'),
                    controller: _text,
                    decoration: const InputDecoration(
                      hintText: 'Ask about the book',
                    ),
                    onSubmitted: _busy ? null : _send,
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _busy ? null : () => _send(_text.text),
                  child: const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});
  final CoachMessage message;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final mine = message.fromUser;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: mine
              ? (palette.highContrast ? palette.orange : palette.forest)
              : (palette.lightGlass
                    ? Colors.white.withValues(alpha: 0.62)
                    : Colors.white.withValues(alpha: 0.12)),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(mine ? 18 : 4),
            bottomRight: Radius.circular(mine ? 4 : 18),
          ),
          border: Border.all(
            color: mine
                ? Colors.transparent
                : Colors.white.withValues(alpha: palette.highContrast ? 0 : 0.45),
          ),
        ),
        child: Text(
          message.content,
          style: TextStyle(
            color: mine
                ? (palette.highContrast ? Colors.black : Colors.white)
                : palette.onCard,
            height: 1.35,
          ),
        ),
      ),
    );
  }
}
