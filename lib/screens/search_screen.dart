import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/demo/demo_controller.dart';
import '../core/models/models.dart';
import '../core/router.dart';
import '../core/session/session.dart';
import '../core/theme/shamwari_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/states.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _query = TextEditingController();
  List<SearchHit> _hits = const [];
  bool _loading = true;
  Object? _error;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _search(''));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final hits = await ref.read(shamwariApiProvider).search(query);
      if (!mounted) return;
      setState(() {
        _hits = hits;
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

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 220), () => _search(value));
  }

  Future<void> _open(SearchHit hit) async {
    final route = routeForHit(hit.label, hit.apiPath);
    if (route == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This row lives on the web desk.')),
      );
      return;
    }
    if (route == '/demo') {
      await ref.read(demoProvider.notifier).walkMorning();
      return;
    }
    if (!mounted) return;
    context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionLabel('Search'),
              TextField(
                key: const Key('search-field'),
                controller: _query,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Modules, people, actions',
                ),
                onChanged: _onChanged,
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SkeletonColumn(),
                )
              : _error != null
              ? ErrorPane(error: _error!, onRetry: () => _search(_query.text))
              : _hits.isEmpty
              ? const EmptyPane(
                  title: 'Nothing matched',
                  body: 'Try send, pulse, coach, or scam. A customer search for pulse stays empty.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: _hits.length,
                  itemBuilder: (context, index) {
                    final hit = _hits[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GlassCard(
                        onTap: () => _open(hit),
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    hit.label,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    hit.hint,
                                    style: TextStyle(
                                      color: context.inkMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              hit.group,
                              style: TextStyle(
                                color: palette.teal,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
