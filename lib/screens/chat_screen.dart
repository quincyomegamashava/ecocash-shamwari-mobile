import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/session/session.dart';
import '../core/theme/shamwari_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/states.dart';

class ChatChannelScreen extends ConsumerStatefulWidget {
  const ChatChannelScreen({super.key});

  @override
  ConsumerState<ChatChannelScreen> createState() => _ChatChannelScreenState();
}

class _Line {
  _Line(this.text, this.mine);
  final String text;
  final bool mine;
}

class _ChatChannelScreenState extends ConsumerState<ChatChannelScreen> {
  final _input = TextEditingController();
  final _lines = <_Line>[];
  String? _session;
  bool _busy = false;
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _send('', opening: true));
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _send(String text, {bool opening = false}) async {
    setState(() {
      _busy = true;
      if (opening) _loading = true;
      _error = null;
    });
    try {
      final turn = await ref
          .read(shamwariApiProvider)
          .chat(sessionId: _session, text: text);
      if (!mounted) return;
      setState(() {
        _session = turn.sessionId;
        if (!opening && text.trim().isNotEmpty) _lines.add(_Line(text.trim(), true));
        _lines.add(_Line(turn.message, false));
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
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            children: [
              const SectionLabel('Channels'),
              Text(
                'Chat channel',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Text(
                'Same book as the wallet. A person still says yes and enters the PIN. Nothing here is a branded messenger.',
                style: TextStyle(color: context.inkMuted, height: 1.35),
              ),
              const SizedBox(height: 12),
              if (_loading)
                const SkeletonColumn()
              else if (_error != null && _lines.isEmpty)
                ErrorPane(
                  error: _error!,
                  onRetry: () => _send('', opening: true),
                )
              else
                for (final line in _lines)
                  Align(
                    alignment: line.mine
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      constraints: const BoxConstraints(maxWidth: 300),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: line.mine
                            ? palette.forest
                            : Colors.white.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        line.text,
                        style: TextStyle(
                          color: line.mine ? Colors.white : palette.onCard,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('chat-text'),
                  controller: _input,
                  decoration: const InputDecoration(
                    hintText: 'balance, or tumira \$5 kuna Tendai',
                  ),
                  onSubmitted: _busy
                      ? null
                      : (value) {
                          final text = value.trim();
                          if (text.isEmpty) return;
                          _input.clear();
                          _send(text);
                        },
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                key: const Key('chat-send'),
                onPressed: _busy
                    ? null
                    : () {
                        final text = _input.text.trim();
                        if (text.isEmpty) return;
                        _input.clear();
                        _send(text);
                      },
                child: const Text('Send'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
