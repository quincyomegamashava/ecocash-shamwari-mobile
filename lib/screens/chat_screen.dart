import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/session/session.dart';
import '../widgets/mark.dart';
import '../widgets/motion.dart';
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
  final _scroll = ScrollController();
  final _lines = <_Line>[];
  String? _session;
  String? _greeting;
  bool _busy = false;
  bool _loading = true;
  bool _voiceOpen = false;
  Object? _error;

  static const _chips = <(IconData, String, String)>[
    (Icons.account_balance_wallet_outlined, 'Balance', 'What is my balance?'),
    (Icons.arrow_upward_rounded, 'Send money', 'tumira \$5 kuna Tendai'),
    (Icons.phone_android_rounded, 'Airtime', 'Buy \$2 airtime'),
    (Icons.auto_awesome_rounded, 'Coach', 'Where is my airtime money going?'),
    (Icons.shield_outlined, 'Scam check', 'Is this payment safe?'),
    (Icons.school_outlined, 'School fees', 'Help me plan school fees'),
  ];

  @override
  void initState() {
    super.initState();
    _input.addListener(() => setState(() {}));
    Future.microtask(() => _send('', opening: true));
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
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
        if (opening) {
          _greeting = turn.message;
        } else {
          if (text.trim().isNotEmpty) _lines.add(_Line(text.trim(), true));
          _lines.add(_Line(turn.message, false));
        }
        _loading = false;
      });
      if (!opening) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_scroll.hasClients) return;
          _scroll.animateTo(
            _scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
          );
        });
      }
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

  void _submit([String? forced]) {
    if (_busy) return;
    final text = (forced ?? _input.text).trim();
    if (text.isEmpty) return;
    _input.clear();
    _send(text);
  }

  @override
  Widget build(BuildContext context) {
    if (_voiceOpen) {
      return _VoiceSession(
        onClose: () => setState(() => _voiceOpen = false),
        onHeard: (phrase) {
          setState(() => _voiceOpen = false);
          _submit(phrase);
        },
      );
    }

    final empty = _lines.isEmpty;
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF071628),
            Color(0xFF0C2344),
            Color(0xFF102C58),
          ],
        ),
      ),
      child: Column(
        children: [
          const _ChatHeader(),
          Expanded(
            child: _loading && empty
                ? const Center(child: SkeletonColumn())
                : _error != null && empty
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: ErrorPane(
                      error: _error!,
                      onRetry: () => _send('', opening: true),
                    ),
                  )
                : empty
                ? _EmptyHero(greeting: _greeting)
                : _Transcript(lines: _lines, controller: _scroll),
          ),
          if (empty && !_loading && _error == null)
            _SuggestionRow(
              chips: _chips,
              onTap: _busy ? null : _submit,
            ),
          _Composer(
            controller: _input,
            busy: _busy,
            hasText: _input.text.trim().isNotEmpty,
            onSend: _submit,
            onVoice: () => setState(() => _voiceOpen = true),
            onAttach: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Attach a slip or photo in the next build. For now use text or voice.',
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          const ShamwariMark(size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome, color: Color(0xFF7EB6FF), size: 16),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Shamwari · EcoCash AI',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          _RoundIcon(
            icon: Icons.notifications_none_rounded,
            onTap: () => context.go('/activity'),
          ),
          const SizedBox(width: 8),
          _RoundIcon(
            icon: Icons.menu_rounded,
            onTap: () => Scaffold.of(context).openEndDrawer(),
          ),
        ],
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.08),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: Colors.white70, size: 20),
        ),
      ),
    );
  }
}

