import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/mock_backend.dart';
import '../api/shamwari_api.dart';
import '../api/dio_api.dart';
import '../models/models.dart';
import 'stores.dart';

final prefsStoreProvider = Provider<PrefsStore>((ref) {
  throw StateError('PrefsStore is provided at startup.');
});

final tokenStoreProvider = Provider<TokenStore>((ref) => SecureTokenStore());

final loadPaceProvider = Provider<Duration>(
  (ref) => const Duration(milliseconds: 380),
);

final mockBackendProvider = Provider<MockBackend>((ref) => MockBackend());

class SettingsState {
  const SettingsState({
    required this.mockMode,
    required this.baseUrl,
    required this.lanIp,
    required this.themeMode,
    required this.highContrast,
    required this.largeType,
    required this.speakBalances,
  });

  final bool mockMode;
  final String baseUrl;
  final String lanIp;
  final ThemeMode themeMode;
  final bool highContrast;
  final bool largeType;
  final bool speakBalances;

  SettingsState copyWith({
    bool? mockMode,
    String? baseUrl,
    String? lanIp,
    ThemeMode? themeMode,
    bool? highContrast,
    bool? largeType,
    bool? speakBalances,
  }) {
    return SettingsState(
      mockMode: mockMode ?? this.mockMode,
      baseUrl: baseUrl ?? this.baseUrl,
      lanIp: lanIp ?? this.lanIp,
      themeMode: themeMode ?? this.themeMode,
      highContrast: highContrast ?? this.highContrast,
      largeType: largeType ?? this.largeType,
      speakBalances: speakBalances ?? this.speakBalances,
    );
  }
}

class SettingsController extends Notifier<SettingsState> {
  @override
  SettingsState build() {
    final prefs = ref.read(prefsStoreProvider);
    final theme = prefs.getString('theme') == 'dark'
        ? ThemeMode.dark
        : ThemeMode.light;
    return SettingsState(
      mockMode: prefs.getBool('mock_mode') ?? false,
      baseUrl: normalizeBaseUrl(prefs.getString('base_url') ?? defaultBaseUrl),
      lanIp: prefs.getString('lan_ip') ?? '',
      themeMode: theme,
      highContrast: prefs.getBool('high_contrast') ?? false,
      largeType: prefs.getBool('large_type') ?? false,
      speakBalances: prefs.getBool('speak_balances') ?? true,
    );
  }

  Future<void> setMockMode(bool value) async {
    state = state.copyWith(mockMode: value);
    await ref.read(prefsStoreProvider).setBool('mock_mode', value);
  }

  Future<void> setBaseUrl(String value) async {
    final next = normalizeBaseUrl(value);
    state = state.copyWith(baseUrl: next);
    await ref.read(prefsStoreProvider).setString('base_url', next);
  }

  Future<void> setLanIp(String value) async {
    state = state.copyWith(lanIp: value.trim());
    await ref.read(prefsStoreProvider).setString('lan_ip', value.trim());
    if (value.trim().isNotEmpty) {
      await setBaseUrl('http://${value.trim()}:8642');
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await ref
        .read(prefsStoreProvider)
        .setString('theme', mode == ThemeMode.light ? 'light' : 'dark');
  }

  Future<void> setHighContrast(bool value) async {
    state = state.copyWith(highContrast: value);
    await ref.read(prefsStoreProvider).setBool('high_contrast', value);
  }

  Future<void> setLargeType(bool value) async {
    state = state.copyWith(largeType: value);
    await ref.read(prefsStoreProvider).setBool('large_type', value);
  }

  Future<void> setSpeakBalances(bool value) async {
    state = state.copyWith(speakBalances: value);
    await ref.read(prefsStoreProvider).setBool('speak_balances', value);
  }

  Future<void> applyAccess(AccessSettings settings) async {
    state = state.copyWith(
      highContrast: settings.highContrast,
      largeType: settings.largeType,
      speakBalances: settings.speakBalances,
    );
    final prefs = ref.read(prefsStoreProvider);
    await prefs.setBool('high_contrast', settings.highContrast);
    await prefs.setBool('large_type', settings.largeType);
    await prefs.setBool('speak_balances', settings.speakBalances);
  }
}

final settingsProvider = NotifierProvider<SettingsController, SettingsState>(
  SettingsController.new,
);

class AuthState {
  const AuthState({
    required this.ready,
    this.token,
    this.user,
    this.customer,
    this.landing,
  });

