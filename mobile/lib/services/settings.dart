import 'dart:convert';

import '../core/calls.dart';
import 'storage.dart';

/// Time between calls when the caller runs on its own.
abstract final class Speed {
  static const min = 2000;
  static const max = 20000;
  static const step = 500;
  static const normal = 5500;

  /// "I'll tap to draw each number."
  static const manual = 0;

  static int clean(Object? value, {bool allowManual = true}) {
    final ms = value is num ? value.round() : normal;
    if (ms == manual && allowManual) return manual;
    return ms.clamp(min, max);
  }
}

/// How the caller speaks. Shared by the game and the number caller.
class VoiceSettings {
  bool on = true;

  /// The chosen text-to-speech voice, or null for automatic (Indian, then British English).
  String? voiceName;
  String? voiceLocale;

  /// 1 is normal speed, from 0.6 to 1.5.
  double rate = 1;

  /// 1 is normal pitch, from 0.5 to 1.5.
  double pitch = 1;
  CallStyle style = CallStyle.number;

  /// Say each number twice.
  bool repeat = false;

  static const minRate = 0.6, maxRate = 1.5, minPitch = 0.5, maxPitch = 1.5;

  /// What the caller says for [n] in the chosen style.
  String speechFor(int n) {
    final speech = describeCall(n, style).speech;
    return repeat ? '$speech $speech' : speech;
  }

  Map<String, Object?> toJson() => {
    'on': on,
    'voiceName': voiceName,
    'voiceLocale': voiceLocale,
    'rate': rate,
    'pitch': pitch,
    'style': style.name,
    'repeat': repeat,
  };

  void _read(Map m) {
    on = m['on'] as bool? ?? on;
    voiceName = m['voiceName'] as String?;
    voiceLocale = m['voiceLocale'] as String?;
    rate = ((m['rate'] as num?)?.toDouble() ?? rate).clamp(minRate, maxRate);
    pitch = ((m['pitch'] as num?)?.toDouble() ?? pitch).clamp(minPitch, maxPitch);
    style = CallStyle.byName(m['style'] as String?);
    repeat = m['repeat'] as bool? ?? repeat;
  }
}

/// Player preferences, saved between launches.
class Settings {
  Settings([KeyValueStore? store]) : _store = store;
  final KeyValueStore? _store;

  // The game table.
  String name = '';
  int tickets = 1;
  int bots = 4;

  /// Milliseconds between calls in the game; [Speed.manual] means the player taps the bag.
  int speed = Speed.normal;
  bool auto = false;
  bool sound = true;

  // The number caller.
  int callerSpeed = 6000;

  final VoiceSettings voice = VoiceSettings();

  bool get manual => speed == Speed.manual;

  static Settings load(KeyValueStore store) {
    final s = Settings(store);
    try {
      final raw = store.getString(StoreKeys.settings);
      if (raw != null) {
        final m = jsonDecode(raw) as Map<String, dynamic>;
        s.name = m['name'] as String? ?? s.name;
        s.tickets = ((m['tickets'] as int?) ?? s.tickets).clamp(1, 3);
        s.bots = ((m['bots'] as int?) ?? s.bots).clamp(0, 6);
        s.speed = Speed.clean(m['speed'] ?? s.speed);
        s.auto = m['auto'] as bool? ?? s.auto;
        s.callerSpeed = Speed.clean(m['callerSpeed'] ?? s.callerSpeed, allowManual: false);
        final voice = m['voice'];
        if (voice is Map) {
          s.voice._read(voice);
        } else if (voice is bool) {
          s.voice.on = voice; // before voice settings, this was just on/off
        }
      }
      s.sound = store.getBool(StoreKeys.sound) ?? true;
    } catch (_) {
      // Corrupt settings: play with the defaults.
    }
    return s;
  }

  void save() {
    final store = _store;
    if (store == null) return;
    store.setString(
      StoreKeys.settings,
      jsonEncode({
        'name': name,
        'tickets': tickets,
        'bots': bots,
        'speed': speed,
        'auto': auto,
        'callerSpeed': callerSpeed,
        'voice': voice.toJson(),
      }),
    );
    store.setBool(StoreKeys.sound, sound);
  }
}
