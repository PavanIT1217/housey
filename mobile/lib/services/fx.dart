import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'settings.dart';

enum Sfx { rummage, clack, dab, win, lose, bogey }

enum Buzz { dab, yours, win }

/// A text-to-speech voice the player can choose.
class VoiceOption {
  const VoiceOption(this.name, this.locale);
  final String name;
  final String locale;

  String get label => '$name ($locale)';
}

/// Side effects the app asks for: sounds, the caller's voice, vibration and
/// keeping the screen on. Tests use this silent base class.
class Fx {
  void play(Sfx sfx) {}
  void say(String text, {bool force = false}) {}
  void hush() {}
  void buzz(Buzz kind) {}
  void keepAwake(bool on) {}

  /// Applies the voice, speed and pitch from the settings.
  Future<void> applyVoice() async {}

  /// Voices the phone can speak with, English first.
  Future<List<VoiceOption>> voices() async => const [];
}

class DeviceFx extends Fx {
  DeviceFx(this.settings);

  /// Read on every call so changes apply straight away.
  final Settings settings;

  final _tts = FlutterTts();
  final _players = <AudioPlayer>[];
  var _next = 0;

  // flutter_tts treats 0.5 as normal speed on both platforms; this sounded best for calling.
  static const _baseRate = 0.47;
  static const _preferred = ['en-IN', 'en-GB', 'en-US'];

  Future<void> init() async {
    try {
      // Mix with the caller's voice instead of pausing it.
      await AudioPlayer.global.setAudioContext(
        AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers).build(),
      );
      for (var i = 0; i < 4; i++) {
        final p = AudioPlayer();
        await p.setReleaseMode(ReleaseMode.stop);
        await p.setPlayerMode(PlayerMode.lowLatency);
        _players.add(p);
      }
    } catch (_) {
      // No audio output: play silently.
    }
    await applyVoice().timeout(const Duration(seconds: 4), onTimeout: () {});
  }

  @override
  Future<void> applyVoice() async {
    final v = settings.voice;
    try {
      final name = v.voiceName, locale = v.voiceLocale;
      if (name != null && locale != null) {
        await _tts.setVoice({'name': name, 'locale': locale});
      } else {
        // The traditional caller voice: Indian English, then British, then any English.
        for (final lang in _preferred) {
          if (await _tts.isLanguageAvailable(lang) == true) {
            await _tts.setLanguage(lang);
            break;
          }
        }
      }
      await _tts.setSpeechRate((_baseRate * v.rate).clamp(0.1, 1.0));
      await _tts.setPitch(v.pitch);
      await _tts.awaitSpeakCompletion(false);
    } catch (_) {
      // No speech engine: the calls are still shown on screen.
    }
  }

  @override
  Future<List<VoiceOption>> voices() async {
    try {
      final raw = await _tts.getVoices;
      if (raw is! List) return const [];
      final voices = [
        for (final v in raw)
          if (v is Map && v['name'] is String && v['locale'] is String)
            VoiceOption(v['name'] as String, v['locale'] as String),
      ].where((v) => v.locale.toLowerCase().startsWith('en')).toList();
      int rank(VoiceOption v) {
        final i = _preferred.indexWhere((p) => v.locale.replaceAll('_', '-').toLowerCase() == p.toLowerCase());
        return i < 0 ? 9 : i;
      }

      voices.sort((a, b) {
        final r = rank(a) - rank(b);
        return r != 0 ? r : a.label.compareTo(b.label);
      });
      return voices;
    } catch (_) {
      return const [];
    }
  }

  @override
  void play(Sfx sfx) {
    if (!settings.sound || _players.isEmpty) return;
    final p = _players[_next++ % _players.length];
    unawaited(p.play(AssetSource('sounds/${sfx.name}.wav')).catchError((_) {}));
  }

  @override
  void say(String text, {bool force = false}) {
    if (!settings.sound || (!settings.voice.on && !force)) return;
    unawaited(() async {
      try {
        await _tts.stop();
        await _tts.speak(text);
      } catch (_) {}
    }());
  }

  @override
  void hush() => unawaited(_tts.stop().catchError((_) => null));

  @override
  void buzz(Buzz kind) {
    switch (kind) {
      case Buzz.dab:
        HapticFeedback.lightImpact();
      case Buzz.yours:
        HapticFeedback.selectionClick();
      case Buzz.win:
        HapticFeedback.heavyImpact();
    }
  }

  @override
  void keepAwake(bool on) => unawaited((on ? WakelockPlus.enable() : WakelockPlus.disable()).catchError((_) {}));
}
