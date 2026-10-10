import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Table settings chosen on the setup card; saved between launches.
class Settings {
  String name = '';
  int tickets = 1;
  int bots = 4;

  /// Milliseconds between calls; 0 means the player taps the bag.
  int speed = 5500;
  bool voice = true;
  bool auto = false;
  bool sound = true;

  bool get manual => speed == 0;

  static const _key = 'housey.settings';
  static const _soundKey = 'housey.sound';

  static Future<Settings> load() async {
    final s = Settings();
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null) {
        final m = jsonDecode(raw) as Map<String, dynamic>;
        s.name = m['name'] as String? ?? s.name;
        s.tickets = m['tickets'] as int? ?? s.tickets;
        s.bots = m['bots'] as int? ?? s.bots;
        s.speed = m['speed'] as int? ?? s.speed;
        s.voice = m['voice'] as bool? ?? s.voice;
        s.auto = m['auto'] as bool? ?? s.auto;
      }
      s.sound = prefs.getBool(_soundKey) ?? true;
    } catch (_) {
      // Storage unavailable or corrupt: play with the defaults.
    }
    return s;
  }

  Future<void> save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key,
        jsonEncode({'name': name, 'tickets': tickets, 'bots': bots, 'speed': speed, 'voice': voice, 'auto': auto}),
      );
      await prefs.setBool(_soundKey, sound);
    } catch (_) {
      // Storage unavailable: settings last for this session only.
    }
  }
}
