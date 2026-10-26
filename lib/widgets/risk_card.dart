import 'package:flutter/material.dart';

import '../core/models/models.dart';
import '../core/theme/shamwari_theme.dart';
import 'glass_card.dart';

class RiskWarning extends StatelessWidget {
  const RiskWarning({
    super.key,
    required this.risk,
    required this.acknowledged,
    required this.onAcknowledge,
    required this.onCancel,
    this.busy = false,
  });

  final TxnRisk risk;
  final bool acknowledged;
  final VoidCallback onAcknowledge;
  final VoidCallback onCancel;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final score = risk.score == null ? '' : ' · score ${risk.score}';
    return GlassCard(
      key: const Key('risk-warning'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Scam warning · ${risk.level.toUpperCase()}$score',
            style: TextStyle(
              color: palette.warning,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            risk.requiresAck
                ? 'Read this before you confirm.'
                : 'Shamwari scored this payment before it can post.',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          const SizedBox(height: 8),
          for (final reason in risk.reasons)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('• ${reason.text}'),
            ),
          if (risk.requiresAck && !acknowledged) ...[
            const SizedBox(height: 8),
            Text(
              'High risk needs an extra confirmation. Cancelling here is logged as a blocked scam.',
              style: TextStyle(color: context.inkMuted, height: 1.35),
            ),
            const SizedBox(height: 12),
            FilledButton(
              key: const Key('risk-ack'),
              onPressed: busy ? null : onAcknowledge,
              child: const Text('I understand the warning — continue'),
            ),
          ],
          TextButton(
            onPressed: busy ? null : onCancel,
            child: const Text('Cancel pending'),
          ),
        ],
      ),
    );
  }
}
