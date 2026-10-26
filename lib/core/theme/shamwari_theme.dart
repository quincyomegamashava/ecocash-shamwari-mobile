import 'dart:ui';

import 'package:flutter/material.dart';

/// Widget-test captures deadlock on blur layers. The running app leaves this
/// true so glass and the backdrop glow stay soft.
bool shamwariAllowBlur = true;

@immutable
class ShamwariPalette extends ThemeExtension<ShamwariPalette> {
  const ShamwariPalette({
    required this.bg,
    required this.bgElevated,
    required this.card,
    required this.text,
    required this.muted,
    required this.faint,
    required this.orange,
    required this.teal,
    required this.forest,
    required this.onCard,
    required this.onCardMuted,
    required this.lightGlass,
    required this.border,
    required this.danger,
    required this.ok,
    required this.warning,
    required this.glass,
    required this.highContrast,
    required this.onAccent,
  });

  final Color bg;
  final Color bgElevated;
  final Color card;
  final Color text;
  final Color muted;
  final Color faint;
  final Color orange;
  final Color teal;
  final Color forest;
  final Color onCard;
  final Color onCardMuted;

  /// Frosted white cards with dark type, as in the sage reference.
  final bool lightGlass;
  final Color border;
  final Color danger;
  final Color ok;
  final Color warning;
  final bool glass;
  final bool highContrast;
  final Color onAccent;

  /// Night version of the same sky-and-navy system.
  static const dark = ShamwariPalette(
    bg: Color(0xFF0C2344),
    bgElevated: Color(0xFF16325C),
    card: Color(0xFF0A1C38),
    text: Color(0xFFF4F8FF),
    muted: Color(0xFFC5D4EA),
    faint: Color(0xFF8AA0C2),
    orange: Color(0xFF7EB6FF),
    teal: Color(0xFF9CC4FF),
    forest: Color(0xFF071628),
    onCard: Color(0xFFF4F8FF),
    onCardMuted: Color(0xFFC5D4EA),
    lightGlass: false,
    border: Color(0x38FFFFFF),
    danger: Color(0xFFFB7185),
    ok: Color(0xFF34D399),
    warning: Color(0xFFFBBF24),
    glass: true,
    highContrast: false,
    onAccent: Colors.white,
  );

  /// Default. Soft sky field, light glass cards, deep navy type and heroes.
  static const light = ShamwariPalette(
    bg: Color(0xFF8EBFEE),
    bgElevated: Color(0xFFD7EBFA),
    card: Color(0xFFFFFFFF),
    text: Color(0xFF0B1E3F),
    muted: Color(0xFF2C4A73),
    faint: Color(0xFF4E6E99),
    orange: Color(0xFF2F6FED),
    teal: Color(0xFF3D6FB5),
    forest: Color(0xFF0E2A56),
    onCard: Color(0xFF0E2A56),
    onCardMuted: Color(0xFF4A6490),
    lightGlass: true,
    border: Color(0xCCFFFFFF),
    danger: Color(0xFFE11D48),
    ok: Color(0xFF059669),
    warning: Color(0xFFD97706),
    glass: true,
    highContrast: false,
    onAccent: Colors.white,
  );

  static const contrast = ShamwariPalette(
    bg: Color(0xFF000000),
    bgElevated: Color(0xFF000000),
    card: Color(0xFF000000),
    text: Color(0xFFFFE14A),
    muted: Color(0xFFFFE14A),
    faint: Color(0xFFFFF3A3),
    orange: Color(0xFFFFE14A),
    teal: Color(0xFFFFFFFF),
    forest: Color(0xFFFFE14A),
    onCard: Color(0xFFFFE14A),
    onCardMuted: Color(0xFFFFF3A3),
    lightGlass: false,
    border: Color(0xFFFFE14A),
    danger: Color(0xFFFF5A5A),
    ok: Color(0xFFFFFFFF),
    warning: Color(0xFFFFE14A),
    glass: false,
    highContrast: true,
    onAccent: Colors.black,
  );

