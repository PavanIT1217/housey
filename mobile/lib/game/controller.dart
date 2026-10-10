import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'fx.dart';
import 'rules.dart';
import 'settings.dart';

class Player {
  Player({required this.id, required this.name, required this.color, required this.tickets, this.skill = 1})
    : human = id == 0;

  final int id;
  final String name;
  final int color;
  final bool human;
  final List<Ticket> tickets;

  /// Chance a computer player notices a finished prize on each call.
  final double skill;
  int points = 0;
  final List<String> wins = [];

  String get displayName => human && name != 'You' ? '$name (you)' : name;
}

/// How a dab of ink sits on a cell: each one is stamped a little differently.
class DabLook {
  DabLook(Random rng)
    : rotation = rng.nextDouble() * 2 * pi,
      dx = (rng.nextDouble() * 8 - 4) / 100,
      dy = (rng.nextDouble() * 8 - 4) / 100,
      scale = 0.92 + rng.nextDouble() * 0.14,
      seed = rng.nextInt(1 << 30);

  final double rotation, dx, dy, scale;
  final int seed;
}

sealed class TableEvent {}

class ToastEvent extends TableEvent {
  ToastEvent(this.message);
  final String message;
}

class AnnounceEvent extends TableEvent {
  AnnounceEvent(this.title, this.subtitle, {this.bogey = false});
  final String title, subtitle;
  final bool bogey;
}

class BagShakeEvent extends TableEvent {}

enum Stage { setup, playing, results }

/// Runs a game of Housey: the caller, the computer players and the claims.
class GameController extends ChangeNotifier {
  GameController({required this.settings, Fx? fx, Random? random}) : fx = fx ?? Fx(), rng = random ?? Random() {
    // Preview a ticket behind the setup card so the table never looks empty.
    players = [
      Player(id: 0, name: 'You', color: 0xFFB3261E, tickets: [makeTicket(rng)]),
    ];
  }

  final Settings settings;
  final Fx fx;
  final Random rng;

  final _events = StreamController<TableEvent>.broadcast();
  Stream<TableEvent> get events => _events.stream;

  Stage stage = Stage.setup;
  late List<Player> players;
  Player get me => players.first;

  List<int> _remaining = [];
  final List<int> called = [];
  final Set<int> calledSet = {};
  final Map<String, Player> claimed = {};
  bool paused = false;
  bool over = true;

  /// The caller waits a moment after each claim before drawing again.
  bool _holding = false;
  final Set<String> _pending = {};

  /// The coin on the mat, the last few before it, and what the caller said.
  int? currentCoin;
  final List<int> tray = [];
  String callText = 'Ready when you are';

  /// Looks of the dabs on each of my tickets, keyed by number.
  final Map<Ticket, Map<int, DabLook>> dabLooks = {};

  /// Cells dabbed before their number was called, as "ticketIndex:number".
  final Set<String> wrong = {};
  int? winnerTicket;
  int? claimingPlayer;

  final List<Timer> _timers = [];
  Timer? _drawTimer;

  /// Whether [n] has a chip on the caller's board: called, and its coin has landed.
  bool onBoard(int n) => calledSet.contains(n) && (n != called.last || currentCoin == n);

  String get callCount => '${called.length} / 90 called';

  void _later(Duration d, VoidCallback fn) {
    late Timer t;
    t = Timer(d, () {
      _timers.remove(t);
      fn();
    });
    _timers.add(t);
  }

  void _clearTimers() {
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
    _drawTimer?.cancel();
    _drawTimer = null;
  }

  void _emit(TableEvent e) {
    if (!_events.isClosed) _events.add(e);
  }

  void toast(String msg) => _emit(ToastEvent(msg));

  // ---------- Game flow ----------

  void start() {
    unawaited(settings.save());
    newGame();
  }

