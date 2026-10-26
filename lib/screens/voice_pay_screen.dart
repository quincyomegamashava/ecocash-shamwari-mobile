import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../core/api/api_exception.dart';
import '../core/models/models.dart';
import '../core/session/session.dart';
import '../core/theme/shamwari_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/pin_pad.dart';
import '../widgets/states.dart';

class VoicePayScreen extends ConsumerStatefulWidget {
  const VoicePayScreen({super.key});

  @override
  ConsumerState<VoicePayScreen> createState() => _VoicePayScreenState();
}

class _VoicePayScreenState extends ConsumerState<VoicePayScreen> {
  final _text = TextEditingController();
  AudioRecorder? _recorder;
  VoiceCatalog? _catalog;
  VoiceInterpretation? _heard;
  Txn? _pending;
  bool _loading = true;
  bool _busy = false;
  bool _recording = false;
  Object? _error;
  String? _micNote;
  String _language = 'sn';
  String _yes = 'hongu';
  String _pin = '';
  String? _formError;
  ConfirmResult? _posted;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  @override
  void dispose() {
    _text.dispose();
    _recorder?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final pace = ref.read(loadPaceProvider);
      final catalog = await ref.read(shamwariApiProvider).voicePhrases();
      await Future<void>.delayed(pace);
      if (!mounted) return;
      setState(() {
        _catalog = catalog;
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

  Future<void> _interpret(String text) async {
    setState(() {
      _busy = true;
      _formError = null;
      _heard = null;
    });
    try {
      final heard = await ref.read(shamwariApiProvider).interpretText(text);
      if (!mounted) return;
      setState(() => _heard = heard);
    } catch (error) {
      if (mounted) setState(() => _formError = friendlyError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _mic() async {
    try {
      _recorder ??= AudioRecorder();
      if (_recording) {
        final path = await _recorder!.stop();
        setState(() => _recording = false);
        if (path == null) return;
        final bytes = await File(path).readAsBytes();
        try {
          await ref
              .read(shamwariApiProvider)
              .interpretAudio(bytes, 'speech.m4a', language: _language);
        } catch (error) {
          if (mounted) setState(() => _micNote = friendlyError(error));
        }
        return;
      }
      final allowed = await _recorder!.hasPermission();
      if (!allowed) {
        setState(
          () => _micNote = 'Microphone permission was denied. Type the phrase — the book still understands it.',
        );
        return;
      }
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/shamwari-${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder!.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path,
      );
      setState(() {
        _recording = true;
        _micNote = null;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _recording = false;
          _micNote =
              'The microphone is not available. Type the phrase instead.';
        });
      }
    }
  }

  Future<void> _prepare() async {
    final plan = _heard?.plan;
    if (plan == null) return;
    setState(() => _busy = true);
    try {
      final result = await ref
          .read(shamwariApiProvider)
          .prepareVoice(plan.toJson());
      if (!mounted) return;
      setState(() => _pending = result.transaction);
    } catch (error) {
      if (mounted) setState(() => _formError = friendlyError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirm() async {
    final pending = _pending;
    if (pending == null) return;
    setState(() => _busy = true);
    try {
      final result = await ref
          .read(shamwariApiProvider)
          .confirmVoice(txnId: pending.id, confirmWord: _yes, pin: _pin);
      if (!mounted) return;
      setState(() {
        _posted = result;
        _pin = '';
        _pending = null;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _formError = friendlyError(error);
          _pin = '';
        });
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
    if (_error != null || _catalog == null) {
      return ErrorPane(error: _error ?? 'Voice did not load.', onRetry: _load);
    }
    final phrases = _catalog!.phrases
        .where((phrase) => phrase.language == _language)
        .toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
      children: [
        const SectionLabel('Voice pay'),
        Text(
          'Say it. Then confirm it.',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        Text(
          _catalog!.pinRule,
          style: TextStyle(color: context.inkMuted, height: 1.35),
        ),
        const SizedBox(height: 14),
        Center(
          child: GestureDetector(
            onTap: _mic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _recording ? palette.danger : palette.orange,
                boxShadow: shamwariAllowBlur
                    ? [
                        BoxShadow(
                          color: palette.orange.withValues(alpha: 0.35),
                          blurRadius: 24,
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                _recording ? Icons.stop_rounded : Icons.mic_rounded,
                color: palette.onAccent,
                size: 42,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text(
            _recording
                ? 'Listening… tap to send the file'
                : 'Tap the mic, or type below',
            style: TextStyle(color: context.inkMuted, fontSize: 12),
          ),
        ),
        if (_micNote != null) ...[
          const SizedBox(height: 8),
          Text(
            _micNote!,
            style: TextStyle(
              color: palette.warning,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _language,
          decoration: const InputDecoration(labelText: 'Listen in'),
          items: const [
            DropdownMenuItem(value: 'sn', child: Text('Shona')),
            DropdownMenuItem(value: 'nd', child: Text('Ndebele')),
            DropdownMenuItem(value: 'en', child: Text('English')),
          ],
          onChanged: (value) => setState(() => _language = value ?? 'sn'),
        ),
        const SizedBox(height: 10),
        TextField(
          key: const Key('voice-text'),
          controller: _text,
          minLines: 2,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Command',
            hintText: 'tumira madhora makumi maviri kuna Mai Tendai',
          ),
        ),
        const SizedBox(height: 10),
        FilledButton(
          key: const Key('read-command'),
          onPressed: _busy ? null : () => _interpret(_text.text),
          child: Text(_busy ? 'Reading…' : 'Read the command'),
        ),
        const SizedBox(height: 14),
        const SectionLabel('Fixed demo phrases'),
        const SizedBox(height: 8),
        for (final phrase in phrases)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GlassCard(
              onTap: () {
                _text.text = phrase.text;
                _interpret(phrase.text);
              },
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    phrase.label,
                    style: TextStyle(
                      color: palette.teal,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    phrase.text,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    phrase.hint,
                    style: TextStyle(color: context.inkMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        if (_formError != null)
          Text(
            _formError!,
            style: TextStyle(
              color: palette.danger,
              fontWeight: FontWeight.w600,
            ),
          ),
        if (_heard != null) _result(context, _heard!),
        if (_pending != null) _confirmCard(context),
        if (_posted != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: GlassCard(
              child: Text(
                'Posted ${_posted!.transaction.display}. The PIN was not sent to the model.',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
      ],
    );
  }

  Widget _result(BuildContext context, VoiceInterpretation heard) {
    final palette = context.palette;
    final plan = heard.plan;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionLabel('Heard'),
            const SizedBox(height: 6),
            Text(
              plan.sentence,
              style: const TextStyle(fontWeight: FontWeight.w700, height: 1.35),
            ),
            const SizedBox(height: 6),
            Text(
              '${plan.intent} · ${plan.language} · confidence ${plan.confidence.toStringAsFixed(2)}',
              style: TextStyle(color: context.inkMuted, fontSize: 12),
            ),
            if (plan.intent == 'check_balance')
              for (final wallet in heard.balances)
                Text(
                  wallet.displayAvailable,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
            if (plan.missing.isNotEmpty)
              Text(
                'Still missing: ${plan.missing.join(', ')}',
                style: TextStyle(color: palette.warning),
              ),
            if (plan.readyToPrepare) ...[
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _busy ? null : _prepare,
                child: const Text('Prepare pending'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _confirmCard(BuildContext context) {
    final pending = _pending!;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pending ${pending.display} · ${pending.counterparty}',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final word in const ['hongu', 'yes', 'yebo', 'ewe', 'ehe'])
                  ChoiceChip(
                    label: Text(word),
                    selected: _yes == word,
                    onSelected: (_) => setState(() => _yes = word),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            PinPad(
              pin: _pin,
              onChanged: (value) => setState(() => _pin = value),
            ),
            FilledButton(
              onPressed: _busy || _pin.length != 4 ? null : _confirm,
              child: const Text('Confirm voice payment'),
            ),
          ],
        ),
      ),
    );
  }
}
