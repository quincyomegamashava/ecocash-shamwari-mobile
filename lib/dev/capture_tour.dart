import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app.dart';
import '../core/demo/demo_controller.dart';
import '../core/router.dart';
import '../core/session/session.dart';
import 'capture_cue.dart';

class CaptureBootstrap extends ConsumerStatefulWidget {
  const CaptureBootstrap({super.key});

  @override
  ConsumerState<CaptureBootstrap> createState() => _CaptureBootstrapState();
}

class _CaptureBootstrapState extends ConsumerState<CaptureBootstrap> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      runCaptureTour(ref);
    });
  }

  @override
  Widget build(BuildContext context) => const ShamwariApp();
}

Future<void> runCaptureTour(WidgetRef ref) async {
  final tour = Directory('/tmp/shamwari-tour');
  if (tour.existsSync()) tour.deleteSync(recursive: true);
  tour.createSync(recursive: true);
  try {
    for (var i = 0; i < 80; i++) {
      if (ref.read(authProvider).ready) break;
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    if (ref.read(authProvider).signedIn) {
      await ref.read(authProvider.notifier).logout();
    }
    final settings = ref.read(settingsProvider.notifier);
    _trace('mock');
    await settings.setMockMode(true);
    await settings.setHighContrast(false);
    await settings.setThemeMode(ThemeMode.light);
    _trace('theme ready mock=${ref.read(settingsProvider).mockMode}');

    final only = Platform.environment['SHAMWARI_CAPTURE_ONLY'];
    if (only == null || only == 'default') {
      await _shot('default-login');
      await _gallery(ref, 'default', contrast: false);
      await _signOut(ref);
    }
    if (only == null || only == 'dark') {
      await settings.setThemeMode(ThemeMode.dark);
      await _shot('dark-login');
      await _gallery(ref, 'dark', contrast: false);
      await _signOut(ref);
      await settings.setThemeMode(ThemeMode.light);
    }
    if (only == null || only == 'contrast') {
      await settings.setHighContrast(true);
      await _shot('contrast-login');
      await _gallery(ref, 'contrast', contrast: true);
      await _signOut(ref);
      await settings.setHighContrast(false);
    }
    await settings.setThemeMode(ThemeMode.light);
    await settings.setMockMode(false);
    await File('${tour.path}/done').writeAsString('ok');
  } catch (error, stack) {
    await File(
      '${tour.path}/error',
    ).writeAsString('$error\n$stack');
    exitCode = 1;
  }
}

Future<void> _gallery(
  WidgetRef ref,
  String prefix, {
  required bool contrast,
}) async {
  final router = ref.read(routerProvider);
  _trace('$prefix login rudo');
  await ref.read(authProvider.notifier).login('rudo', 'rudo-demo');
  _trace('$prefix rudo in');
  await Future<void>.delayed(const Duration(milliseconds: 300));
  await ref
      .read(shamwariApiProvider)
      .updateAccessibility(
        largeType: false,
        highContrast: contrast,
        speakBalances: false,
      );
  await Future<void>.delayed(const Duration(milliseconds: 1200));
  await _shot('$prefix-home');

  if (prefix == 'default') {
    await _releaseHolds(ref);
    CaptureCue.ready.value = null;
    CaptureCue.phase.value = 'send-risk';
    router.go('/send');
    await _untilPhase('send-risk-ready');
    await _shot('default-send-risk');
    CaptureCue.phase.value = null;
    CaptureCue.ready.value = null;
    await _releaseHolds(ref);
    // Leave /send so the PIN phase builds a fresh screen.
    await _open(router, '/home');
  }

  CaptureCue.phase.value = 'pin';
  router.go('/send');
  await _untilPhase('pin-ready');
  await _shot('$prefix-send-pin');

  CaptureCue.phase.value = 'voice';
  await _open(router, '/voice');
  await _untilPhase('voice-ready');
  await _shot('$prefix-voice');
  if (prefix == 'default') {
    // The PIN shot holds US$20. Prize Desk is US$80, so release that hold
    // or the warning never opens.
    await _releaseHolds(ref);
    await _open(router, '/home');
    CaptureCue.phase.value = 'risk';
    router.go('/voice');
    await _untilPhase('risk-ready');
    await _shot('default-risk');
    CaptureCue.phase.value = null;
    CaptureCue.ready.value = null;
    await _releaseHolds(ref);
    CaptureCue.ready.value = null;
    CaptureCue.phase.value = 'success';
    router.go('/send');
    await _untilPhase('success-ready');
    await _shot('default-success');
    CaptureCue.phase.value = null;
    CaptureCue.ready.value = null;
    await _open(router, '/chat');
    await _shot('default-chat');
    await _open(router, '/ussd');
    await _shot('default-ussd');
  }

  CaptureCue.phase.value = 'coach';
  router.go('/coach');
  await _untilPhase('coach-ready');
  await _shot('$prefix-coach');

  CaptureCue.phase.value = 'scam';
  router.go('/scam');
  await _untilPhase('scam-ready');
  await _shot('$prefix-scam');

  CaptureCue.phase.value = null;
  for (final route in [
    '/insights',
    '/receipts',
    '/accessibility',
    '/activity',
    '/search',
    '/profile',
  ]) {
    await _open(router, route);
    await _shot('$prefix-${route.substring(1)}');
  }

  await _signOut(ref);
  ref.read(mockBackendProvider).clearDecisions();
  await ref.read(authProvider.notifier).login('care', 'care-demo');
  await Future<void>.delayed(const Duration(milliseconds: 1200));
  await _shot('$prefix-pulse');
  if (prefix == 'default') {
    await _open(router, '/pulse/case/58');
    await _shot('default-copilot');
    await _open(router, '/audit');
    await _shot('default-audit');
  }
  for (final route in ['/onboarding', '/ledger', '/ai-log']) {
    await _open(router, route);
    await _shot('$prefix-${route.substring(1)}');
  }

  await _signOut(ref);
  await ref
      .read(authProvider.notifier)
      .login('rudo', 'rudo-demo', landing: '/voice');
  await ref.read(demoProvider.notifier).start();
  await Future<void>.delayed(const Duration(milliseconds: 900));
  await _shot('$prefix-demo');
  await ref.read(demoProvider.notifier).stop();
}

Future<void> _releaseHolds(WidgetRef ref) async {
  final api = ref.read(shamwariApiProvider);
  final rows = await api.transactions(limit: 30);
  for (final txn in rows) {
    if (txn.status == 'pending') {
      await api.cancelTransfer(txn.id);
      _trace('released ${txn.id}');
    }
  }
}

Future<void> _signOut(WidgetRef ref) async {
  if (ref.read(authProvider).signedIn) {
    await ref.read(authProvider.notifier).logout();
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }
}

Future<void> _untilPhase(String phase) async {
  for (var i = 0; i < 100; i++) {
    final matched =
        CaptureCue.phase.value == phase || CaptureCue.ready.value == phase;
    if (matched) {
      final epoch = CaptureCue.epoch;
      final ready = CaptureCue.ready.value;
      final current = CaptureCue.phase.value;
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (CaptureCue.epoch == epoch &&
          CaptureCue.ready.value == ready &&
          CaptureCue.phase.value == current) {
        return;
      }
      continue;
    }
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  throw StateError(
    'Timed out waiting for $phase (phase ${CaptureCue.phase.value}, ready ${CaptureCue.ready.value}, epoch ${CaptureCue.epoch})',
  );
}

int _shotSeq = 0;

Future<void> _open(GoRouter router, String route) async {
  router.go(route);
  for (var i = 0; i < 40; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (router.routeInformationProvider.value.uri.path == route) break;
  }
  // Let the new screen load and paint before the grabber is allowed to shoot.
  await Future<void>.delayed(const Duration(milliseconds: 900));
}

void _trace(String message) {
  File('/tmp/shamwari-tour/trace').writeAsStringSync(
    '$message\n',
    mode: FileMode.append,
  );
}

Future<void> _shot(String name) async {
  _trace('shot $name');
  _shotSeq += 1;
  final token = '$_shotSeq $name';
  final tmp = File('/tmp/shamwari-tour/step.tmp');
  await tmp.writeAsString(token);
  await tmp.rename('/tmp/shamwari-tour/step');
  final ack = File('/tmp/shamwari-tour/ack');
  for (var i = 0; i < 120; i++) {
    if (ack.existsSync() && (await ack.readAsString()).trim() == token) return;
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  throw StateError('No screenshot ack for $name');
}