  void newGame() {
    _clearTimers();
    final names = (List.of(botNames)..shuffle(rng)).take(settings.bots).toList();
    final name = settings.name.trim();
    players = [
      Player(id: 0, name: name.isEmpty ? 'You' : name, color: 0xFFB3261E, tickets: _deal()),
      for (var i = 0; i < names.length; i++)
        Player(
          id: i + 1,
          name: names[i],
          color: botColors[i % botColors.length],
          tickets: _deal(),
          skill: 0.55 + rng.nextDouble() * 0.35,
        ),
    ];
    _remaining = List.generate(90, (i) => i + 1)..shuffle(rng);
    called.clear();
    calledSet.clear();
    claimed.clear();
    dabLooks.clear();
    wrong.clear();
    _pending.clear();
    tray.clear();
    currentCoin = null;
    winnerTicket = null;
    claimingPlayer = null;
    paused = false;
    over = false;
    _holding = false;
    stage = Stage.playing;
    if (settings.manual) {
      callText = 'Tap the bag to draw';
    } else {
      callText = 'Shuffling the coins…';
      _scheduleDraw(const Duration(milliseconds: 1800));
    }
    fx.keepAwake(true);
    notifyListeners();
  }

  List<Ticket> _deal() => List.generate(settings.tickets, (_) => makeTicket(rng));

  void openSetup() {
    _clearTimers();
    paused = true;
    fx.hush();
    stage = Stage.setup;
    notifyListeners();
  }

  void _scheduleDraw(Duration d) {
    _drawTimer?.cancel();
    if (over || paused || settings.manual) return;
    _drawTimer = Timer(d, drawNext);
  }

  Duration get _speed => Duration(milliseconds: settings.speed);

  void drawNext() {
    if (over || stage != Stage.playing) return;
    if (_holding) {
      if (!settings.manual) _scheduleDraw(const Duration(milliseconds: 300));
      return;
    }
    if (_remaining.isEmpty) {
      _endGame();
      return;
    }

    final n = _remaining.removeLast();
    called.add(n);
    calledSet.add(n);
    _emit(BagShakeEvent());
    fx.play(Sfx.rummage);

    _later(const Duration(milliseconds: 550), () {
      final prev = currentCoin;
      if (prev != null) {
        tray.insert(0, prev);
        if (tray.length > 6) tray.removeLast();
      }
      currentCoin = n;
      _later(const Duration(milliseconds: 350), () => fx.play(Sfx.clack));
      callText = calls[n];
      fx.say(spoken(n));

      // Cells dabbed early are fine now their number has come up.
      wrong.removeWhere((w) => w.endsWith(':$n'));

      if (settings.auto) {
        _autoDab(n);
      } else if (me.tickets.any((t) => t.contains(n))) {
        fx.buzz(Buzz.yours);
      }
      _botsConsider();
      notifyListeners();
    });

    _scheduleDraw(_speed);
  }

  void tapBag() {
    if (over || stage != Stage.playing) return;
    if (settings.manual) {
      drawNext();
    } else if (paused) {
      togglePause();
    }
  }

  void togglePause() {
    if (over || settings.manual || stage != Stage.playing) return;
    paused = !paused;
    if (paused) {
      _drawTimer?.cancel();
      callText = 'Paused — take a breather';
      fx.hush();
    } else {
      callText = 'Here we go…';
      _scheduleDraw(const Duration(milliseconds: 1200));
    }
    notifyListeners();
  }

  /// Pauses the caller when the app goes to the background.
  void pauseIfRunning() {
    if (!paused) togglePause();
  }

  void toggleSound() {
    settings.sound = !settings.sound;
    if (!settings.sound) fx.hush();
    unawaited(settings.save());
    notifyListeners();
  }

  // ---------- Dabbing ----------

  bool isDabbed(Ticket t, int n) => t.dabs.contains(n);

  void toggleDab(int ticketIndex, int n) {
    if (over) return;
    final t = me.tickets[ticketIndex];
    final key = '$ticketIndex:$n';
    if (t.dabs.remove(n)) {
      dabLooks[t]?.remove(n);
      wrong.remove(key);
      notifyListeners();
      return;
    }
    _dab(t, n);
    fx.play(Sfx.dab);
    fx.buzz(Buzz.dab);
    if (!calledSet.contains(n)) {
      wrong.add(key);
      toast("$n hasn't been called yet — tap again to undo");
    }
    notifyListeners();
  }