  @override
  ShamwariPalette copyWith({
    Color? bg,
    Color? bgElevated,
    Color? card,
    Color? text,
    Color? muted,
    Color? faint,
    Color? orange,
    Color? teal,
    Color? forest,
    Color? onCard,
    Color? onCardMuted,
    bool? lightGlass,
    Color? border,
    Color? danger,
    Color? ok,
    Color? warning,
    bool? glass,
    bool? highContrast,
    Color? onAccent,
  }) {
    return ShamwariPalette(
      bg: bg ?? this.bg,
      bgElevated: bgElevated ?? this.bgElevated,
      card: card ?? this.card,
      text: text ?? this.text,
      muted: muted ?? this.muted,
      faint: faint ?? this.faint,
      orange: orange ?? this.orange,
      teal: teal ?? this.teal,
      forest: forest ?? this.forest,
      onCard: onCard ?? this.onCard,
      onCardMuted: onCardMuted ?? this.onCardMuted,
      lightGlass: lightGlass ?? this.lightGlass,
      border: border ?? this.border,
      danger: danger ?? this.danger,
      ok: ok ?? this.ok,
      warning: warning ?? this.warning,
      glass: glass ?? this.glass,
      highContrast: highContrast ?? this.highContrast,
      onAccent: onAccent ?? this.onAccent,
    );
  }

  @override
  ShamwariPalette lerp(ThemeExtension<ShamwariPalette>? other, double t) {
    if (other is! ShamwariPalette) return this;
    return t < 0.5 ? this : other;
  }
}

extension ShamwariThemeContext on BuildContext {
  ShamwariPalette get palette =>
      Theme.of(this).extension<ShamwariPalette>() ?? ShamwariPalette.light;

  /// Type color for the current surface: navy on the sky, white inside a navy card.
  Color get ink {
    if (CardInk.navyOf(this) && !palette.highContrast) return Colors.white;
    return CardInk.contains(this) ? palette.onCard : palette.text;
  }

  Color get inkMuted {
    if (CardInk.navyOf(this) && !palette.highContrast) {
      return Colors.white.withValues(alpha: 0.65);
    }
    return CardInk.contains(this) ? palette.onCardMuted : palette.muted;
  }
}

/// Marks a frosted card so nested text picks up [ShamwariPalette.onCard].
class CardInk extends InheritedWidget {
  const CardInk({super.key, required super.child, this.navy = false});

  final bool navy;

  static CardInk? _of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CardInk>();

  static bool contains(BuildContext context) => _of(context) != null;

  static bool navyOf(BuildContext context) => _of(context)?.navy ?? false;

  @override
  bool updateShouldNotify(CardInk oldWidget) => navy != oldWidget.navy;
}

