import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../screens/accessibility_screen.dart';
import '../screens/activity_screen.dart';
import '../screens/ai_log_screen.dart';
import '../screens/audit_screen.dart';
import '../screens/care_places.dart';
import '../screens/chat_screen.dart';
import '../screens/coach_screen.dart';
import '../screens/copilot_screen.dart';
import '../screens/forbidden_screen.dart';
import '../screens/insights_screen.dart';
import '../screens/customer_home_screen.dart';
import '../screens/ledger_screen.dart';
import '../screens/login_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/pulse_screen.dart';
import '../screens/receipts_screen.dart';
import '../screens/scam_screen.dart';
import '../screens/search_screen.dart';
import '../screens/send_money_screen.dart';
import '../screens/ussd_screen.dart';
import '../screens/voice_pay_screen.dart';
import '../widgets/app_shell.dart';
import '../widgets/mark.dart';
import 'session/session.dart';
import 'theme/shamwari_theme.dart';

const customerPaths = {
  '/home',
  '/send',
  '/voice',
  '/coach',
  '/scam',
  '/receipts',
  '/activity',
  '/accessibility',
  '/chat',
  '/ussd',
  '/insights',
};

const staffPaths = {
  '/pulse',
  '/onboarding',
  '/ledger',
  '/ai-log',
  '/audit',
  '/queue',
  '/impact',
  '/copilot',
};

bool isCustomerPath(String loc) => customerPaths.contains(loc);

bool isStaffPath(String loc) =>
    staffPaths.contains(loc) || loc.startsWith('/pulse/');

String routeForSlug(String slug) {
  switch (slug) {
    case 'voice':
      return '/voice';
    case 'access':
      return '/accessibility';
    case 'coach':
      return '/coach';
    case 'scam':
      return '/scam';
    case 'receipts':
      return '/receipts';
    case 'pulse':
      return '/pulse';
    case 'onboarding':
      return '/onboarding';
    default:
      return '/chat';
  }
}

String? routeForHit(String label, String? apiPath) {
  final path = apiPath ?? '';
  final lower = label.toLowerCase();
  if (lower.contains('walk rudo')) return '/demo';
  if (path.contains('/channels/chat') || lower.contains('chat channel')) {
    return '/chat';
  }
  if (path.contains('/channels/ussd') || lower.contains('ussd')) return '/ussd';
  if (path.contains('/audit')) return '/audit';
  if (path.contains('/impact')) return '/pulse';
  if (path.contains('/copilot')) return '/pulse';
  if (path.contains('/voice')) return '/voice';
  if (path.contains('/coach')) return '/coach';
  if (path.contains('/scam')) return '/scam';
  if (path.contains('/receipts')) return '/receipts';
  if (path.contains('/accessibility')) return '/accessibility';
  if (path.contains('/activity') ||
      path.contains('/wallet') ||
      path.contains('/transactions')) {
    return '/activity';
  }
  if (path.contains('/transfers')) return '/send';
  if (path.contains('/pulse')) return '/pulse';
  if (path.contains('/onboarding')) return '/onboarding';
  if (path.contains('/ledger')) return '/ledger';
  if (path.contains('/ai-log')) return '/ai-log';
  if (path.contains('/merchants')) return '/ledger';
  return null;
}

