import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_exception.dart';
import '../models/models.dart';
import '../router.dart';
import '../session/session.dart';

class DemoState {
  const DemoState({this.script, this.busy = false, this.error});

  final DemoScript? script;
  final bool busy;
  final String? error;

  bool get active => script?.active ?? false;
}

class DemoController extends Notifier<DemoState> {
  String? _loadedFor;

  @override
  DemoState build() => const DemoState();

  Future<T> _run<T>(Future<T> Function() body) async {
    state = DemoState(script: state.script, busy: true);
    try {
      return await body();
    } catch (error) {
      state = DemoState(script: state.script, error: friendlyError(error));
      rethrow;
    }
  }

  void onAuthChanged(AuthState auth) {
    if (!auth.signedIn) {
      _loadedFor = null;
      state = const DemoState();
      return;
    }
    if (_loadedFor == auth.token) return;
    _loadedFor = auth.token;
    refresh();
  }

  Future<void> refresh() async {
    if (!ref.read(authProvider).signedIn) return;
    await _run(() async {
      final script = await ref.read(shamwariApiProvider).demo();
      state = DemoState(script: script);
    });
  }

  Future<void> start() => _mutate((api) => api.demoStart(), go: true);

  Future<void> next() => _mutate((api) => api.demoNext(), go: true);

  Future<void> back() => _mutate((api) => api.demoBack(), go: true);

  Future<void> stop() => _mutate((api) => api.demoStop());

  Future<void> _mutate(
    Future<DemoScript> Function(dynamic api) call, {
    bool go = false,
  }) async {
    if (!ref.read(authProvider).signedIn) return;
    await _run(() async {
      final script = await call(ref.read(shamwariApiProvider));
      state = DemoState(script: script);
      if (!go) return;
      final step = script.current;
      final auth = ref.read(authProvider);
      if (step == null) return;
      final role = auth.isStaff ? 'staff' : 'customer';
      if (step.role == role) {
        ref.read(routerProvider).go(routeForSlug(step.slug));
      }
    });
  }

  Future<void> walkMorning() async {
    final auth = ref.read(authProvider);
    if (!auth.isCustomer) {
      await ref
          .read(authProvider.notifier)
          .login('rudo', 'rudo-demo', landing: '/voice');
    }
    await start();
    final step = state.script?.current;
    if (step != null && step.role == 'customer') {
      ref.read(routerProvider).go(routeForSlug(step.slug));
    }
  }

  /// Demo progress is stored on the bearer token. The care steps need the care token.
  Future<void> continueAsCare() async {
    final target = state.script?.current?.slug ?? 'pulse';
    await ref
        .read(authProvider.notifier)
        .login('care', 'care-demo', landing: routeForSlug(target));
    await start();
    for (var i = 0; i < 8; i++) {
      final slug = state.script?.current?.slug;
      if (slug == target) break;
      await next();
    }
    ref.read(routerProvider).go(routeForSlug(target));
  }
}

final demoProvider = NotifierProvider<DemoController, DemoState>(
  DemoController.new,
);
