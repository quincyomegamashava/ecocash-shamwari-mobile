import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/session/session.dart';
import 'core/session/stores.dart';
import 'dev/capture_cue.dart';
import 'dev/capture_tour.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [
        prefsStoreProvider.overrideWithValue(SharedPrefsStore(preferences)),
        // libsecret blocks the UI thread when this desktop has no keyring.
        // The capture walk keeps the bearer in memory instead.
        if (captureTourActive)
          tokenStoreProvider.overrideWithValue(MemoryTokenStore()),
      ],
      child: captureTourActive ? const CaptureBootstrap() : const ShamwariApp(),
    ),
  );
}