class _RouterRefresh extends ChangeNotifier {
  void ping() => notifyListeners();
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh();
  ref.onDispose(refresh.dispose);
  ref.listen(authProvider, (_, _) => refresh.ping());
  return GoRouter(
    initialLocation: '/boot',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final loc = state.matchedLocation;
      if (!auth.ready) return loc == '/boot' ? null : '/boot';
      if (!auth.signedIn) return loc == '/login' ? null : '/login';
      if (loc == '/boot' || loc == '/login') {
        return auth.landing ?? (auth.isStaff ? '/pulse' : '/chat');
      }
      if (auth.isStaff && isCustomerPath(loc)) return '/forbidden';
      if (!auth.isStaff && isStaffPath(loc)) return '/forbidden';
      return null;
    },
    routes: [
      GoRoute(path: '/boot', builder: (context, state) => const _BootScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      ShellRoute(
        pageBuilder: (context, state, child) {
          return NoTransitionPage<void>(
            key: const ValueKey('shamwari-shell'),
            child: AppShell(child: child),
          );
        },
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) =>
                _page(state, const CustomerHomeScreen()),
          ),
          GoRoute(
            path: '/send',
            pageBuilder: (context, state) =>
                _page(state, const SendMoneyScreen()),
          ),
          GoRoute(
            path: '/voice',
            pageBuilder: (context, state) =>
                _page(state, const VoicePayScreen()),
          ),
          GoRoute(
            path: '/coach',
            pageBuilder: (context, state) => _page(state, const CoachScreen()),
          ),
          GoRoute(
            path: '/scam',
            pageBuilder: (context, state) => _page(state, const ScamScreen()),
          ),
          GoRoute(
            path: '/receipts',
            pageBuilder: (context, state) =>
                _page(state, const ReceiptsScreen()),
          ),
          GoRoute(
            path: '/activity',
            pageBuilder: (context, state) =>
                _page(state, const ActivityScreen()),
          ),
          GoRoute(
            path: '/insights',
            pageBuilder: (context, state) =>
                _page(state, const InsightsScreen()),
          ),
          GoRoute(
            path: '/queue',
            pageBuilder: (context, state) => _page(state, const QueueScreen()),
          ),
          GoRoute(
            path: '/copilot',
            pageBuilder: (context, state) =>
                _page(state, const CopilotHubScreen()),
          ),
          GoRoute(
            path: '/impact',
            pageBuilder: (context, state) =>
                _page(state, const ImpactScreen()),
          ),
          GoRoute(
            path: '/accessibility',
            pageBuilder: (context, state) =>
                _page(state, const AccessibilityScreen()),
          ),
          GoRoute(
            path: '/pulse',
            pageBuilder: (context, state) => _page(state, const PulseScreen()),
          ),
          GoRoute(
            path: '/pulse/case/:id',
            pageBuilder: (context, state) => _page(
              state,
              CopilotScreen(
                itemId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
              ),
            ),
          ),
          GoRoute(
            path: '/audit',
            pageBuilder: (context, state) => _page(state, const AuditScreen()),
          ),
          GoRoute(
            path: '/chat',
            pageBuilder: (context, state) =>
                _page(state, const ChatChannelScreen()),
          ),
          GoRoute(
            path: '/ussd',
            pageBuilder: (context, state) => _page(state, const UssdScreen()),
          ),
          GoRoute(
            path: '/onboarding',
            pageBuilder: (context, state) =>
                _page(state, const OnboardingScreen()),
          ),
          GoRoute(
            path: '/ledger',
            pageBuilder: (context, state) => _page(state, const LedgerScreen()),
          ),
          GoRoute(
            path: '/ai-log',
            pageBuilder: (context, state) => _page(state, const AiLogScreen()),
          ),
          GoRoute(
            path: '/search',
            pageBuilder: (context, state) => _page(state, const SearchScreen()),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) =>
                _page(state, const ProfileScreen()),
          ),
          GoRoute(
            path: '/forbidden',
            pageBuilder: (context, state) =>
                _page(state, const ForbiddenScreen()),
          ),
        ],
      ),
    ],
  );
});

CustomTransitionPage<void> _page(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    opaque: true,
    transitionDuration: const Duration(milliseconds: 220),
    reverseTransitionDuration: const Duration(milliseconds: 180),
    transitionsBuilder: (context, animation, secondary, child) {
      final reduce = MediaQuery.disableAnimationsOf(context);
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return _OpaquePage(
        child: reduce
            ? child
            : FadeTransition(
                opacity: curved,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.03, 0),
                    end: Offset.zero,
                  ).animate(curved),
                  child: child,
                ),
              ),
      );
    },
  );
}

/// Fills the route with the active palette before the screen paints.
///
/// A fade used to leave this slot transparent while the previous route was
/// still in the navigator, so home, coach and scam drew on top of each other.
class _OpaquePage extends StatelessWidget {
  const _OpaquePage({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ShamwariBackdrop(child: child);
  }
}

class _BootScreen extends StatelessWidget {
  const _BootScreen();

  @override
  Widget build(BuildContext context) {
    return ShamwariBackdrop(
      child: const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: ShamwariMark(size: 72)),
      ),
    );
  }
}
