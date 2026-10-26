import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/session/session.dart';
import '../core/theme/shamwari_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/states.dart';

class UssdScreen extends ConsumerStatefulWidget {
  const UssdScreen({super.key});

  @override
  ConsumerState<UssdScreen> createState() => _UssdScreenState();
}

class _UssdScreenState extends ConsumerState<UssdScreen> {
  final _input = TextEditingController();
  final _history = <String>[];
  String? _session;
  bool _open = true;
  bool _busy = false;
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _send(''));
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _send(String text) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final turn = await ref
          .read(shamwariApiProvider)
          .ussd(sessionId: _session, text: text);
      if (!mounted) return;
      setState(() {
        _session = turn.sessionId;
        if (text.trim().isNotEmpty) _history.add('> ${text.trim()}');
        _history.add(turn.message);
        _open = turn.continueSession;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
      children: [
        const SectionLabel('Channels'),
        Text('USSD *151#', style: Theme.of(context).textTheme.headlineMedium),
        Text(
          'A phone-style text menu. Payments still wait for a yes word and the PIN. The PIN is not printed back.',
          style: TextStyle(color: context.inkMuted, height: 1.35),
        ),
        const SizedBox(height: 14),
        if (_loading)
          const SkeletonColumn()
        else if (_error != null && _history.isEmpty)
          ErrorPane(error: _error!, onRetry: () => _send(''))
        else
          GlassCard(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: palette.highContrast ? Colors.black : palette.forest,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                _history.join('\n\n'),
                key: const Key('ussd-screen'),
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'monospace',
                  height: 1.4,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        const SizedBox(height: 12),
        if (!_open)
          FilledButton(
            onPressed: _busy
                ? null
                : () {
                    setState(() {
                      _history.clear();
                      _session = null;
                      _open = true;
                    });
                    _send('');
                  },
            child: const Text('Dial *151# again'),
          )
        else
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('ussd-text'),
                  controller: _input,
                  decoration: const InputDecoration(hintText: '1, 2, 3, 4, or 0'),
                  onSubmitted: _busy
                      ? null
                      : (value) {
                          _input.clear();
                          _send(value);
                        },
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                key: const Key('ussd-send'),
                onPressed: _busy
                    ? null
                    : () {
                        final text = _input.text;
                        _input.clear();
                        _send(text);
                      },
                child: const Text('Reply'),
              ),
            ],
          ),
      ],
    );
  }
}
