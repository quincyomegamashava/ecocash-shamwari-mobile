import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/api_exception.dart';
import '../core/models/models.dart';
import '../core/session/session.dart';
import '../dev/capture_cue.dart';
import '../core/theme/shamwari_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/states.dart';

class ScamScreen extends ConsumerStatefulWidget {
  const ScamScreen({super.key});

  @override
  ConsumerState<ScamScreen> createState() => _ScamScreenState();
}

class _ScamScreenState extends ConsumerState<ScamScreen> {
  final _text = TextEditingController();
  List<ScamSample> _samples = const [];
  ScamReport? _report;
  bool _loading = true;
  bool _busy = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final pace = ref.read(loadPaceProvider);
      final samples = await ref.read(shamwariApiProvider).scamSamples();
      await Future<void>.delayed(pace);
      if (!mounted) return;
      setState(() {
        _samples = samples;
        _loading = false;
      });
      if (captureTourActive && CaptureCue.phase.value == 'scam') {
        final sample = samples.where((item) => item.id == 'reversal').firstOrNull;
        if (sample != null) {
          _text.text = sample.text;
          await _check(sample: sample.id);
          if (!mounted) return;
          await WidgetsBinding.instance.endOfFrame;
          if (!mounted) return;
          await captureReveal(context, (element) {
            final widget = element.widget;
            return widget is Text && widget.data == 'Likely scam';
          });
        }
        CaptureCue.phase.value = 'scam-ready';
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  Future<void> _check({String? sample, String? text}) async {
    setState(() => _busy = true);
    try {
      final report = await ref
          .read(shamwariApiProvider)
          .scamCheck(sample: sample, text: text);
      if (!mounted) return;
      setState(() => _report = report);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(friendlyError(error))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: SkeletonColumn(),
      );
    }
    if (_error != null) return ErrorPane(error: _error!, onRetry: _load);
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
        children: [
          const SectionLabel('Protect'),
          Text(
            'Is this a lure?',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          Text(
            'Paste an SMS or describe the call. The cautious verdict wins. Nothing you paste is a payment.',
            style: TextStyle(color: context.inkMuted, height: 1.35),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('scam-text'),
            controller: _text,
            minLines: 4,
            maxLines: 6,
            decoration: const InputDecoration(
              hintText: 'Paste the SMS…',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 10),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: palette.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: _busy ? null : () => _check(text: _text.text),
            child: Text(_busy ? 'Checking…' : 'Check this message'),
          ),
          const SizedBox(height: 14),
          const SectionLabel('Samples'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final sample in _samples)
                ActionChip(
                  label: Text(sample.title),
                  onPressed: () {
                    _text.text = sample.text;
                    _check(sample: sample.id);
                  },
                ),
            ],
          ),
          if (_report != null) ...[
            const SizedBox(height: 14),
            _Verdict(report: _report!),
          ],
        ],
      ),
    );
  }
}

class _Verdict extends StatelessWidget {
  const _Verdict({required this.report});
  final ScamReport report;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final color = switch (report.verdict) {
      'likely_scam' => palette.danger,
      'suspicious' => palette.warning,
      _ => palette.ok,
    };
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            report.label,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            'Rules: ${report.rulesLabel} · source ${report.source}',
            style: TextStyle(color: context.inkMuted, fontSize: 12),
          ),
          if (report.patterns.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final pattern in report.patterns) Text('• $pattern'),
          ],
          const SizedBox(height: 8),
          for (final step in report.steps)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(step, style: const TextStyle(height: 1.3)),
            ),
        ],
      ),
    );
  }
}
