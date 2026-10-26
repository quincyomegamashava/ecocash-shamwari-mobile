import 'dart:io';

import 'package:flutter/widgets.dart';

/// Set only for the Linux screenshot walk. Widget tests leave this unset.
bool get captureTourActive => Platform.environment['SHAMWARI_CAPTURE'] == '1';

class CaptureCue {
  static final phase = ValueNotifier<String?>(null);
}

/// Scrolls a widget that matches [test] into the phone viewport.
Future<void> captureReveal(
  BuildContext context,
  bool Function(Element element) test,
) async {
  final root = context as Element;
  Element? target;
  void walk(Element element) {
    if (target == null && test(element)) target = element;
    element.visitChildren(walk);
  }

  root.visitChildElements(walk);
  final found = target;
  if (found == null) return;
  await Scrollable.ensureVisible(
    found,
    alignment: 0.15,
    duration: const Duration(milliseconds: 250),
  );
}
