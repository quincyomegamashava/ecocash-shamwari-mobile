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

  /// Deeper sage night. The nav pill stays darker than the field.
  static const dark = ShamwariPalette(
    bg: Color(0xFF2A4740),
    bgElevated: Color(0xFF3E6158),
    card: Color(0xFF1A3330),
    text: Color(0xFFF4F7F6),
    muted: Color(0xFFC5D5CF),
    faint: Color(0xFF8AA39B),
    orange: Color(0xFFF97316),
    teal: Color(0xFF8FBFB4),
    forest: Color(0xFF0C2420),
    onCard: Color(0xFFF4F7F6),
    onCardMuted: Color(0xFFC5D5CF),
    lightGlass: false,
    border: Color(0x38FFFFFF),
    danger: Color(0xFFFB7185),
    ok: Color(0xFF34D399),
    warning: Color(0xFFFBBF24),
    glass: true,
    highContrast: false,
    onAccent: Colors.white,
  );

  /// Default. Soft sage field, frosted white cards, forest-teal selection.
  static const light = ShamwariPalette(
    bg: Color(0xFF6F8A80),
    bgElevated: Color(0xFFA9BDB5),
    card: Color(0xFFFFFFFF),
    text: Color(0xFFFFFFFF),
    muted: Color(0xE6FFFFFF),
    faint: Color(0xB3FFFFFF),
    orange: Color(0xFFF97316),
    teal: Color(0xFF0F3B33),
    forest: Color(0xFF0F3B33),
    onCard: Color(0xFF0F3B33),
    onCardMuted: Color(0xFF3E5A52),
    lightGlass: true,
    border: Color(0xBFFFFFFF),
    danger: Color(0xFFBE123C),
    ok: Color(0xFF047857),
    warning: Color(0xFFC2410C),
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

  /// Type color for the current surface: white on the sage field, forest inside a light card.
  Color get ink => CardInk.contains(this) ? palette.onCard : palette.text;

  Color get inkMuted =>
      CardInk.contains(this) ? palette.onCardMuted : palette.muted;
}

/// Marks a frosted card so nested text picks up [ShamwariPalette.onCard].
class CardInk extends InheritedWidget {
  const CardInk({super.key, required super.child});

  static bool contains(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CardInk>() != null;

  @override
  bool updateShouldNotify(CardInk oldWidget) => false;
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
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [palette.bg, palette.bgElevated],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (palette.glass) ...[
            const Positioned(
              top: -110,
              right: -40,
              child: _Glow(color: Color(0xFFFFFFFF), size: 260, alpha: 0.16),
            ),
            const Positioned(
              bottom: -20,
              left: -70,
              child: _Glow(color: Color(0xFF0F3B33), size: 240, alpha: 0.14),
            ),
          ],
          child,
        ],
      ),
    );
  }
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