class _EmptyHero extends StatelessWidget {
  const _EmptyHero({required this.greeting});
  final String? greeting;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final orb = math.min(240.0, constraints.maxWidth * 0.62);
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FadeSlideIn(child: _EcoOrb(size: orb)),
                const SizedBox(height: 28),
                const FadeSlideIn(
                  index: 1,
                  child: Text(
                    "Hi, I'm Shamwari!\nHow can I help you today?",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                    ),
                  ),
                ),
                if (greeting != null) ...[
                  const SizedBox(height: 12),
                  FadeSlideIn(
                    index: 2,
                    child: Text(
                      greeting!,
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.62),
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Transcript extends StatelessWidget {
  const _Transcript({required this.lines, required this.controller});
  final List<_Line> lines;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: lines.length,
      itemBuilder: (context, index) {
        final line = lines[index];
        return Align(
          alignment: line.mine ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            constraints: BoxConstraints(
              maxWidth: math.min(340, MediaQuery.sizeOf(context).width * 0.82),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              gradient: line.mine
                  ? const LinearGradient(
                      colors: [Color(0xFF1A5BB8), Color(0xFF0E2A56)],
                    )
                  : null,
              color: line.mine ? null : Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(line.mine ? 20 : 6),
                bottomRight: Radius.circular(line.mine ? 6 : 20),
              ),
              border: line.mine
                  ? null
                  : Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Text(
              line.text,
              style: const TextStyle(
                color: Colors.white,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SuggestionRow extends StatelessWidget {
  const _SuggestionRow({required this.chips, required this.onTap});
  final List<(IconData, String, String)> chips;
  final ValueChanged<String>? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        itemCount: chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final chip = chips[index];
          return Material(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: onTap == null ? null : () => onTap!(chip.$3),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Icon(chip.$1, size: 16, color: const Color(0xFF9CC4FF)),
                    const SizedBox(width: 8),
                    Text(
                      chip.$2,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.busy,
    required this.hasText,
    required this.onSend,
    required this.onVoice,
    required this.onAttach,
  });

  final TextEditingController controller;
  final bool busy;
  final bool hasText;
  final VoidCallback onSend;
  final VoidCallback onVoice;
  final VoidCallback onAttach;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
        child: Row(
          children: [
            _RoundIcon(icon: Icons.add_rounded, onTap: onAttach),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.14),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: const Key('chat-text'),
                        controller: controller,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        cursorColor: const Color(0xFF7EB6FF),
                        textInputAction: TextInputAction.send,
                        onSubmitted: busy || !hasText ? null : (_) => onSend(),
                        decoration: InputDecoration(
                          hintText: 'Message Shamwari…',
                          hintStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.45),
                            fontWeight: FontWeight.w600,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: onAttach,
                      icon: Icon(
                        Icons.photo_camera_outlined,
                        color: Colors.white.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            _MicSendButton(
              key: const Key('chat-send'),
              busy: busy,
              sendMode: hasText,
              onPressed: busy
                  ? null
                  : hasText
                  ? onSend
                  : onVoice,
            ),
          ],
        ),
      ),
    );
  }
}

class _MicSendButton extends StatelessWidget {
  const _MicSendButton({
    super.key,
    required this.busy,
    required this.sendMode,
    required this.onPressed,
  });

  final bool busy;
  final bool sendMode;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Ink(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: busy
                  ? const [Color(0xFF3A557A), Color(0xFF243B5C)]
                  : const [Color(0xFF3D8BFF), Color(0xFF0E2A56)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2F6FED).withValues(alpha: 0.45),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            sendMode ? Icons.arrow_upward_rounded : Icons.mic_rounded,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _EcoOrb extends StatefulWidget {
  const _EcoOrb({required this.size});
  final double size;

  @override
  State<_EcoOrb> createState() => _EcoOrbState();
}

class _EcoOrbState extends State<_EcoOrb> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (reduceMotion(context)) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: CustomPaint(painter: _OrbPainter(t: 0.35)),
      );
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(painter: _OrbPainter(t: _controller.value)),
        );
      },
    );
  }
}

class _OrbPainter extends CustomPainter {
  _OrbPainter({required this.t});
  final double t;

