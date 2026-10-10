import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

enum Sfx { rummage, clack, dab, win, lose, bogey }

enum Buzz { dab, yours, win }

/// Side effects the game asks for: sounds, the caller's voice, vibration and
/// keeping the screen on. Tests use the silent base class.
class Fx {
  void play(Sfx sfx) {}
  void say(String text) {}
  void hush() {}
  void buzz(Buzz kind) {}
  void keepAwake(bool on) {}
}

class DeviceFx extends Fx {
  DeviceFx({required this.soundOn, required this.voiceOn});

  /// Read on every call so toggles apply straight away.
  final bool Function() soundOn;
  final bool Function() voiceOn;

  final _tts = FlutterTts();
  final _players = <AudioPlayer>[];
  var _next = 0;

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
    await _initVoice().timeout(const Duration(seconds: 4), onTimeout: () {});
  }

  Future<void> _initVoice() async {
    try {
      // The traditional caller voice: Indian English, then British, then any English.
      for (final lang in ['en-IN', 'en-GB', 'en-US']) {
        if (await _tts.isLanguageAvailable(lang) == true) {
          await _tts.setLanguage(lang);
          break;
        }
      }
      await _tts.setSpeechRate(0.47);
      await _tts.setPitch(1);
      await _tts.awaitSpeakCompletion(false);
    } catch (_) {
      // No speech engine: the calls are still shown on screen.
    }
  }

  @override
  void play(Sfx sfx) {
    if (!soundOn() || _players.isEmpty) return;
    final p = _players[_next++ % _players.length];
    unawaited(p.play(AssetSource('sounds/${sfx.name}.wav')).catchError((_) {}));
  }

  @override
  void say(String text) {
    if (!soundOn() || !voiceOn()) return;
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