  final bool ready;
  final String? token;
  final UserAccount? user;
  final CustomerProfile? customer;
  final String? landing;

  bool get signedIn => token != null && user != null;
  bool get isStaff => user?.isStaff ?? false;
  bool get isCustomer => user?.isCustomer ?? false;

  factory AuthState.booting() => const AuthState(ready: false);
  factory AuthState.signedOut() => const AuthState(ready: true);

  AuthState copyWith({
    bool? ready,
    String? token,
    UserAccount? user,
    CustomerProfile? customer,
    String? landing,
    bool clearSession = false,
    bool clearLanding = false,
  }) {
    return AuthState(
      ready: ready ?? this.ready,
      token: clearSession ? null : (token ?? this.token),
      user: clearSession ? null : (user ?? this.user),
      customer: clearSession ? null : (customer ?? this.customer),
      landing: clearLanding ? null : (landing ?? this.landing),
    );
  }
}

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    Future.microtask(restore);
    return AuthState.booting();
  }

  Future<void> restore() async {
    final token = await ref.read(tokenStoreProvider).read();
    if (token == null || token.isEmpty) {
      state = AuthState.signedOut();
      return;
    }
    try {
      final settings = ref.read(settingsProvider);
      if (settings.mockMode) {
        final username = ref.read(prefsStoreProvider).getString('mock_user');
        if (username != null && username.isNotEmpty) {
          ref.read(mockBackendProvider).adopt(token, username);
        }
      }
      final me = await ref.read(shamwariApiProvider).me();
      state = AuthState(
        ready: true,
        token: token,
        user: me.user,
        customer: me.customer,
      );
    } catch (_) {
      try {
        await ref.read(tokenStoreProvider).clear();
      } catch (_) {}
      state = AuthState.signedOut();
    }
  }

  Future<void> login(
    String username,
    String password, {
    String? landing,
  }) async {
    final result = await ref
        .read(shamwariApiProvider)
        .login(username.trim(), password)
        .timeout(const Duration(seconds: 8));
    try {
      await ref.read(tokenStoreProvider).write(result.token);
    } catch (_) {
      // The keyring can be missing on a desktop build. The session token
      // still lives in memory until the next launch.
    }
    if (ref.read(settingsProvider).mockMode) {
      await ref
          .read(prefsStoreProvider)
          .setString('mock_user', result.user.username);
      ref.read(mockBackendProvider).attach(result.token);
    }
    final me = await ref.read(shamwariApiProvider).me();
    state = AuthState(
      ready: true,
      token: result.token,
      user: me.user,
      customer: me.customer,
      landing: landing,
    );
  }

  Future<void> logout() async {
    try {
      await ref.read(shamwariApiProvider).logout();
    } catch (_) {}
    try {
      await ref.read(tokenStoreProvider).clear();
    } catch (_) {}
    await ref.read(prefsStoreProvider).setString('mock_user', '');
    state = AuthState.signedOut();
  }
}

final authProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

final shamwariApiProvider = Provider<ShamwariApi>((ref) {
  final settings = ref.watch(settingsProvider);
  final mock = ref.watch(mockBackendProvider);
  mock.tokenReader = () => ref.read(authProvider).token;
  if (settings.mockMode) return mock;
  return DioShamwariApi(
    baseUrl: settings.baseUrl,
    token: () => ref.read(authProvider).token,
  );
});