  void _dab(Ticket t, int n) {
    t.dabs.add(n);
    (dabLooks[t] ??= {})[n] = DabLook(rng);
  }

  void _autoDab(int n) {
    for (final t in me.tickets) {
      if (!t.contains(n) || t.dabs.contains(n)) continue;
      t.dabs.add(n);
      _later(const Duration(milliseconds: 700), () {
        (dabLooks[t] ??= {})[n] = DabLook(rng);
        fx.play(Sfx.dab);
        notifyListeners();
      });
    }
  }

  // ---------- Computer players ----------

  void _botsConsider() {
    bool has(int n) => calledSet.contains(n);
    for (final bot in players.skip(1)) {
      for (final p in prizes) {
        if (claimed.containsKey(p.key)) continue;
        final key = '${bot.id}:${p.key}';
        if (_pending.contains(key)) continue;
        if (!bot.tickets.any((t) => meets(p.key, t, has))) continue;
        if (rng.nextDouble() > bot.skill) continue; // didn't notice this time — may spot it next call
        _pending.add(key);
        final base = settings.speed == 0 ? 4500 : settings.speed;
        final ms = base * 0.3 + rng.nextDouble() * base * 0.55 + 800;
        _later(Duration(milliseconds: ms.round()), () {
          _pending.remove(key);
          if (!over && !claimed.containsKey(p.key)) _award(bot, p.key);
        });
      }
    }
  }

  // ---------- Claims ----------

  void claim(String key) {
    if (over || stage != Stage.playing) return;
    final owner = claimed[key];
    if (owner != null) {
      toast('Already claimed by ${owner.name}');
      return;
    }
    final winning = me.tickets.indexWhere((t) => meets(key, t, (n) => calledSet.contains(n) && t.dabs.contains(n)));
    if (winning >= 0) {
      _award(me, key, ticketIndex: winning);
      return;
    }
    if (me.tickets.any((t) => meets(key, t, calledSet.contains))) {
      toast('So close! Dab all the numbers for that prize first.');
      return;
    }
    fx.play(Sfx.bogey);
    fx.say('Bogey!');
    _emit(AnnounceEvent('Bogey!', 'Not quite — keep playing', bogey: true));
  }

  void _award(Player player, String key, {int? ticketIndex}) {
    final prize = prizeByKey(key);
    claimed[key] = player;
    player.points += prize.points;
    player.wins.add(key);
    claimingPlayer = player.id;
    _later(const Duration(milliseconds: 1200), () {
      if (claimingPlayer == player.id) claimingPlayer = null;
      notifyListeners();
    });

    _holding = true;
    _later(const Duration(milliseconds: 2800), () => _holding = false);
    if (player.human) {
      fx.play(Sfx.win);
      fx.buzz(Buzz.win);
      winnerTicket = ticketIndex;
      _later(const Duration(milliseconds: 3500), () {
        winnerTicket = null;
        notifyListeners();
      });
      _emit(AnnounceEvent(prize.label, 'You win ${prize.points} points!'));
      fx.say('${prize.label}! Well done ${player.name}!');
    } else {
      fx.play(Sfx.lose);
      _emit(AnnounceEvent(prize.label, '${player.name} claims it — checked ✓'));
      fx.say('${prize.label} to ${player.name}!');
    }

    if (key == 'full') {
      over = true;
      _drawTimer?.cancel();
      _later(const Duration(milliseconds: 2900), _endGame);
    } else {
      _scheduleDraw(Duration(milliseconds: max(settings.speed, 3200)));
    }
    notifyListeners();
  }

  void _endGame() {
    _clearTimers();
    over = true;
    fx.keepAwake(false);
    stage = Stage.results;
    notifyListeners();
  }

  List<Player> get ranked => List.of(players)..sort((a, b) => b.points != a.points ? b.points - a.points : a.id - b.id);

  @override
  void dispose() {
    _clearTimers();
    fx.keepAwake(false);
    _events.close();
    super.dispose();
  }
}
