import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../core/api/api_exception.dart';
import '../core/models/models.dart';
import '../core/money.dart';
import '../core/session/session.dart';
import '../core/theme/shamwari_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/states.dart';

class ReceiptsScreen extends ConsumerStatefulWidget {
  const ReceiptsScreen({super.key});

  @override
  ConsumerState<ReceiptsScreen> createState() => _ReceiptsScreenState();
}

class _ReceiptsScreenState extends ConsumerState<ReceiptsScreen> {
  ReceiptBook? _book;
  List<ReceiptSample> _samples = const [];
  bool _loading = true;
  Object? _error;
  ReceiptExtraction? _draft;
  final _vendor = TextEditingController();
  final _date = TextEditingController();
  final _total = TextEditingController();
  String _currency = 'USD';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  @override
  void dispose() {
    _vendor.dispose();
    _date.dispose();
    _total.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ref.read(shamwariApiProvider);
      final pace = ref.read(loadPaceProvider);
      final results = await Future.wait([
        api.receipts(),
        api.receiptSamples(),
        Future<void>.delayed(pace),
      ]);
      if (!mounted) return;
      setState(() {
        _book = results[0] as ReceiptBook;
        _samples = results[1] as List<ReceiptSample>;
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

  void _apply(ReceiptExtraction extraction) {
    _vendor.text = extraction.vendor;
    _date.text = extraction.date;
    _total.text = extraction.totalCents == 0
        ? ''
        : (extraction.totalCents / 100).toStringAsFixed(2);
    _currency = extraction.currency.isEmpty ? 'USD' : extraction.currency;
    setState(() => _draft = extraction);
  }

  Future<void> _readSample(String filename) async {
    setState(() => _busy = true);
    try {
      final extraction = await ref
          .read(shamwariApiProvider)
          .readReceiptSample(filename);
      _apply(extraction);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(friendlyError(error))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pick(ImageSource source) async {
    try {
      final file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (file == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No photo was chosen. You can still use a sample slip.',
              ),
            ),
          );
        }
        return;
      }
      final bytes = await file.readAsBytes();
      final extraction = await ref
          .read(shamwariApiProvider)
          .readReceiptImage(bytes, file.name);
      _apply(extraction);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'The camera or gallery is not available. Use a sample slip.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _save() async {
    final cents = parseCents(_total.text);
    if (_vendor.text.trim().isEmpty || cents == null || cents <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A slip needs a vendor and a positive total.'),
        ),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(shamwariApiProvider)
          .saveReceipt(
            vendor: _vendor.text.trim(),
            receiptDate: _date.text.trim(),
            currency: _currency,
            totalCents: cents,
            notes: _draft?.note ?? '',
            items: _draft?.items ?? const [],
          );
      if (!mounted) return;
      setState(() => _draft = null);
      await _load();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(friendlyError(error))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _export() async {
    try {
      final file = await ref.read(shamwariApiProvider).exportReceipts();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(file.filename),
          content: SingleChildScrollView(
            child: SelectableText(
              file.csv.isEmpty ? 'The tuckshop book is empty.' : file.csv,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: file.csv));
                Navigator.pop(context);
              },
              child: const Text('Copy'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(friendlyError(error))));
      }
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
    if (_error != null || _book == null) {
      return ErrorPane(
        error: _error ?? 'Receipts did not load.',
        onRetry: _load,
      );
    }
    final book = _book!;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
        children: [
          const SectionLabel('Tuckshop'),
          Text(
            book.merchant.name,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          Text(
            'Read a slip, check the lines, then save. A pay QR does not send money.',
            style: TextStyle(color: context.inkMuted),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pick(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Camera'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pick(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Gallery'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: _export,
              child: const Text('Export CSV'),
            ),
          ),
          const SectionLabel('Sample slips'),
          const SizedBox(height: 8),
          for (final sample in _samples)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GlassCard(
                onTap: _busy ? null : () => _readSample(sample.filename),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sample.title.isEmpty ? sample.vendor : sample.title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      sample.filename,
                      style: TextStyle(color: palette.teal, fontSize: 12),
                    ),
                    if (sample.note.isNotEmpty)
                      Text(
                        sample.note,
                        style: TextStyle(color: context.inkMuted, fontSize: 12),
                      ),
                    if (sample.payload.isNotEmpty)
                      Text(
                        sample.payload,
                        style: TextStyle(color: context.inkMuted, fontSize: 12),
                      ),
                  ],
                ),
              ),
            ),
          if (_draft != null) _editor(),
          const SizedBox(height: 8),
          Text('Saved', style: Theme.of(context).textTheme.titleMedium),
          if (book.entries.isEmpty)
            const EmptyPane(
              title: 'No slips saved',
              body: 'Read the Mbare sample and save it onto the tuckshop.',
            )
          else
            for (final entry in book.entries) _Slip(entry: entry),
        ],
      ),
    );
  }

  Widget _editor() {
    final draft = _draft!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionLabel('Review'),
            Text(
              draft.note,
              style: TextStyle(color: context.inkMuted, fontSize: 12),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _vendor,
              decoration: const InputDecoration(labelText: 'Vendor'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _date,
              decoration: const InputDecoration(labelText: 'Date'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _total,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Total',
                prefixText: '${currencyMark(_currency)} ',
              ),
            ),
            if (draft.items.isNotEmpty) ...[
              const SizedBox(height: 8),
              for (final item in draft.items)
                Text(
                  '${item.description}  ${formatCents(item.amountCents, _currency)}',
                ),
            ],
            const SizedBox(height: 10),
            FilledButton(
              onPressed: _busy ? null : _save,
              child: const Text('Save onto the tuckshop'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Slip extends StatelessWidget {
  const _Slip({required this.entry});
  final ReceiptEntry entry;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry.vendor,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            Text(
              '${entry.display} · ${entry.receiptDate}',
              style: TextStyle(color: palette.teal),
            ),
            for (final item in entry.items)
              Text(
                item.description,
                style: TextStyle(color: context.inkMuted, fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }
}

/// Decodes a sample PNG when a screen wants the bytes. Kept for the image route.
Uint8List decodeSlip(String base64Body) => base64Decode(base64Body);
