import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/calls.dart';
import '../core/number_draw.dart';
import '../core/prizes.dart';
import '../core/tickets.dart';
import '../services/fx.dart';
import '../services/settings.dart';
import '../services/storage.dart';
import 'table_events.dart';

/// The number caller: draws and calls numbers for a game on paper tickets,
/// with no tickets of its own. Saved as it goes.
class CallerController extends ChangeNotifier with TableEvents implements CallerMatModel {
  CallerController({required this.settings, Fx? fx, this.saveSlot, NumberDraw? draw}) : fx = fx ?? Fx() {
    _draw = draw ?? NumberDraw.fromJson(saveSlot?.load()) ?? NumberDraw.shuffled();
    _restoreMat(
      _draw.count == 0
          ? 'Press Start when everyone is ready'
          : 'Welcome back: ${_draw.count} numbers called. Press Carry on',
    );
  }

  final Settings settings;
  final Fx fx;

  /// Where the state is saved; null to not save (tests).
  final JsonRecord? saveSlot;

  late NumberDraw _draw;
  bool running = false;
  Timer? _timer;

  @override
  int? currentCoin;
  @override
  final List<int> tray = [];
  @override
  String callText = '';

  /// The ticket the host last checked. It updates as numbers are called.
  Ticket? checked;

  List<int> get called => _draw.called;
  bool isCalled(int n) => _draw.has(n);
  bool get isFinished => _draw.isFinished;
  bool get canUndo => _draw.count > 0;

  @override
  String get callCount => '${_draw.count} / 90 called';
  @override
  int get drawCount => _draw.count;
  @override
  bool get invitesTap => !running && !_draw.isFinished;

  /// Prizes the checked ticket has completed with the numbers called so far.
  List<Prize> get checkedPrizes => checked == null ? const [] : prizesMet(checked!, isCalled);
  int get checkedHits => checked?.numbers.where(isCalled).length ?? 0;

  void _save() => saveSlot?.save(_draw.toJson());

  void _restoreMat(String message) {
    final c = _draw.called;
    currentCoin = _draw.last;
    tray
      ..clear()
      ..addAll(c.length > 1 ? c.sublist(c.length - 7 < 0 ? 0 : c.length - 7, c.length - 1).reversed : const <int>[]);
    callText = message;
  }

  /// Draws and calls the next number.
  void callNext() {
    final n = _draw.next();
    if (n == null) {
      stop();
      callText = 'All 90 numbers have been called';
      notifyListeners();
      return;
    }
    _save();
    emit(BagShakeEvent());
    fx.play(Sfx.rummage);
    fx.play(Sfx.clack);
    final prev = currentCoin;
    if (prev != null) {
      tray.insert(0, prev);
      if (tray.length > 6) tray.removeLast();
    }
    currentCoin = n;
    callText = describeCall(n, settings.voice.style).display;
    fx.say(settings.voice.speechFor(n));
    if (_draw.isFinished) stop();
    notifyListeners();
  }

  void _schedule() {
    _timer?.cancel();
    if (running) {
      _timer = Timer(Duration(milliseconds: settings.callerSpeed), () {
        callNext();
        _schedule();
      });
    }
  }

  void start() {
    if (_draw.isFinished) return;
    running = true;
    fx.keepAwake(true);
    callNext();
    _schedule();
    notifyListeners();
  }

  void stop() {
    running = false;
    _timer?.cancel();
    fx.keepAwake(false);
    notifyListeners();
  }

  void toggle() => running ? stop() : start();

  /// Draws one number now (and restarts the countdown if calling on its own).
  @override
  void tapBag() {
    callNext();
    _schedule();
  }

  void undo() {
    final n = _draw.undo();
    if (n == null) return;
    _save();
    fx.hush();
    _restoreMat('$n put back in the bag');
    _schedule(); // so the next call isn't rushed
    notifyListeners();
  }

  void newGame() {
    stop();
    _draw = NumberDraw.shuffled();
    _save();
    checked = null;
    _restoreMat('New game. Press Start when everyone is ready');
    notifyListeners();
  }

  void setSpeed(int ms) {
    settings.callerSpeed = ms;
    settings.save();
    _schedule();
    notifyListeners();
  }

  void check(Ticket? ticket) {
    checked = ticket;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    fx.keepAwake(false);
    closeEvents();
    super.dispose();
  }
}
