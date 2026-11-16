import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

bool reduceMotion(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context);

class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool value) {
    if (reduceMotion(context)) return;
    setState(() => _down = value);
  }

  @override
  Widget build(BuildContext context) {
    final scale = _down ? 0.96 : 1.0;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.onTap == null ? null : (_) => _set(true),
      onTapCancel: () => _set(false),
      onTapUp: widget.onTap == null ? null : (_) => _set(false),
      onTap: widget.onTap == null
          ? null
          : () {
              HapticFeedback.lightImpact();
              widget.onTap!();
            },
      child: AnimatedScale(
        scale: scale,
        duration: reduceMotion(context)
            ? Duration.zero
            : const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Counts a money or integer string up, then settles on the exact source text.
class CountUpText extends StatefulWidget {
  const CountUpText(
    this.text, {
    super.key,
    this.style,
    this.duration = const Duration(milliseconds: 420),
  });

  final String text;
  final TextStyle? style;
  final Duration duration;

  @override
  State<CountUpText> createState() => _CountUpTextState();
}

class _CountUpTextState extends State<CountUpText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  var _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reduceMotion(context)) {
      _controller.value = 1;
      return;
    }
    if (_started) return;
    _started = true;
    _controller.forward();
  }

  @override
  void didUpdateWidget(CountUpText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text && !reduceMotion(context)) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Text(_shown(_controller.value), style: widget.style);
      },
    );
  }

  String _shown(double t) {
    if (t >= 1) return widget.text;
    final match = RegExp(
      r'^(.*?)(\d+)(?:\.(\d+))?$',
    ).firstMatch(widget.text.trim());
    if (match == null) return widget.text;
    final prefix = match.group(1)!;
    final whole = int.parse(match.group(2)!);
    final frac = match.group(3);
    if (frac == null) return '$prefix${(whole * t).round()}';
    final scale = math.pow(10, frac.length).toInt();
    final minor = int.parse('$whole$frac');
    return '$prefix${(minor * t / scale).toStringAsFixed(frac.length)}';
  }
}

/// Big balance with the fractional part in a lighter weight, after count-up.
class MoneyHero extends StatefulWidget {
  const MoneyHero(this.text, {super.key});

  final String text;

  @override
  State<MoneyHero> createState() => _MoneyHeroState();
}

class _MoneyHeroState extends State<MoneyHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 480),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reduceMotion(context)) {
      _controller.value = 1;
    } else if (!_controller.isAnimating && _controller.value == 0) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(MoneyHero oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text && !reduceMotion(context)) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final shown = _controller.value >= 1
            ? widget.text
            : _tick(widget.text, _controller.value);
        return _rich(shown);
      },
    );
  }

  String _tick(String text, double t) {
    final match = RegExp(r'^(.*?)(\d+)(\.(\d+))?$').firstMatch(text.trim());
    if (match == null) return text;
    final prefix = match.group(1)!;
    final whole = int.parse(match.group(2)!);
    final frac = match.group(4);
    if (frac == null) return '$prefix${(whole * t).round()}';
    final scale = math.pow(10, frac.length).toInt();
    final minor = int.parse('$whole$frac');
    return '$prefix${(minor * t / scale).toStringAsFixed(frac.length)}';
  }

  Widget _rich(String shown) {
    final match = RegExp(r'^(.*?)(\d+)(\.\d+)?$').firstMatch(shown.trim());
    const heavy = TextStyle(
      fontSize: 40,
      height: 1.15,
      fontWeight: FontWeight.w800,
      letterSpacing: -1.2,
      color: Colors.white,
    );
    if (match == null) return Text(shown, style: heavy);
    return Text.rich(
      TextSpan(
        style: heavy,
        children: [
          TextSpan(text: '${match.group(1)}${match.group(2)}'),
          TextSpan(
            text: match.group(3) ?? '',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.62),
            ),
          ),
        ],
      ),
    );
  }
}

class Shake extends StatefulWidget {
  const Shake({super.key, required this.token, required this.child});

  final int token;
  final Widget child;

  @override
  State<Shake> createState() => _ShakeState();
}

class _ShakeState extends State<Shake> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void didUpdateWidget(Shake oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.token != oldWidget.token &&
        widget.token > 0 &&
        !reduceMotion(context)) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final dx = math.sin(_controller.value * math.pi * 6) * 8 * (1 - _controller.value);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: widget.child,
    );
  }
}

class SuccessMark extends StatefulWidget {
  const SuccessMark({super.key});

  @override
  State<SuccessMark> createState() => _SuccessMarkState();
}

class _SuccessMarkState extends State<SuccessMark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 640),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (reduceMotion(context)) {
        _controller.value = 1;
      } else {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = Curves.easeOutBack.transform(_controller.value.clamp(0, 1));
        return Transform.scale(
          scale: t,
          child: Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: Color(0xFF059669),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 40),
          ),
        );
      },
    );
  }
}

class FadeSlideIn extends StatelessWidget {
  const FadeSlideIn({super.key, required this.child, this.index = 0});

  final Widget child;
  final int index;

  @override
  Widget build(BuildContext context) {
    if (reduceMotion(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 220 + index * 40),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        // Translate only — Opacity forces a saveLayer every frame.
        return Transform.translate(
          offset: Offset(0, (1 - value) * 8),
          child: child,
        );
      },
      child: child,
    );
  }
}

class SpendRing extends StatefulWidget {
  const SpendRing({
    super.key,
    required this.segments,
    required this.center,
    this.caption = 'This week',
  });

  final List<RingSegment> segments;
  final String center;
  final String caption;

  @override
  State<SpendRing> createState() => _SpendRingState();
}

class RingSegment {
  const RingSegment(this.label, this.share, this.color);
  final String label;
  final double share;
  final Color color;
}

class _SpendRingState extends State<SpendRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reduceMotion(context)) {
      _controller.value = 1;
    } else if (_controller.value == 0 && !_controller.isAnimating) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return SizedBox(
          height: 260,
          child: CustomPaint(
            painter: _RingPainter(
              segments: widget.segments,
              sweep: _controller.value,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                    ),
                  ),
                  Text(
                    widget.caption,
                    style: const TextStyle(
                      color: Color(0xFF4A6490),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.segments, required this.sweep});

  final List<RingSegment> segments;
  final double sweep;

  @override
  void paint(Canvas canvas, Size size) {
    final total = segments.fold<double>(0, (sum, item) => sum + item.share);
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.34;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 22
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF0E2A56).withValues(alpha: 0.08);
    canvas.drawArc(rect, 0, math.pi * 2, false, track);
    if (total <= 0) return;
    var start = -math.pi / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 22
      ..strokeCap = StrokeCap.butt;
    for (final segment in segments) {
      final sweep = (segment.share / total) * math.pi * 2 * this.sweep;
      paint.color = segment.color;
      canvas.drawArc(rect, start, sweep, false, paint);
      final mid = start + sweep / 2;
      final labelR = radius + 36;
      final pos = center + Offset(math.cos(mid) * labelR, math.sin(mid) * labelR);
      final tp = TextPainter(
        text: TextSpan(
          text: segment.label,
          style: const TextStyle(
            color: Color(0xFF0E2A56),
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 72);
      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
      start += (segment.share / total) * math.pi * 2;
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.sweep != sweep || oldDelegate.segments != segments;
}
