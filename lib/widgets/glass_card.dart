import 'package:flutter/material.dart';

import '../core/theme/shamwari_theme.dart';
import 'motion.dart';

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.radius = 28,
    this.tint,
    this.navy = false,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final double radius;
  final Color? tint;

  /// Deep navy hero and list cards. Type inside is white.
  final bool navy;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final radiusValue = BorderRadius.circular(radius);
    // Opaque panels (no live backdrop blur) — cheaper scroll/paint on tablets.
    final top = palette.highContrast
        ? palette.card
        : navy
        ? const Color(0xFF1A3E78)
        : palette.lightGlass
        ? Colors.white
        : Colors.white.withValues(alpha: 0.16);
    final bottom = palette.highContrast
        ? palette.card
        : navy
        ? const Color(0xFF0E2A56)
        : palette.lightGlass
        ? const Color(0xFFF7FAFE)
        : Colors.white.withValues(alpha: 0.08);
    final decorated = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radiusValue,
        gradient: palette.glass
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [tint ?? top, tint ?? bottom],
              )
            : null,
        color: palette.glass ? null : (tint ?? palette.card),
        border: Border.all(
          color: palette.highContrast
              ? palette.border
              : Colors.white.withValues(alpha: palette.lightGlass ? 0.95 : 0.28),
          width: palette.highContrast ? 2 : 1,
        ),
        boxShadow: palette.glass && !palette.highContrast
            ? [
                BoxShadow(
                  color: const Color(0xFF0E2A56).withValues(alpha: 0.08),
                  blurRadius: shamwariAllowBlur ? 16 : 8,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: CardInk(
          navy: navy && !palette.highContrast,
          child: IconTheme(
            data: IconThemeData(
              color: navy && !palette.highContrast
                  ? Colors.white
                  : palette.onCard,
            ),
            child: DefaultTextStyle.merge(
              style: TextStyle(
                color: navy && !palette.highContrast
                    ? Colors.white
                    : palette.onCard,
              ),
              child: Padding(padding: padding, child: child),
            ),
          ),
        ),
      ),
    );
    final clipped = ClipRRect(
      borderRadius: radiusValue,
      child: decorated,
    );
    if (onTap == null) return clipped;
    return Pressable(onTap: onTap, child: clipped);
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: color ?? context.ink,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
