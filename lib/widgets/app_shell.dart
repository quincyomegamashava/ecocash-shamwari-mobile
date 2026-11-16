import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/demo/demo_controller.dart';
import '../core/layout.dart';
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
    final index = _indexFor(auth.isStaff, location);
    final showBack = _parentOf(auth.isStaff, location) != null;
    final useRail = context.isMediumOrUp;

    final header = Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 12, 4),
      child: Row(
        children: [
          if (showBack)
            GlassIconButton(
              tooltip: 'Back',
              icon: Icons.arrow_back_rounded,
              onPressed: () => context.go(_parentOf(auth.isStaff, location)!),
            )
          else
            const ShamwariMark(size: 34),
          const SizedBox(width: 10),
          Text(
            'Shamwari',
            style: TextStyle(
              fontSize: useRail ? 24 : 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
              color: context.ink,
            ),
          ),
          const Spacer(),
          GlassIconButton(
            tooltip: 'Notices',
            icon: Icons.notifications_none_rounded,
            onPressed: () =>
                context.go(auth.isStaff ? '/audit' : '/activity'),
          ),
          const SizedBox(width: 8),
          Builder(
            builder: (context) => GlassIconButton(
              tooltip: 'Menu',
              icon: Icons.menu_rounded,
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
      ),
    );

    final destinations = [
      for (final tab in tabs)
        NavDestination(
          path: tab.path,
          label: tab.label,
          icon: tab.icon,
          selected: tab.selected,
        ),
    ];

    Widget body;
    if (useRail) {
      body = Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 4, 12),
            child: ShamwariRail(
              destinations: destinations,
              selectedIndex: index,
              onSelected: (next) => context.go(tabs[next].path),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                header,
                Expanded(child: ClipRect(child: child)),
                if (demo.active && demo.script?.current != null)
                  const _DemoBar(),
              ],
            ),
          ),
        ],
      );
    } else {
      body = Column(
        children: [
          header,
          Expanded(child: ClipRect(child: child)),
          if (demo.active && demo.script?.current != null) const _DemoBar(),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: ShamwariNav(
                destinations: destinations,
                selectedIndex: index,
                onSelected: (next) => context.go(tabs[next].path),
              ),
            ),
          ),
        ],
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay.copyWith(statusBarColor: Colors.transparent),
      child: ShamwariBackdrop(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          endDrawer: _ShamwariDrawer(location: location),
          body: SafeArea(bottom: !useRail, child: body),
        ),
      ),
    );
  }

  int _indexFor(bool staff, String location) {
    if (staff) {
      if (location == '/queue' || location == '/ledger') return 1;
      if (location == '/copilot' || location.startsWith('/pulse/case')) {
        return 2;
      }
      if (location == '/impact') return 3;
      if (location == '/pulse') return 0;
      return 4;
    }
    if (location == '/send' || location == '/receipts') return 1;
    if (location == '/insights') return 2;
    if (location == '/activity') return 3;
    if (location == '/home') return 0;
    return 4;
  }

  String? _parentOf(bool staff, String location) {
    const customerRoots = {
      '/home',
      '/send',
      '/insights',
      '/activity',
      '/profile',
    };
    const staffRoots = {'/pulse', '/queue', '/copilot', '/impact', '/profile'};
    if ((staff ? staffRoots : customerRoots).contains(location)) return null;
    if (location.startsWith('/pulse/case')) return '/copilot';
    if (staff) {
      if (location == '/onboarding' ||
          location == '/ledger' ||
          location == '/ai-log' ||
          location == '/audit' ||
          location == '/search') {
        return '/profile';
      }
      return '/pulse';
    }
    if (location == '/voice' ||
        location == '/chat' ||
        location == '/ussd' ||
        location == '/coach' ||
        location == '/scam' ||
        location == '/accessibility' ||
        location == '/search') {
      return '/profile';
    }
    if (location == '/receipts') return '/send';
    return staff ? '/pulse' : '/home';
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
    'Pay',
    Icons.qr_code_scanner_rounded,
    Icons.qr_code_scanner_rounded,
  ),
  _Tab(
    '/insights',
    'Insights',
    Icons.donut_large_outlined,
    Icons.donut_large_rounded,
  ),
  _Tab('/activity', 'History', Icons.history_rounded, Icons.history_rounded),
  _Tab(
    '/profile',
    'Account',
    Icons.person_outline_rounded,
    Icons.person_rounded,
  ),
];

const _staffTabs = [
  _Tab('/pulse', 'Home', Icons.home_outlined, Icons.home_rounded),
  _Tab('/queue', 'Queue', Icons.inbox_outlined, Icons.inbox_rounded),
  _Tab('/copilot', 'Copilot', Icons.forum_outlined, Icons.forum_rounded),
  _Tab('/impact', 'Impact', Icons.bolt_outlined, Icons.bolt_rounded),
  _Tab(
    '/profile',
    'Account',
    Icons.person_outline_rounded,
    Icons.person_rounded,
  ),
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
            ('/pulse', 'Care home', Icons.home_rounded),
            ('/queue', 'Queue', Icons.inbox_rounded),
            ('/copilot', 'Copilot', Icons.forum_rounded),
            ('/impact', 'Impact', Icons.bolt_rounded),
            ('/onboarding', 'Onboarding buddy', Icons.school_rounded),
            ('/ledger', 'Ledger', Icons.menu_book_rounded),
            ('/ai-log', 'AI log', Icons.memory_rounded),
            ('/audit', 'Audit log', Icons.fact_check_rounded),
            ('/search', 'Search', Icons.search_rounded),
            ('/profile', 'Account', Icons.person_rounded),
          ]
        : const [
            ('/home', 'Home', Icons.home_rounded),
            ('/send', 'Pay', Icons.qr_code_scanner_rounded),
            ('/insights', 'Insights', Icons.donut_large_rounded),
            ('/activity', 'History', Icons.history_rounded),
            ('/voice', 'Voice pay', Icons.mic_rounded),
            ('/chat', 'Chat channel', Icons.chat_bubble_outline_rounded),
            ('/ussd', 'USSD *151#', Icons.dialpad_rounded),
            ('/coach', 'Coach', Icons.auto_awesome_rounded),
            ('/scam', 'Scam check', Icons.shield_rounded),
            ('/receipts', 'Scan a slip', Icons.receipt_long_rounded),
            ('/accessibility', 'Accessibility', Icons.accessibility_new_rounded),
            ('/search', 'Search', Icons.search_rounded),
            ('/profile', 'Account', Icons.person_rounded),
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
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              step.narration,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFFD6E4F7), fontSize: 12),
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