  static const _palette = [
    Color(0xFF7EB6FF),
    Color(0xFF2F6FED),
    Color(0xFF0E2A56),
    Color(0xFF9CC4FF),
    Color(0xFFE11D48),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.42;
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF2F6FED).withValues(alpha: 0.35),
          const Color(0xFF0E2A56).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.35));
    canvas.drawCircle(center, radius * 1.35, glow);

    final rnd = math.Random(42);
    for (var i = 0; i < 160; i++) {
      final lat = (rnd.nextDouble() * math.pi) - (math.pi / 2);
      final lon = rnd.nextDouble() * math.pi * 2 + t * math.pi * 2;
      final wobble = 0.92 + 0.08 * math.sin(t * math.pi * 2 + i);
      final x = center.dx + radius * wobble * math.cos(lat) * math.cos(lon);
      final y = center.dy + radius * wobble * math.sin(lat);
      final depth = (math.cos(lat) * math.sin(lon) + 1) / 2;
      final paint = Paint()
        ..color = _palette[i % _palette.length].withValues(
          alpha: 0.25 + depth * 0.7,
        );
      canvas.drawCircle(Offset(x, y), 1.2 + depth * 2.2, paint);
    }

    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0xFF7EB6FF).withValues(alpha: 0.28);
    canvas.drawCircle(center, radius * 0.98, ring);
  }

  @override
  bool shouldRepaint(covariant _OrbPainter oldDelegate) => oldDelegate.t != t;
}

class _VoiceSession extends StatefulWidget {
  const _VoiceSession({required this.onClose, required this.onHeard});
  final VoidCallback onClose;
  final ValueChanged<String> onHeard;

  @override
  State<_VoiceSession> createState() => _VoiceSessionState();
}

class _VoiceSessionState extends State<_VoiceSession>
    with TickerProviderStateMixin {
  late final AnimationController _wave = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();
  final _started = DateTime.now();
  bool _paused = false;

  @override
  void dispose() {
    _wave.dispose();
    _pulse.dispose();
    super.dispose();
  }

  String get _clock {
    final elapsed = DateTime.now().difference(_started);
    final m = elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _finish() {
    HapticFeedback.lightImpact();
    widget.onHeard('What is my balance?');
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF050E1C),
            Color(0xFF0A1C38),
            Color(0xFF143A7A),
            Color(0xFF1A5BB8),
          ],
          stops: [0, 0.35, 0.78, 1],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: widget.onClose,
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.more_horiz_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 88,
              width: double.infinity,
              child: reduceMotion(context)
                  ? CustomPaint(painter: _WavePainter(t: 0.4))
                  : AnimatedBuilder(
                      animation: _wave,
                      builder: (context, _) =>
                          CustomPaint(painter: _WavePainter(t: _wave.value)),
                    ),
            ),
            const Spacer(),
            StreamBuilder(
              stream: Stream<void>.periodic(const Duration(seconds: 1)),
              builder: (context, _) => Text(
                _clock,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _paused ? 'Paused' : 'Listening…',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _VoiceSideButton(
                    icon: _paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                    onTap: () {
                      setState(() {
                        _paused = !_paused;
                        if (_paused) {
                          _wave.stop();
                          _pulse.stop();
                        } else {
                          _wave.repeat();
                          _pulse.repeat();
                        }
                      });
                    },
                  ),
                  AnimatedBuilder(
                    animation: _pulse,
                    builder: (context, child) {
                      final scale = reduceMotion(context)
                          ? 1.0
                          : 1 + (_pulse.value * 0.08);
                      return Transform.scale(
                        scale: scale,
                        child: child,
                      );
                    },
                    child: GestureDetector(
                      onTap: _finish,
                      child: Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF3D8BFF), Color(0xFF0E2A56)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2F6FED).withValues(alpha: 0.55),
                              blurRadius: 28,
                              spreadRadius: 4,
                            ),
                          ],
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.35),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.mic_rounded,
                          color: Colors.white,
                          size: 34,
                        ),
                      ),
                    ),
                  ),
                  _VoiceSideButton(
                    icon: Icons.close_rounded,
                    onTap: widget.onClose,
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

class _VoiceSideButton extends StatelessWidget {
  const _VoiceSideButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.12),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 52,
          height: 52,
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  _WavePainter({required this.t});
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    for (var layer = 0; layer < 3; layer++) {
      final path = Path();
      final amp = 10.0 + layer * 8;
      final phase = t * math.pi * 2 + layer * 0.8;
      for (var x = 0.0; x <= size.width; x += 4) {
        final y =
            size.height / 2 +
            math.sin((x / size.width) * math.pi * 4 + phase) * amp;
        if (x == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      paint.color = [
        const Color(0xFF9CC4FF),
        const Color(0xFF2F6FED),
        const Color(0xFFE11D48),
      ][layer].withValues(alpha: 0.85 - layer * 0.2);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) => oldDelegate.t != t;
}
