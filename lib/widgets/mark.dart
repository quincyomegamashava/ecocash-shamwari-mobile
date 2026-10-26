import 'package:flutter/material.dart';

import '../core/theme/shamwari_theme.dart';

class ShamwariMark extends StatelessWidget {
  const ShamwariMark({super.key, this.size = 36});

  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: palette.highContrast ? palette.orange : const Color(0xFFF97316),
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: palette.highContrast || !shamwariAllowBlur
            ? null
            : [
                BoxShadow(
                  color: const Color(0xFFF97316).withValues(alpha: 0.45),
                  blurRadius: size * 0.45,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: CustomPaint(
        painter: _MarkPainter(
          color: palette.highContrast ? Colors.black : Colors.white,
        ),
      ),
    );
  }
}

class _MarkPainter extends CustomPainter {
  _MarkPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final peak = Path()
      ..moveTo(size.width * 0.5, size.height * 0.24)
      ..lineTo(size.width * 0.76, size.height * 0.74)
      ..lineTo(size.width * 0.24, size.height * 0.74)
      ..close();
    final cut = Path()
      ..moveTo(size.width * 0.5, size.height * 0.46)
      ..lineTo(size.width * 0.62, size.height * 0.68)
      ..lineTo(size.width * 0.38, size.height * 0.68)
      ..close();
    canvas.drawPath(
      Path.combine(PathOperation.difference, peak, cut),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _MarkPainter oldDelegate) =>
      oldDelegate.color != color;
}

class PrototypeChip extends StatelessWidget {
  const PrototypeChip({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: palette.highContrast
            ? Colors.black
            : Colors.white.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: palette.highContrast
              ? palette.orange
              : Colors.white.withValues(alpha: 0.45),
        ),
      ),
      child: Text(
        'Prototype · synthetic data',
        style: TextStyle(
          color: palette.highContrast ? palette.orange : Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}

class HackathonPill extends StatelessWidget {
  const HackathonPill({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: palette.orange.withValues(
            alpha: palette.highContrast ? 1 : 0.7,
          ),
        ),
      ),
      child: Text(
        'ECOCASH AI HACKATHON',
        style: TextStyle(
          color: palette.orange,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
