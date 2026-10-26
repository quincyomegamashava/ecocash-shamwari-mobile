import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/api_exception.dart';
import '../core/models/models.dart';
import '../core/session/session.dart';
import '../core/theme/shamwari_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/states.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _question = TextEditingController();
  SopBundle? _docs;
  final List<_Turn> _turns = [];
  QuizPaper? _paper;
  final Map<int, String> _answers = {};
  QuizScore? _score;
  bool _loading = true;
  bool _busy = false;
  Object? _error;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  @override
  void dispose() {
    _question.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final pace = ref.read(loadPaceProvider);
      final docs = await ref.read(shamwariApiProvider).onboardingDocs();
      await Future<void>.delayed(pace);
      if (!mounted) return;
      setState(() {
        _docs = docs;
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

  Future<void> _ask(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    setState(() => _busy = true);
    try {
      final answer = await ref.read(shamwariApiProvider).onboardingAsk(trimmed);
      if (!mounted) return;
      _question.clear();
      setState(() => _turns.add(_Turn(answer)));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(friendlyError(error))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _quiz() async {
    setState(() => _busy = true);
    try {
      final paper = await ref.read(shamwariApiProvider).onboardingQuiz();
      if (!mounted) return;
      setState(() {
        _paper = paper;
        _answers.clear();
        _score = null;
        _tab = 1;
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(friendlyError(error))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _scoreQuiz() async {
    setState(() => _busy = true);
    try {
      final answers = {
        for (final entry in _answers.entries) '${entry.key}': entry.value,
      };
      final score = await ref
          .read(shamwariApiProvider)
          .onboardingScore(answers);
      if (!mounted) return;
      setState(() => _score = score);
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
    if (_error != null || _docs == null) {
      return ErrorPane(
        error: _error ?? 'The buddy did not load.',
        onRetry: _load,
      );
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionLabel('Team'),
              Text(
                'Onboarding buddy.',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              if (_docs!.fiction)
                Text(
                  'Fictional SOPs. This is hackathon material, not EcoCash policy.',
                  style: TextStyle(
                    color: palette.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              const SizedBox(height: 8),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 0, label: Text('Ask')),
                  ButtonSegment(value: 1, label: Text('Quiz')),
                  ButtonSegment(value: 2, label: Text('SOPs')),
                ],
                selected: {_tab},
                onSelectionChanged: (value) =>
                    setState(() => _tab = value.first),
              ),
            ],
          ),
        ),
        Expanded(
          child: _tab == 0
              ? _askPane()
              : _tab == 1
              ? _quizPane()
              : _docsPane(),
        ),
      ],
    );
  }

  Widget _askPane() {
    final palette = context.palette;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final prompt in const [
                    'What do I do if a customer is asked for their PIN?',
                    'Does scanning a QR send the money?',
                    'When does a Shona voice payment post?',
                  ])
                    ActionChip(
                      label: Text(prompt),
                      onPressed: _busy ? null : () => _ask(prompt),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (_turns.isEmpty)
                const EmptyPane(
                  title: 'Ask the buddy',
                  body: 'Answers cite the fictional SOP headings.',
                ),
              for (final turn in _turns) ...[
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: palette.orange,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      turn.answer.question,
                      style: TextStyle(color: palette.onAccent),
                    ),
                  ),
                ),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        turn.answer.answer,
                        style: const TextStyle(height: 1.35),
                      ),
                      if (turn.answer.hits.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          children: [
                            for (final hit in turn.answer.hits)
                              Chip(label: Text(hit.docTitle)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _question,
                    decoration: const InputDecoration(
                      hintText: 'Ask about the fictional SOPs',
                    ),
                    onSubmitted: _busy ? null : _ask,
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _busy ? null : () => _ask(_question.text),
                  child: const Text('Ask'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _quizPane() {
    final palette = context.palette;
    final paper = _paper;
    if (paper == null) {
      return Center(
        child: FilledButton(
          onPressed: _busy ? null : _quiz,
          child: const Text('Start the quiz'),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        for (var i = 0; i < paper.questions.length; i++) ...[
          Text(
            paper.questions[i].question,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          Text(
            paper.questions[i].docTitle,
            style: TextStyle(color: context.inkMuted, fontSize: 12),
          ),
          const SizedBox(height: 6),
          RadioGroup<String>(
            groupValue: _answers[i],
            onChanged: (value) => setState(() => _answers[i] = value ?? ''),
            child: Column(
              children: [
                for (final choice in paper.questions[i].choices)
                  RadioListTile<String>(
                    value: choice.key,
                    title: Text('${choice.key}. ${choice.text}'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
        FilledButton(
          onPressed: _busy || _answers.length < paper.questions.length
              ? null
              : _scoreQuiz,
          child: const Text('Score'),
        ),
        if (_score != null) ...[
          const SizedBox(height: 12),
          Text(
            '${_score!.correct} of ${_score!.total}',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          for (final row in _score!.review)
            ListTile(
              leading: Icon(
                row.ok ? Icons.check_circle : Icons.cancel,
                color: row.ok ? palette.ok : palette.danger,
              ),
              title: Text('You picked ${row.picked}. Answer ${row.answer}.'),
              subtitle: Text(row.docTitle),
            ),
        ],
      ],
    );
  }

  Widget _docsPane() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        for (final doc in _docs!.documents)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doc.title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    doc.body,
                    style: TextStyle(
                      color: context.inkMuted,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _Turn {
  _Turn(this.answer);
  final BuddyAnswer answer;
}
