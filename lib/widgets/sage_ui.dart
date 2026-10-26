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
    final background = palette.highContrast
        ? Colors.black
        : filled
        ? Colors.white
        : Colors.white.withValues(alpha: palette.lightGlass ? 0.28 : 0.12);
    final foreground = palette.highContrast
        ? context.ink
        : filled
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
    return Material(
      key: const Key('shamwari-nav'),
      color: palette.highContrast ? Colors.black : palette.forest,
      elevation: palette.highContrast ? 0 : 10,
      shadowColor: const Color(0x66000000),
      shape: StadiumBorder(
        side: BorderSide(
          color: palette.highContrast
              ? palette.border
              : Colors.white.withValues(alpha: 0.35),
          width: palette.highContrast ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Row(
          children: [
            for (var i = 0; i < destinations.length; i++) ...[
              if (i > 0) const SizedBox(width: 4),
              i == selectedIndex
                  ? Expanded(
                      child: _NavItem(
                        destination: destinations[i],
                        selected: true,
                        onTap: () => onSelected(i),
                      ),
                    )
                  : _NavItem(
                      destination: destinations[i],
                      selected: false,
                      onTap: () => onSelected(i),
                    ),
            ],
          ],
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
        : palette.forest;
    final background = palette.highContrast
        ? (selected ? palette.orange : Colors.black)
        : Colors.white;
    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      child: Material(
        key: Key('nav-${destination.path}'),
        color: background,
        shape: selected
            ? const StadiumBorder()
            : CircleBorder(
                side: BorderSide(
                  color: palette.highContrast
                      ? palette.border
                      : Colors.white.withValues(alpha: 0.8),
                  width: palette.highContrast ? 2 : 1,
                ),
              ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          customBorder: selected ? const StadiumBorder() : const CircleBorder(),
          child: SizedBox(
            width: selected ? null : 40,
            height: 40,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: selected ? 8 : 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 20, color: foreground),
                  if (selected) ...[
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        destination.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: foreground,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
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
