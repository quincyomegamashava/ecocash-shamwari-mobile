import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/demo/demo_controller.dart';
import '../core/session/session.dart';
import '../core/theme/shamwari_theme.dart';
import 'mark.dart';
import 'sage_ui.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final auth = ref.watch(authProvider);
    final demo = ref.watch(demoProvider);
    final location = GoRouterState.of(context).uri.path;
    final overlay =
        palette.highContrast || Theme.of(context).brightness == Brightness.dark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;
    final tabs = auth.isStaff ? _staffTabs : _customerTabs;
    final index = _indexFor(tabs, location);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay.copyWith(statusBarColor: Colors.transparent),
      child: ShamwariBackdrop(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          drawer: _ShamwariDrawer(location: location),
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 12, 0),
                  child: Row(
                    children: [
                      Builder(
                        builder: (context) => GlassIconButton(
                          tooltip: 'Menu',
                          icon: Icons.menu_rounded,
                          onPressed: () => Scaffold.of(context).openDrawer(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const ShamwariMark(size: 28),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: PrototypeChip(),
                          ),
                        ),
                      ),
                      GlassIconButton(
                        tooltip: 'Search',
                        icon: Icons.search_rounded,
                        onPressed: () => context.go('/search'),
                      ),
                      const SizedBox(width: 8),
                      GlassIconButton(
                        tooltip: 'Profile',
                        icon: Icons.person_rounded,
                        filled: true,
                        onPressed: () => context.go('/profile'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ColoredBox(
                    color: palette.bg,
                    child: ClipRect(child: child),
                  ),
                ),
                if (demo.active && demo.script?.current != null)
                  const _DemoBar(),
              ],
            ),
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: ShamwariNav(
              destinations: [
                for (final tab in tabs)
                  NavDestination(
                    path: tab.path,
                    label: tab.label,
                    icon: tab.icon,
                    selected: tab.selected,
                  ),
              ],
              selectedIndex: index,
              onSelected: (next) => context.go(tabs[next].path),
            ),
          ),
        ),
      ),
    );
  }

  int _indexFor(List<_Tab> tabs, String location) {
    final index = tabs.indexWhere((tab) => location == tab.path);
    return index < 0 ? 0 : index;
  }
}

class _Tab {
  const _Tab(this.path, this.label, this.icon, this.selected);
  final String path;
  final String label;
  final IconData icon;
  final IconData selected;
}

const _customerTabs = [
  _Tab('/home', 'Home', Icons.home_outlined, Icons.home_rounded),
  _Tab(
    '/send',
    'Send',
    Icons.arrow_outward_rounded,
    Icons.arrow_outward_rounded,
  ),
  _Tab('/voice', 'Voice', Icons.mic_none_rounded, Icons.mic_rounded),
  _Tab(
    '/coach',
    'Coach',
    Icons.chat_bubble_outline_rounded,
    Icons.chat_bubble_rounded,
  ),
  _Tab('/scam', 'Scam', Icons.shield_outlined, Icons.shield_rounded),
];

const _staffTabs = [
  _Tab('/pulse', 'Pulse', Icons.insights_outlined, Icons.insights_rounded),
  _Tab('/onboarding', 'Buddy', Icons.school_outlined, Icons.school_rounded),
  _Tab('/ledger', 'Ledger', Icons.menu_book_outlined, Icons.menu_book_rounded),
  _Tab('/ai-log', 'AI log', Icons.memory_outlined, Icons.memory_rounded),
];

