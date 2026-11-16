import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/models/models.dart';
import '../core/session/session.dart';
import '../core/theme/shamwari_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/sage_ui.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  WalletSnapshot? _wallet;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    final auth = ref.read(authProvider);
    if (!auth.isCustomer) return;
    try {
      final wallet = await ref.read(shamwariApiProvider).wallet();
      if (mounted) setState(() => _wallet = wallet);
    } catch (_) {
      // Profile still renders from the signed-in account.
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final auth = ref.watch(authProvider);
    final settings = ref.watch(settingsProvider);
    final name = auth.user?.displayName ?? 'Shamwari';
    final role = auth.isStaff ? 'Care team' : 'Customer';
    final city = _wallet?.customer.city ?? (auth.isStaff ? 'Harare desk' : '');
    final initials = name
        .split(' ')
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0])
        .join()
        .toUpperCase();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        const Text(
          'Account',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        GlassCard(
          radius: 30,
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: palette.highContrast ? Colors.black : palette.forest,
                  border: Border.all(
                    color: palette.highContrast ? palette.orange : Colors.white,
                    width: palette.highContrast ? 2 : 1.5,
                  ),
                ),
                child: Text(
                  initials.isEmpty ? 'S' : initials,
                  style: TextStyle(
                    color: palette.highContrast ? palette.orange : Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                name,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              Text(
                city.isEmpty ? role : '$city · $role',
                style: TextStyle(color: palette.onCardMuted),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _Tile(
                    label: 'Balance',
                    value: auth.isStaff
                        ? 'Care'
                        : (_wallet?.wallets.isNotEmpty == true
                              ? _wallet!.wallets.first.displayBalance
                              : '—'),
                  ),
                  const SizedBox(width: 8),
                  _Tile(
                    label: auth.isStaff ? 'Desk' : 'Saved',
                    value: auth.isStaff
                        ? 'Live'
                        : (_wallet?.goal?.displaySaved ?? '—'),
                  ),
                  const SizedBox(width: 8),
                  _Tile(
                    label: auth.isStaff ? 'Book' : 'Week',
                    value: auth.isStaff
                        ? 'Synthetic'
                        : (_wallet?.week.display ?? '—'),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (auth.isCustomer) ...[
          const SizedBox(height: 18),
          const _SectionLabel('Money'),
          const SizedBox(height: 8),
          SettingsPill(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Wallet home',
            subtitle: 'Balance, coach and recent activity',
            onTap: () => context.go('/home'),
          ),
          SettingsPill(
            icon: Icons.history_rounded,
            title: 'History',
            onTap: () => context.go('/activity'),
          ),
          SettingsPill(
            icon: Icons.donut_large_rounded,
            title: 'Insights',
            onTap: () => context.go('/insights'),
          ),
          SettingsPill(
            icon: Icons.receipt_long_rounded,
            title: 'Scan a slip',
            onTap: () => context.go('/receipts'),
          ),
          const SizedBox(height: 18),
          const _SectionLabel('Ask Shamwari'),
          const SizedBox(height: 8),
          SettingsPill(
            icon: Icons.auto_awesome_rounded,
            title: 'Open AI',
            subtitle: 'Chat, voice and money help',
            onTap: () => context.go('/chat'),
          ),
          SettingsPill(
            icon: Icons.mic_rounded,
            title: 'Voice pay',
            subtitle: 'Shona, Ndebele and English',
            onTap: () => context.go('/voice'),
          ),
          SettingsPill(
            icon: Icons.school_rounded,
            title: 'Financial coach',
            onTap: () => context.go('/coach'),
          ),
          SettingsPill(
            icon: Icons.shield_rounded,
            title: 'Scam checker',
            onTap: () => context.go('/scam'),
          ),
          SettingsPill(
            icon: Icons.dialpad_rounded,
            title: 'USSD *151#',
            onTap: () => context.go('/ussd'),
          ),
          const SizedBox(height: 18),
          const _SectionLabel('Access'),
          const SizedBox(height: 8),
          SettingsPill(
            icon: Icons.accessibility_new_rounded,
            title: 'Accessibility',
            subtitle: 'Type, contrast, spoken balances',
            onTap: () => context.go('/accessibility'),
          ),
          SettingsPill(
            icon: Icons.search_rounded,
            title: 'Search',
            onTap: () => context.go('/search'),
          ),
        ],
        if (auth.isStaff) ...[
          const SizedBox(height: 18),
          const _SectionLabel('Care tools'),
          const SizedBox(height: 8),
          SettingsPill(
            icon: Icons.fact_check_rounded,
            title: 'Audit log',
            onTap: () => context.go('/audit'),
          ),
          SettingsPill(
            icon: Icons.school_rounded,
            title: 'Onboarding buddy',
            onTap: () => context.go('/onboarding'),
          ),
          SettingsPill(
            icon: Icons.menu_book_rounded,
            title: 'Ledger',
            onTap: () => context.go('/ledger'),
          ),
          SettingsPill(
            icon: Icons.memory_rounded,
            title: 'AI log',
            onTap: () => context.go('/ai-log'),
          ),
          SettingsPill(
            icon: Icons.insights_rounded,
            title: 'Customer pulse',
            onTap: () => context.go('/pulse'),
          ),
          SettingsPill(
            icon: Icons.search_rounded,
            title: 'Search',
            onTap: () => context.go('/search'),
          ),
        ],
        const SizedBox(height: 18),
        const _SectionLabel('Preferences'),
        const SizedBox(height: 8),
        SettingsPill(
          icon: Icons.dark_mode_outlined,
          title: 'Dark mode',
          subtitle: 'A deeper navy version of this palette',
          trailing: Switch(
            value: settings.themeMode == ThemeMode.dark,
            onChanged: (value) => ref
                .read(settingsProvider.notifier)
                .setThemeMode(value ? ThemeMode.dark : ThemeMode.light),
          ),
        ),
        SettingsPill(
          icon: Icons.contrast_rounded,
          title: 'High contrast',
          subtitle: 'Black and yellow',
          trailing: Switch(
            value: settings.highContrast,
            onChanged: (value) =>
                ref.read(settingsProvider.notifier).setHighContrast(value),
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: palette.highContrast
              ? Colors.black
              : Colors.white.withValues(alpha: palette.lightGlass ? 0.55 : 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: palette.highContrast
                ? palette.border
                : Colors.white.withValues(alpha: 0.6),
          ),
        ),
        child: Column(
          children: [
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
            ),
            Text(
              label,
              style: TextStyle(color: palette.onCardMuted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
