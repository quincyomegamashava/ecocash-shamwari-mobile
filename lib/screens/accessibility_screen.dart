import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/api_exception.dart';
import '../core/models/models.dart';
import '../core/session/session.dart';
import '../core/theme/shamwari_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/sage_ui.dart';
import '../widgets/states.dart';

class AccessibilityScreen extends ConsumerStatefulWidget {
  const AccessibilityScreen({super.key});

  @override
  ConsumerState<AccessibilityScreen> createState() =>
      _AccessibilityScreenState();
}

class _AccessibilityScreenState extends ConsumerState<AccessibilityScreen> {
  AccessState? _state;
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final pace = ref.read(loadPaceProvider);
      final state = await ref.read(shamwariApiProvider).accessibility();
      await Future<void>.delayed(pace);
      if (!mounted) return;
      await ref.read(settingsProvider.notifier).applyAccess(state.settings);
      setState(() {
        _state = state;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  Future<void> _update({bool? large, bool? contrast, bool? speak}) async {
    final settings = ref.read(settingsProvider);
    final nextLarge = large ?? settings.largeType;
    final nextContrast = contrast ?? settings.highContrast;
    final nextSpeak = speak ?? settings.speakBalances;
    await ref
        .read(settingsProvider.notifier)
        .applyAccess(
          AccessSettings(
            largeType: nextLarge,
            highContrast: nextContrast,
            speakBalances: nextSpeak,
          ),
        );
    try {
      await ref
          .read(shamwariApiProvider)
          .updateAccessibility(
            largeType: nextLarge,
            highContrast: nextContrast,
            speakBalances: nextSpeak,
          );
      await _load();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(friendlyError(error))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    if (_loading && _state == null) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: SkeletonColumn(),
      );
    }
    if (_error != null && _state == null) {
      return ErrorPane(error: _error!, onRetry: _load);
    }
    final spoken = _state?.spoken ?? '';
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
        children: [
          const SectionLabel('Accessibility'),
          Text(
            'Easier to see. Easier to hear.',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          Text(
            'High contrast paints the whole app black and yellow. These switches are stored for Rudo, not only on this phone.',
            style: TextStyle(color: context.inkMuted, height: 1.35),
          ),
          const SizedBox(height: 16),
          const Text(
            'Preferences',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          SettingsPill(
            icon: Icons.format_size_rounded,
            title: 'Large type',
            trailing: Switch(
              value: settings.largeType,
              onChanged: (value) => _update(large: value),
            ),
          ),
          SettingsPill(
            icon: Icons.contrast_rounded,
            title: 'High contrast',
            subtitle: 'Overrides sage and dark.',
            trailing: Switch(
              value: settings.highContrast,
              onChanged: (value) => _update(contrast: value),
            ),
          ),
          SettingsPill(
            icon: Icons.volume_up_rounded,
            title: 'Speak balances',
            trailing: Switch(
              value: settings.speakBalances,
              onChanged: (value) => _update(speak: value),
            ),
          ),
          const SizedBox(height: 8),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionLabel('Spoken'),
                const SizedBox(height: 6),
                Text(
                  spoken.isEmpty
                      ? 'Speak balances is off, so this line stays quiet.'
                      : spoken,
                  style: TextStyle(
                    fontSize: settings.largeType ? 18 : 16,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const SectionLabel('QR, read aloud'),
          const SizedBox(height: 8),
          for (final qr in _state?.qrSamples ?? const <QrSample>[])
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      qr.title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      qr.payload,
                      style: TextStyle(color: context.inkMuted, height: 1.35),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
