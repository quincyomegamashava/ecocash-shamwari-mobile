import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class TokenStore {
  Future<String?> read();
  Future<void> write(String token);
  Future<void> clear();
}

class SecureTokenStore implements TokenStore {
  SecureTokenStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const _key = 'shamwari_bearer';

  static const _budget = Duration(seconds: 2);

  @override
  Future<String?> read() => _storage.read(key: _key).timeout(_budget);

  @override
  Future<void> write(String token) =>
      _storage.write(key: _key, value: token).timeout(_budget);

  @override
  Future<void> clear() => _storage.delete(key: _key).timeout(_budget);
}

class MemoryTokenStore implements TokenStore {
  String? value;

  @override
  Future<void> clear() async => value = null;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String token) async => value = token;
}

abstract class PrefsStore {
  String? getString(String key);
  bool? getBool(String key);
  Future<void> setString(String key, String value);
  Future<void> setBool(String key, bool value);
}

class SharedPrefsStore implements PrefsStore {
  SharedPrefsStore(this._prefs);
  final SharedPreferences _prefs;

  @override
  bool? getBool(String key) => _prefs.getBool(key);

  @override
  String? getString(String key) => _prefs.getString(key);

  @override
  Future<void> setBool(String key, bool value) => _prefs.setBool(key, value);

  @override
  Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);
}

class MemoryPrefs implements PrefsStore {
  final _strings = <String, String>{};
  final _bools = <String, bool>{};

  @override
  bool? getBool(String key) => _bools[key];

  @override
  String? getString(String key) => _strings[key];

  @override
  Future<void> setBool(String key, bool value) async => _bools[key] = value;

  @override
  Future<void> setString(String key, String value) async =>
      _strings[key] = value;
}

const defaultBaseUrl =
    'https://shamwari.3xm7hvreng89r.eu-west-2.cs.amazonlightsail.com';

String normalizeBaseUrl(String raw) {
  var value = raw.trim();
  if (value.isEmpty) return defaultBaseUrl;
  if (!value.startsWith('http://') && !value.startsWith('https://')) {
    value = 'http://$value';
  }
  while (value.endsWith('/')) {
    value = value.substring(0, value.length - 1);
  }
  return value;
}
