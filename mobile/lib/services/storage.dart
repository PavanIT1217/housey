// Saved data. Everything goes through [KeyValueStore], so tests use memory
// and a server-backed store can replace it later without touching screens.

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Every key Housey stores, in one place.
abstract final class StoreKeys {
  static const settings = 'housey.settings';
  static const sound = 'housey.sound';
  static const savedGame = 'housey.game';
  static const callerSession = 'housey.caller.session';
  static const myTickets = 'housey.mytickets';
  static const printOptions = 'housey.print';
}

abstract interface class KeyValueStore {
  String? getString(String key);
  bool? getBool(String key);
  void setString(String key, String value);
  void setBool(String key, bool value);
  void remove(String key);
}

/// Keeps values for this run only. Used by tests and when storage fails.
class MemoryStore implements KeyValueStore {
  final _values = <String, Object>{};

  @override
  String? getString(String key) => _values[key] as String?;
  @override
  bool? getBool(String key) => _values[key] as bool?;
  @override
  void setString(String key, String value) => _values[key] = value;
  @override
  void setBool(String key, bool value) => _values[key] = value;
  @override
  void remove(String key) => _values.remove(key);
}

/// The phone's shared preferences. Reads are instant; writes finish in the background.
class PrefsStore implements KeyValueStore {
  PrefsStore._(this._prefs);
  final SharedPreferences _prefs;

  /// Opens the phone's storage, or falls back to memory if it's unavailable.
  static Future<KeyValueStore> open() async {
    try {
      return PrefsStore._(await SharedPreferences.getInstance());
    } catch (_) {
      return MemoryStore();
    }
  }

  @override
  String? getString(String key) => _prefs.getString(key);
  @override
  bool? getBool(String key) => _prefs.getBool(key);
  @override
  void setString(String key, String value) => _prefs.setString(key, value).ignore();
  @override
  void setBool(String key, bool value) => _prefs.setBool(key, value).ignore();
  @override
  void remove(String key) => _prefs.remove(key).ignore();
}

/// A stored JSON record with a schema version, so old or damaged data is
/// ignored rather than crashing the app.
class JsonRecord {
  const JsonRecord(this.store, this.key, this.version);
  final KeyValueStore store;
  final String key;
  final int version;

  Object? load() {
    try {
      final raw = store.getString(key);
      if (raw == null) return null;
      final record = jsonDecode(raw);
      return record is Map && record['version'] == version ? record['data'] : null;
    } catch (_) {
      return null;
    }
  }

  void save(Object data) => store.setString(
    key,
    jsonEncode({'version': version, 'savedAt': DateTime.now().millisecondsSinceEpoch, 'data': data}),
  );

  void clear() => store.remove(key);
}