ThemeData shamwariTheme(ShamwariPalette palette) {
  final brightness = palette == ShamwariPalette.light
      ? Brightness.light
      : Brightness.dark;
  final scheme = ColorScheme(
    brightness: brightness,
    primary: palette.highContrast ? palette.orange : palette.forest,
    onPrimary: palette.highContrast ? Colors.black : Colors.white,
    secondary: palette.teal,
    onSecondary: palette.highContrast ? Colors.black : Colors.white,
    error: palette.danger,
    onError: Colors.white,
    surface: palette.lightGlass ? Colors.white : palette.card,
    onSurface: palette.onCard,
  );
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: BorderSide(
      color: palette.border,
      width: palette.highContrast ? 2 : 1,
    ),
  );
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: palette.bg,
    fontFamily: 'Plus Jakarta Sans',
    splashFactory: InkRipple.splashFactory,
    extensions: [palette],
    textTheme: TextTheme(
      displayLarge: TextStyle(
        fontSize: 40,
        height: 1.02,
        fontWeight: FontWeight.w800,
        color: palette.text,
        letterSpacing: -1,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        height: 1.1,
        fontWeight: FontWeight.w800,
        color: palette.text,
        letterSpacing: -0.6,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: palette.text,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: palette.text,
      ),
      bodyLarge: TextStyle(fontSize: 16, height: 1.4, color: palette.text),
      bodyMedium: TextStyle(fontSize: 14, height: 1.4, color: palette.text),
      bodySmall: TextStyle(fontSize: 12, height: 1.35, color: palette.muted),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: palette.text,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: palette.highContrast
          ? Colors.black
          : Colors.white.withValues(alpha: palette.lightGlass ? 0.55 : 0.12),
      hintStyle: TextStyle(
        color: palette.lightGlass ? palette.onCardMuted : palette.faint,
      ),
      labelStyle: TextStyle(
        color: palette.lightGlass ? palette.onCardMuted : palette.muted,
        fontWeight: FontWeight.w600,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: BorderSide(
          color: palette.highContrast ? palette.orange : palette.forest,
          width: palette.highContrast ? 2.5 : 1.6,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: palette.highContrast || !palette.lightGlass
            ? palette.text
            : palette.forest,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: palette.highContrast
            ? palette.orange
            : palette.lightGlass
            ? palette.forest
            : palette.teal,
        foregroundColor: palette.highContrast
            ? Colors.black
            : palette.lightGlass
            ? Colors.white
            : const Color(0xFF0C2420),
        minimumSize: const Size(0, 48),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 15,
          fontFamily: 'Plus Jakarta Sans',
        ),
        shape: const StadiumBorder(),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: palette.text,
        side: BorderSide(
          color: palette.border,
          width: palette.highContrast ? 2 : 1,
        ),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontFamily: 'Plus Jakarta Sans',
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: palette.highContrast
          ? Colors.black
          : Colors.white.withValues(alpha: palette.lightGlass ? 0.72 : 0.14),
      selectedColor: palette.highContrast ? palette.orange : Colors.white,
      disabledColor: Colors.white24,
      labelStyle: TextStyle(
        color: palette.highContrast
            ? palette.text
            : (palette.lightGlass ? palette.forest : Colors.white),
        fontWeight: FontWeight.w700,
        fontFamily: 'Plus Jakarta Sans',
      ),
      secondaryLabelStyle: TextStyle(
        color: palette.highContrast ? Colors.black : palette.forest,
        fontWeight: FontWeight.w800,
        fontFamily: 'Plus Jakarta Sans',
      ),
      side: BorderSide(
        color: palette.highContrast
            ? palette.border
            : Colors.white.withValues(alpha: 0.7),
      ),
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (palette.highContrast) return palette.orange;
        if (states.contains(WidgetState.selected)) return Colors.white;
        return Colors.white;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (palette.highContrast) {
          return states.contains(WidgetState.selected)
              ? Colors.black
              : Colors.black;
        }
        return states.contains(WidgetState.selected)
            ? (palette.lightGlass ? palette.forest : palette.teal)
            : palette.forest.withValues(alpha: 0.28);
      }),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: palette.highContrast ? Colors.black : palette.bgElevated,
      indicatorColor: palette.orange.withValues(
        alpha: palette.highContrast ? 1 : 0.18,
      ),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 11,
          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          color: selected ? palette.orange : palette.muted,
          fontFamily: 'Plus Jakarta Sans',
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected
              ? (palette.highContrast ? Colors.black : palette.orange)
              : palette.muted,
        );
      }),
    ),
    dividerColor: palette.border,
    snackBarTheme: SnackBarThemeData(
      backgroundColor: palette.highContrast ? Colors.black : palette.bgElevated,
      contentTextStyle: TextStyle(
        color: palette.text,
        fontFamily: 'Plus Jakarta Sans',
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: palette.border),
      ),
    ),
  );
}

class ShamwariBackdrop extends StatelessWidget {
  const ShamwariBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final sky = palette.lightGlass;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: sky
              ? const [Color(0xFFD7EBFA), Color(0xFF8EBFEE), Color(0xFF6AA6E4)]
              : [palette.bg, palette.bgElevated, palette.bg],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (palette.glass)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _WavePainter(
                    color: sky ? Colors.white : const Color(0xFF7EB6FF),
                    alpha: sky ? 0.28 : 0.08,
                  ),
                ),
              ),
            ),
          if (palette.glass) ...[
            const Positioned(
              top: -120,
              right: -30,
              child: _Glow(color: Color(0xFFFFFFFF), size: 280, alpha: 0.35),
            ),
            Positioned(
              bottom: 40,
              left: -80,
              child: _Glow(
                color: sky ? const Color(0xFF5B93D6) : const Color(0xFF16325C),
                size: 240,
                alpha: 0.22,
              ),
            ),
          ],
          child,
        ],
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  _WavePainter({required this.color, required this.alpha});

  final Color color;
  final double alpha;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: alpha)
      ..style = PaintingStyle.fill;
    for (final band in [0.22, 0.48, 0.74]) {
      final path = Path()..moveTo(0, size.height * band);
      for (var x = 0.0; x <= size.width; x += 8) {
        final y =
            size.height * band +
            18 * (x / size.width) * (0.5 - (x / size.width)) * 8 +
            10 * (x / 90);
        path.lineTo(x, y);
      }
      path
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.alpha != alpha;
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.size, required this.alpha});

  final Color color;
  final double size;
  final double alpha;

  @override
  Widget build(BuildContext context) {
    final orb = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: alpha),
      ),
    );
    return IgnorePointer(
      child: shamwariAllowBlur
          ? ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: orb,
            )
          : orb,
    );
  }
}
