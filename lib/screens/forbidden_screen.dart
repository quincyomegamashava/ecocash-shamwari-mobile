import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/session/session.dart';
import '../core/theme/shamwari_theme.dart';

class ForbiddenScreen extends ConsumerWidget {
  const ForbiddenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final staff = ref.watch(authProvider).isStaff;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline_rounded, color: palette.orange, size: 40),
          const SizedBox(height: 12),
          Text(
            staff
                ? 'This desk is the customer side.'
                : 'This desk is for the care team.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            staff
                ? 'Sign in as Rudo to open the wallet.'
                : 'Sign in as care to open pulse, the buddy, and the ledger.',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.inkMuted),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => context.go(staff ? '/pulse' : '/chat'),
            child: Text(staff ? 'Back to pulse' : 'Back to AI'),
          ),
        ],
      ),
    );
  }
}
