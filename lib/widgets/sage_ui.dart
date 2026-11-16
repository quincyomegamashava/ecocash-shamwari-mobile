import 'package:flutter/material.dart';

import '../core/theme/shamwari_theme.dart';
import 'glass_card.dart';

class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.filled = false,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final onSky = palette.lightGlass && !palette.highContrast;
    final background = palette.highContrast
        ? Colors.black
        : onSky || filled
        ? Colors.white.withValues(alpha: 0.86)
        : Colors.white.withValues(alpha: 0.12);
    final foreground = palette.highContrast
        ? context.ink
        : onSky || filled
        ? palette.forest
        : Colors.white;
    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: background,
        shape: CircleBorder(
          side: BorderSide(
            color: palette.highContrast
                ? palette.border
                : Colors.white.withValues(alpha: 0.55),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 42,
            height: 42,
            child: Icon(icon, color: foreground, size: 20),
          ),
        ),
      ),
    );
  }
}

class NavDestination {
  const NavDestination({
    required this.path,
    required this.label,
    required this.icon,
    required this.selected,
  });

  final String path;
  final String label;
  final IconData icon;
  final IconData selected;
}

class ShamwariNav extends StatelessWidget {
  const ShamwariNav({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<NavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final reduce = MediaQuery.disableAnimationsOf(context);
    return Material(
      key: const Key('shamwari-nav'),
      color: palette.highContrast ? Colors.black : const Color(0xFF0E2A56),
      elevation: palette.highContrast ? 0 : 16,
      shadowColor: const Color(0x660E2A56),
      borderRadius: BorderRadius.circular(28),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth / destinations.length;
            final index = selectedIndex.clamp(0, destinations.length - 1);
            return Stack(
              children: [
                AnimatedPositioned(
                  duration: reduce
                      ? Duration.zero
                      : const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  left: width * index,
                  width: width,
                  top: 0,
                  bottom: 0,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: palette.highContrast
                          ? palette.orange
                          : Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                Row(
                  children: [
                    for (var i = 0; i < destinations.length; i++)
                      Expanded(
                        child: _NavItem(
                          destination: destinations[i],
                          selected: i == index,
                          onTap: () => onSelected(i),
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final NavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final icon = selected ? destination.selected : destination.icon;
    final foreground = palette.highContrast
        ? (selected ? Colors.black : palette.orange)
        : Colors.white;
    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      child: Material(
        key: Key('nav-${destination.path}'),
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20, color: foreground),
                const SizedBox(height: 2),
                Text(
                  destination.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foreground.withValues(alpha: selected ? 1 : 0.72),
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Vertical rail for tablet / wide layouts.
class ShamwariRail extends StatelessWidget {
  const ShamwariRail({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<NavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final index = selectedIndex.clamp(0, destinations.length - 1);
    return Material(
      key: const Key('shamwari-rail'),
      color: palette.highContrast ? Colors.black : const Color(0xFF0E2A56),
      elevation: palette.highContrast ? 0 : 12,
      shadowColor: const Color(0x660E2A56),
      borderRadius: BorderRadius.circular(28),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        child: Column(
          children: [
            for (var i = 0; i < destinations.length; i++) ...[
              if (i > 0) const SizedBox(height: 6),
              _RailItem(
                destination: destinations[i],
                selected: i == index,
                onTap: () => onSelected(i),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final NavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final icon = selected ? destination.selected : destination.icon;
    final foreground = palette.highContrast
        ? (selected ? Colors.black : palette.orange)
        : Colors.white;
    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      child: Material(
        key: Key('rail-${destination.path}'),
        color: selected
            ? (palette.highContrast
                  ? palette.orange
                  : Colors.white.withValues(alpha: 0.16))
            : Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            width: 72,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 22, color: foreground),
                  const SizedBox(height: 4),
                  Text(
                    destination.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: foreground.withValues(alpha: selected ? 1 : 0.72),
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SettingsPill extends StatelessWidget {
  const SettingsPill({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        radius: 999,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: palette.highContrast
                    ? Colors.black
                    : palette.forest.withValues(alpha: palette.lightGlass ? 0.1 : 0.35),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: palette.onCard),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: TextStyle(color: palette.onCardMuted, fontSize: 12),
                    ),
                ],
              ),
            ),
            trailing ??
                Icon(Icons.chevron_right_rounded, color: palette.onCardMuted),
          ],
        ),
      ),
    );
  }
}
