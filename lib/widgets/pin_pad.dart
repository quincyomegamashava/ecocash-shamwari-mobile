import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/shamwari_theme.dart';

/// Four-digit pad. The digits are kept by the parent and are not rendered as text.
class PinPad extends StatelessWidget {
  const PinPad({
    super.key,
    required this.pin,
    required this.onChanged,
    this.length = 4,
  });

  final String pin;
  final ValueChanged<String> onChanged;
  final int length;

  void _push(String digit) {
    if (pin.length >= length) return;
    HapticFeedback.selectionClick();
    onChanged(pin + digit);
  }

  void _pop() {
    if (pin.isEmpty) return;
    HapticFeedback.selectionClick();
    onChanged(pin.substring(0, pin.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Semantics(
      label: 'Payment PIN. ${pin.length} of $length digits entered.',
      child: Column(
        key: const Key('pin-pad'),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(length, (index) {
              final filled = index < pin.length;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                margin: const EdgeInsets.symmetric(horizontal: 8),
                width: filled ? 16 : 14,
                height: filled ? 16 : 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: filled ? palette.orange : Colors.transparent,
                  border: Border.all(
                    color: filled ? palette.orange : context.inkMuted,
                    width: 1.6,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          for (final row in const [
            ['1', '2', '3'],
            ['4', '5', '6'],
            ['7', '8', '9'],
            ['', '0', 'del'],
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  for (final key in row)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: key.isEmpty
                            ? const SizedBox(height: 56)
                            : _Key(
                                label: key == 'del' ? '⌫' : key,
                                onTap: key == 'del' ? _pop : () => _push(key),
                              ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: palette.highContrast
          ? Colors.black
          : palette.bg.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: palette.border,
          width: palette.highContrast ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 56,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: context.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
