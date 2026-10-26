/// Parses a dollar/dollar-cent field into integer cents.
///
/// Accepts `20`, `20.5`, and `20.50`. Rejects more than two decimal places
/// so a float accident cannot post the wrong amount.
int? parseCents(String input) {
  final cleaned = input
      .trim()
      .replaceAll(',', '')
      .replaceAll(r'$', '')
      .replaceAll(' ', '')
      .replaceAll(RegExp(r'[A-Za-z]'), '');
  if (cleaned.isEmpty) return null;
  final match = RegExp(r'^(\d+)(?:\.(\d{1,2}))?$').firstMatch(cleaned);
  if (match == null) return null;
  final whole = int.parse(match.group(1)!);
  final fracRaw = match.group(2);
  final frac = fracRaw == null ? 0 : int.parse(fracRaw.padRight(2, '0'));
  return whole * 100 + frac;
}

/// Display mark used when the server did not send a ready-made string.
/// Server strings such as `US$ 86.00` should be preferred.
String formatCents(int cents, String currency) {
  final negative = cents < 0;
  final abs = cents.abs();
  final whole = abs ~/ 100;
  final frac = (abs % 100).toString().padLeft(2, '0');
  final mark = currency.toUpperCase() == 'ZIG' ? 'ZiG' : 'US\$';
  return '${negative ? '-' : ''}$mark $whole.$frac';
}

String currencyMark(String currency) =>
    currency.toUpperCase() == 'ZIG' ? 'ZiG' : 'US\$';