class _ShamwariDrawer extends ConsumerWidget {
  const _ShamwariDrawer({required this.location});
  final String location;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final auth = ref.watch(authProvider);
    final settings = ref.watch(settingsProvider);
    final name = auth.user?.displayName ?? 'Shamwari';
    final role = auth.isStaff ? 'Care team' : 'Customer';
    final links = auth.isStaff
        ? const [
            ('/profile', 'Profile', Icons.person_rounded),
            ('/pulse', 'Customer pulse', Icons.insights_rounded),
            ('/onboarding', 'Onboarding buddy', Icons.school_rounded),
            ('/ledger', 'Ledger', Icons.menu_book_rounded),
            ('/ai-log', 'AI log', Icons.memory_rounded),
            ('/search', 'Search', Icons.search_rounded),
          ]
        : const [
            ('/profile', 'Profile', Icons.person_rounded),
            ('/home', 'Home', Icons.home_rounded),
            ('/send', 'Send money', Icons.arrow_outward_rounded),
            ('/voice', 'Voice pay', Icons.mic_rounded),
            ('/coach', 'Coach', Icons.chat_bubble_rounded),
            ('/scam', 'Scam check', Icons.shield_rounded),
            ('/receipts', 'Receipts', Icons.receipt_long_rounded),
            ('/activity', 'Activity', Icons.history_rounded),
            (
              '/accessibility',
              'Accessibility',
              Icons.accessibility_new_rounded,
            ),
            ('/search', 'Search', Icons.search_rounded),
          ];

    return Drawer(
      backgroundColor: palette.bg,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Row(
              children: [
                const ShamwariMark(size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: context.ink,
                        ),
                      ),
                      Text(
                        role,
                        style: TextStyle(color: context.inkMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            for (final link in links)
              SettingsPill(
                icon: link.$3,
                title: link.$2,
                trailing: location == link.$1
                    ? Icon(Icons.check_rounded, color: palette.forest)
                    : Icon(
                        Icons.chevron_right_rounded,
                        color: palette.onCardMuted,
                      ),
                onTap: () {
                  Navigator.pop(context);
                  context.go(link.$1);
                },
              ),
            const Divider(height: 28),
            Text(
              'Appearance',
              style: TextStyle(
                color: context.inkMuted,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text('Dark'),
                  icon: Icon(Icons.dark_mode_outlined),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text('Light'),
                  icon: Icon(Icons.light_mode_outlined),
                ),
              ],
              selected: {settings.themeMode},
              onSelectionChanged: (value) =>
                  ref.read(settingsProvider.notifier).setThemeMode(value.first),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('High contrast'),
              subtitle: const Text(
                'Black and yellow. Larger type comes with it.',
              ),
              value: settings.highContrast,
              onChanged: (value) =>
                  ref.read(settingsProvider.notifier).setHighContrast(value),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Large type'),
              value: settings.largeType,
              onChanged: (value) =>
                  ref.read(settingsProvider.notifier).setLargeType(value),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                await ref.read(demoProvider.notifier).walkMorning();
              },
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text("Walk Rudo's morning"),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                await ref.read(authProvider.notifier).logout();
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Sign out'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DemoBar extends ConsumerWidget {
  const _DemoBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final demo = ref.watch(demoProvider);
    final auth = ref.watch(authProvider);
    final step = demo.script?.current;
    if (step == null) return const SizedBox.shrink();
    final role = auth.isStaff ? 'staff' : 'customer';
    final mismatch = step.role != role;
    return Material(
      color: palette.highContrast
          ? Colors.black
          : palette.lightGlass
          ? palette.forest
          : palette.card,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: palette.orange.withValues(alpha: 0.7)),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${step.number} / ${demo.script?.total ?? 7} · ${step.kicker}',
              style: TextStyle(
                color: palette.orange,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              step.title,
              style: TextStyle(
                color: context.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              step.narration,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: context.inkMuted, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: demo.busy
                      ? null
                      : () => ref.read(demoProvider.notifier).back(),
                  child: const Text('Back'),
                ),
                OutlinedButton(
                  onPressed: demo.busy
                      ? null
                      : () => ref.read(demoProvider.notifier).stop(),
                  child: const Text('Stop'),
                ),
                if (mismatch)
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: palette.highContrast
                          ? palette.orange
                          : Colors.white,
                      foregroundColor: palette.highContrast
                          ? Colors.black
                          : palette.forest,
                    ),
                    onPressed: demo.busy
                        ? null
                        : () =>
                              ref.read(demoProvider.notifier).continueAsCare(),
                    child: const Text('Continue as care'),
                  )
                else
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: palette.highContrast
                          ? palette.orange
                          : Colors.white,
                      foregroundColor: palette.highContrast
                          ? Colors.black
                          : palette.forest,
                    ),
                    onPressed: demo.busy
                        ? null
                        : () => ref.read(demoProvider.notifier).next(),
                    child: const Text('Next'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
