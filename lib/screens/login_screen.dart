import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/api_exception.dart';
import '../core/demo/demo_controller.dart';
import '../core/session/session.dart';
import '../core/theme/shamwari_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/mark.dart';
import '../widgets/sage_ui.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _lan = TextEditingController();
  bool _busy = false;
  bool _obscure = true;
  String? _error;
  String? _health;

  @override
  void initState() {
    super.initState();
    _lan.text = ref.read(settingsProvider).lanIp;
  }

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _lan.dispose();
    super.dispose();
  }

  Future<void> _signIn({String? landing}) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(authProvider.notifier)
          .login(_username.text, _password.text, landing: landing);
      if (landing == '/voice') {
        await ref.read(demoProvider.notifier).start();
      }
    } catch (error) {
      if (mounted) setState(() => _error = friendlyError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _fill(String username, String password) {
    setState(() {
      _username.text = username;
      _password.text = password;
      _error = null;
    });
  }

  Future<void> _probe() async {
    setState(() => _health = 'Checking…');
    try {
      final health = await ref.read(shamwariApiProvider).health();
      final settings = ref.read(settingsProvider);
      setState(() {
        _health = settings.mockMode
            ? 'Offline mock is on. ${health.customers} synthetic customers. No server was called.'
            : 'Reached ${settings.baseUrl}. ${health.aiLabel} · ${health.customers} customers.';
      });
    } catch (error) {
      setState(() => _health = friendlyError(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final settings = ref.watch(settingsProvider);
    return ShamwariBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              Row(
                children: [
                  const ShamwariMark(size: 42),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Shamwari',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          'A friend in the wallet',
                          style: TextStyle(color: context.inkMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  GlassIconButton(
                    tooltip: settings.themeMode == ThemeMode.dark
                        ? 'Light mode'
                        : 'Dark mode',
                    icon: settings.themeMode == ThemeMode.dark
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined,
                    onPressed: () => ref
                        .read(settingsProvider.notifier)
                        .setThemeMode(
                          settings.themeMode == ThemeMode.dark
                              ? ThemeMode.light
                              : ThemeMode.dark,
                        ),
                  ),
                  const SizedBox(width: 8),
                  GlassIconButton(
                    tooltip: 'Accessibility',
                    icon: Icons.accessibility_new_rounded,
                    filled: settings.highContrast,
                    onPressed: () => ref
                        .read(settingsProvider.notifier)
                        .setHighContrast(!settings.highContrast),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [HackathonPill(), PrototypeChip()],
              ),
              const SizedBox(height: 16),
              Text(
                'The wallet that\nwaits for yes.',
                style: Theme.of(context).textTheme.displayLarge,
              ),
              const SizedBox(height: 10),
              Text(
                'A friend inside a synthetic EcoCash book. Voice in Shona, Ndebele and English. Money does not move until a person confirms it.',
                style: TextStyle(color: context.inkMuted, height: 1.4),
              ),
              const SizedBox(height: 16),
              const _PreviewCard(),
              const SizedBox(height: 14),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionLabel('Sign in'),
                    const SizedBox(height: 6),
                    Text(
                      'Choose a demo desk.',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Every account is fictional. Passwords are stored hashed on the server. This form does not send a CSRF token.',
                      style: TextStyle(color: context.inkMuted, fontSize: 13),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      key: const Key('username'),
                      controller: _username,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        hintText: 'Username',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      key: const Key('password'),
                      controller: _password,
                      obscureText: _obscure,
                      onSubmitted: (_) => _busy ? null : _signIn(),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: 'Password',
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _obscure = !_obscure),
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        _error!,
                        style: TextStyle(
                          color: palette.danger,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        key: const Key('sign-in'),
                        onPressed: _busy ? null : () => _signIn(),
                        child: Text(_busy ? 'Signing in…' : 'Sign in'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const SectionLabel('Demo accounts'),
              const SizedBox(height: 8),
              _DeskCard(
                key: const Key('desk-rudo'),
                title: 'Customer',
                account: 'rudo · rudo-demo',
                body: 'Wallet, voice pay, coach and scam checker.',
                onTap: () => _fill('rudo', 'rudo-demo'),
              ),
              const SizedBox(height: 8),
              _DeskCard(
                key: const Key('desk-care'),
                title: 'Care team',
                account: 'care · care-demo',
                body: 'Dashboards, customer pulse and the onboarding buddy.',
                onTap: () => _fill('care', 'care-demo'),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  key: const Key('walk-morning'),
                  onPressed: _busy
                      ? null
                      : () {
                          _fill('rudo', 'rudo-demo');
                          _signIn(landing: '/voice');
                        },
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text("Walk Rudo's morning"),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Guided demo signs in as Rudo and opens every module. The last two steps are the care desk.',
                style: TextStyle(color: context.inkMuted, fontSize: 12),
              ),
              const SizedBox(height: 16),
              GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Theme(
                  data: Theme.of(context)
                      .copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    title: const Text('Server'),
                    subtitle: Text(
                      settings.mockMode ? 'Offline mock' : settings.baseUrl,
                      style: TextStyle(color: context.inkMuted, fontSize: 12),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ActionChip(
                                  label: const Text('Android emulator'),
                                  onPressed: () => ref
                                      .read(settingsProvider.notifier)
                                      .setBaseUrl('http://10.0.2.2:8642'),
                                ),
                                ActionChip(
                                  label: const Text('iOS simulator'),
                                  onPressed: () => ref
                                      .read(settingsProvider.notifier)
                                      .setBaseUrl('http://127.0.0.1:8642'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _lan,
                              decoration: const InputDecoration(
                                labelText: 'LAN IP for a real phone',
                                hintText: '192.168.1.20',
                              ),
                              onSubmitted: (value) => ref
                                  .read(settingsProvider.notifier)
                                  .setLanIp(value),
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton(
                                onPressed: () => ref
                                    .read(settingsProvider.notifier)
                                    .setLanIp(_lan.text),
                                child: const Text('Use this LAN address'),
                              ),
                            ),
                            Text(
                              'Base URL  ${settings.baseUrl}',
                              style: TextStyle(
                                color: context.inkMuted,
                                fontSize: 12,
                              ),
                            ),
                            SwitchListTile(
                              key: const Key('mock-mode'),
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Offline mock'),
                              subtitle: const Text(
                                'Synthetic responses that match the contract. No Flask server required.',
                              ),
                              value: settings.mockMode,
                              onChanged: (value) => ref
                                  .read(settingsProvider.notifier)
                                  .setMockMode(value),
                            ),
                            OutlinedButton(
                              onPressed: _probe,
                              child: const Text('Test connection'),
                            ),
                            if (_health != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                _health!,
                                style: TextStyle(color: context.inkMuted),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return GlassCard(
      radius: 30,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rudo Moyo · Mbare',
            style: TextStyle(color: palette.onCardMuted, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            'US\$ 86.00',
            style: TextStyle(
              color: palette.onCard,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
            ),
          ),
          Text(
            'ZiG 420.00 on the second wallet',
            style: TextStyle(color: palette.onCardMuted),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              for (final item in const [
                (Icons.arrow_outward_rounded, 'Send'),
                (Icons.storefront_rounded, 'Pay'),
                (Icons.add_card_rounded, 'Top-up'),
                (Icons.call_received_rounded, 'Request'),
              ])
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: palette.highContrast ? Colors.black : Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: palette.highContrast
                          ? palette.border
                          : palette.forest.withValues(alpha: 0.16),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.$1,
                        size: 14,
                        color: palette.highContrast
                            ? palette.orange
                            : palette.forest,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.$2,
                        style: TextStyle(
                          color: palette.highContrast
                              ? palette.orange
                              : palette.forest,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DeskCard extends StatelessWidget {
  const _DeskCard({
    super.key,
    required this.title,
    required this.account,
    required this.body,
    required this.onTap,
  });

  final String title;
  final String account;
  final String body;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          Text(
            account,
            style: TextStyle(
              color: palette.teal,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(body, style: TextStyle(color: context.inkMuted, fontSize: 13)),
        ],
      ),
    );
  }
}
