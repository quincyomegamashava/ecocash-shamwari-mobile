import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/demo/demo_controller.dart';
import 'core/router.dart';
import 'core/session/session.dart';
import 'core/theme/shamwari_theme.dart';

class ShamwariApp extends ConsumerWidget {
  const ShamwariApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final router = ref.watch(routerProvider);
    ref.listen(authProvider, (previous, next) {
      ref.read(demoProvider.notifier).onAuthChanged(next);
    });
    final palette = settings.highContrast
        ? ShamwariPalette.contrast
        : settings.themeMode == ThemeMode.light
        ? ShamwariPalette.light
        : ShamwariPalette.dark;
    final theme = shamwariTheme(palette);
    return MaterialApp.router(
      title: 'Shamwari',
      debugShowCheckedModeBanner: false,
      theme: theme,
      darkTheme: settings.highContrast
          ? theme
          : shamwariTheme(ShamwariPalette.dark),
      themeMode: settings.highContrast ? ThemeMode.dark : settings.themeMode,
      routerConfig: router,
      builder: (context, child) {
        final media = MediaQuery.of(context);
        final boost = settings.largeType || settings.highContrast;
        final scaler = boost
            ? media.textScaler.clamp(minScaleFactor: 1.15, maxScaleFactor: 1.8)
            : media.textScaler;
        return MediaQuery(
          data: media.copyWith(textScaler: scaler),
          child: RepaintBoundary(
            key: const Key('shamwari-shot'),
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}
