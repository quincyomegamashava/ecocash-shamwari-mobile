import 'package:flutter/material.dart';

import '../core/api/api_exception.dart';
import '../core/theme/shamwari_theme.dart';

class SkeletonBox extends StatefulWidget {
  const SkeletonBox({
    super.key,
    this.height = 16,
    this.width,
    this.radius = 12,
  });

  final double height;
  final double? width;
  final double radius;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(-1 + _controller.value * 2, 0),
              end: Alignment(_controller.value * 2, 0),
              colors: [
                palette.card,
                palette.orange.withValues(alpha: 0.18),
                palette.card,
              ],
            ),
          ),
        );
      },
    );
  }
}

class SkeletonColumn extends StatelessWidget {
  const SkeletonColumn({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SkeletonBox(height: 18, width: 120),
        SizedBox(height: 12),
        SkeletonBox(height: 160, radius: 22),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: SkeletonBox(height: 88, radius: 18)),
            SizedBox(width: 10),
            Expanded(child: SkeletonBox(height: 88, radius: 18)),
          ],
        ),
      ],
    );
  }
}

class ErrorPane extends StatelessWidget {
  const ErrorPane({super.key, required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, color: palette.orange, size: 36),
            const SizedBox(height: 12),
            Text(
              friendlyError(error),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}

class EmptyPane extends StatelessWidget {
  const EmptyPane({
    super.key,
    required this.title,
    required this.body,
    this.icon = Icons.inbox_rounded,
  });

  final String title;
  final String body;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 12),
      child: Column(
        children: [
          Icon(icon, color: palette.teal, size: 32),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(fontWeight: FontWeight.w800, color: context.ink),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.inkMuted),
          ),
        ],
      ),
    );
  }
}
