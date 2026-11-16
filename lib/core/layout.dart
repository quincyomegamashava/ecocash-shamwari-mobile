import 'package:flutter/material.dart';

/// Shared width breakpoints for phone / tablet / wide layouts.
abstract final class ShamwariBreakpoints {
  static const double compact = 600;
  static const double medium = 840;
  static const double contentMax = 720;
  static const double homePaneGap = 16;
}

extension ShamwariLayoutContext on BuildContext {
  double get windowWidth => MediaQuery.sizeOf(this).width;

  /// Phone-width layouts (bottom nav, single column).
  bool get isCompact => windowWidth < ShamwariBreakpoints.compact;

  /// Tablet and up — side rail instead of bottom nav.
  bool get isMediumOrUp => windowWidth >= ShamwariBreakpoints.compact;

  /// Wide enough for list–detail / two panes.
  bool get isExpanded => windowWidth >= ShamwariBreakpoints.medium;

  /// Horizontal inset that keeps reading width comfortable on tablets.
  EdgeInsets contentPadding({
    double phone = 16,
    double tablet = 24,
  }) {
    if (isCompact) return EdgeInsets.symmetric(horizontal: phone);
    final side = ((windowWidth - ShamwariBreakpoints.contentMax) / 2).clamp(
      tablet,
      windowWidth / 2,
    );
    return EdgeInsets.symmetric(horizontal: side);
  }
}

/// Centers [child] and caps its width — used for login and narrow forms.
class ConstrainedContent extends StatelessWidget {
  const ConstrainedContent({
    super.key,
    required this.child,
    this.maxWidth = ShamwariBreakpoints.contentMax,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
