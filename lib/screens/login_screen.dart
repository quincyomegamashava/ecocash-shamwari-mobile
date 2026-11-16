import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/api_exception.dart';
import '../core/demo/demo_controller.dart';
import '../core/layout.dart';
import '../core/session/session.dart';
import '../core/session/stores.dart';
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
  bool _demos = false;
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

  void _openServer() {
    final settings = ref.read(settingsProvider);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            0,
            20,
            24 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Consumer(
            builder: (context, ref, _) {
              final live = ref.watch(settingsProvider);
              return ListView(
                shrinkWrap: true,
                children: [
                  const Text(
                    'Server',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    live.mockMode ? 'Offline mock' : live.baseUrl,
                    style: TextStyle(color: context.inkMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ActionChip(
                        label: const Text('Production'),
                        onPressed: () => ref
                            .read(settingsProvider.notifier)
                            .setBaseUrl(defaultBaseUrl),
                      ),
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
                    onSubmitted: (value) =>
                        ref.read(settingsProvider.notifier).setLanIp(value),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () => ref
                          .read(settingsProvider.notifier)
                          .setLanIp(_lan.text),
                      child: const Text('Use this LAN address'),
                    ),
                  ),
                  SwitchListTile(
                    key: const Key('mock-mode'),
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Offline mock'),
                    subtitle: const Text(
                      'Synthetic responses that match the contract. No Flask server required.',
                    ),
                    value: live.mockMode,
                    onChanged: (value) =>
                        ref.read(settingsProvider.notifier).setMockMode(value),
                  ),
                  OutlinedButton(
                    onPressed: _probe,
                    child: const Text('Test connection'),
                  ),
                  if (_health != null) ...[
                    const SizedBox(height: 8),
                    Text(_health!, style: TextStyle(color: context.inkMuted)),
                  ],
                ],
              );
            },
          ),
        );
      },
    );
    // settings is read so the sheet opens against the current host.
    assert(settings.baseUrl.isNotEmpty);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return ShamwariBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Stack(
            children: [
              ConstrainedContent(
                maxWidth: 480,
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    context.isCompact ? 20 : 28,
                    context.isCompact ? 56 : 72,
                    context.isCompact ? 20 : 28,
                    28,
                  ),
                  children: [
                    const Center(child: ShamwariMark(size: 64)),
                    const SizedBox(height: 16),
                    Text(
                      'Shamwari',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.6,
                          ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    'The wallet that waits for yes.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: context.inkMuted,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 28),
                  GlassCard(
                    radius: 32,
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Welcome back',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: palette.onCard,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Sign in to your EcoCash wallet.',
                          style: TextStyle(
                            color: palette.onCardMuted,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 18),
                        TextField(
                          key: const Key('username'),
                          controller: _username,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Username',
                            hintText: 'Username',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          key: const Key('password'),
                          controller: _password,
                          obscureText: _obscure,
                          onSubmitted: (_) => _busy ? null : _signIn(),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            hintText: 'Password',
                            suffixIcon: IconButton(
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _error!,
                            style: TextStyle(
                              color: palette.danger,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            key: const Key('sign-in'),
                            onPressed: _busy ? null : () => _signIn(),
                            child: Text(_busy ? 'Signing in…' : 'Sign in'),
                          ),
                        ),
                        Center(
                          child: TextButton(
                            key: const Key('demo-accounts'),
                            onPressed: () => setState(() => _demos = !_demos),
                            child: const Text('Demo accounts'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_demos) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Choose a demo desk.',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
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
                      body: 'Pulse, copilot and the onboarding buddy.',
                      onTap: () => _fill('care', 'care-demo'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
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
                  ],
                ],
              ),
            ),
              Positioned(
                top: 8,
                right: 12,
                child: GlassIconButton(
                  tooltip: 'Server settings',
                  icon: Icons.settings_outlined,
                  onPressed: _openServer,
                ),
              ),
            ],
          ),
        ),
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
