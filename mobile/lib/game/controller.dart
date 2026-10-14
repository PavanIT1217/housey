import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../core/calls.dart';
import '../core/number_draw.dart';
import '../core/prizes.dart';
import '../core/random.dart';
import '../core/tickets.dart';
import '../services/fx.dart';
import '../services/settings.dart';
import '../services/storage.dart';
import 'table_events.dart';

export 'table_events.dart';

const botNames = ['Priya', 'Ravi', 'Aunty Meena', 'Uncle Joe', 'Fatima', 'Sam', 'Grandpa Dev', 'Lucy', 'Arjun', 'Rosa'];
const botColors = [0xFFC0392B, 0xFF2471A3, 0xFF7D3C98, 0xFF1E8449, 0xFFB9770E, 0xFFA04000, 0xFF117A65, 0xFF884EA0];
const _myColor = 0xFFB3261E;

class Player {
  Player({
    required this.id,
    required this.name,
    required this.color,
    required this.tickets,
    this.skill = 1,
    this.points = 0,
    List<String>? wins,
  }) : human = id == 0,
       wins = wins ?? [];

  final int id;
  final String name;
  final int color;
  final bool human;
  final List<Ticket> tickets;

  /// Chance a computer player notices a finished prize on each call.
  final double skill;
  int points;
  final List<String> wins;

  String get displayName => human && name != 'You' ? '$name (you)' : name;

  Map<String, Object> toJson() => {
    'id': id,
    'name': name,
    'color': color,
    'skill': skill,
    'points': points,
    'wins': wins,
    'tickets': [
      for (final t in tickets) {'code': t.code, 'dabs': t.dabs.toList()},
    ],
  };

  /// Rebuilds a saved player; throws if the data is damaged.
  static Player fromJson(Map json) {
    final tickets = [
      for (final t in json['tickets'] as List)
        (ticketFromCode(t['code'] as String) ?? (throw const FormatException('bad ticket code')))
          ..dabs.addAll((t['dabs'] as List).cast<int>()),
    ];
    return Player(
      id: json['id'] as int,
      name: json['name'] as String,
      color: json['color'] as int,
      tickets: tickets,
      skill: (json['skill'] as num).toDouble(),
      points: json['points'] as int,
      wins: (json['wins'] as List).cast<String>(),
    );
  }
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

enum Stage { setup, playing, results }

/// Runs a game of Housey: the caller, the computer players and the claims.
/// The game is saved as it goes, so closing the app doesn't lose it.
class GameController extends ChangeNotifier with TableEvents implements CallerMatModel {
  GameController({required this.settings, Fx? fx, Random? random, this.saveSlot})
    : fx = fx ?? Fx(),
      rng = random ?? Random() {
    // Preview a ticket behind the setup card so the table never looks empty.
    players = [
      Player(id: 0, name: 'You', color: _myColor, tickets: [createTicket(fromRandom(rng))]),
    ];
    _saved = _loadSaved();
  }

  final Settings settings;
  final Fx fx;
  final Random rng;

  /// Where the state is saved; null to not save (tests).
  final JsonRecord? saveSlot;

  Stage stage = Stage.setup;
  late List<Player> players;
  Player get me => players.first;

  NumberDraw _draw = NumberDraw.shuffled();
  final Map<String, Player> claimed = {};
  bool paused = false;
  bool over = true;

  /// A game in progress from an earlier visit, offered on the setup card.
  _SavedGame? _saved;

  /// The caller waits a moment after each claim before drawing again.
  bool _holding = false;
  final Set<String> _pending = {};

  @override
  int? currentCoin;
  @override
  final List<int> tray = [];
  @override
  String callText = 'Ready when you are';

  /// Looks of the dabs on each of my tickets, keyed by number.
  final Map<Ticket, Map<int, DabLook>> dabLooks = {};

  /// Cells dabbed before their number was called, as "ticketIndex:number".
  final Set<String> wrong = {};
  int? winnerTicket;
  int? claimingPlayer;

  final List<Timer> _timers = [];
  Timer? _drawTimer;

  List<int> get called => _draw.called;
  bool isCalled(int n) => _draw.has(n);

  /// Whether [n] has a chip on the caller's board: called, and its coin has landed.
  bool onBoard(int n) => isCalled(n) && (n != _draw.last || currentCoin == n);

  @override
  String get callCount => '${_draw.count} / 90 called';
  @override
  int get drawCount => _draw.count;
  @override
  bool get invitesTap => settings.manual && stage == Stage.playing && !over;

  /// How many numbers the saved game had called, or null if there's nothing to resume.
  int? get resumableCount => _saved?.draw.count;

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

  // ---------- Saving ----------

  void _save() {
    final slot = saveSlot;
    if (slot == null) return;
    if (over) {
      slot.clear();
      return;
    }
    slot.save({
      'draw': _draw.toJson(),
      'players': [for (final p in players) p.toJson()],
      'claimed': {for (final e in claimed.entries) e.key: e.value.id},
    });
  }

  _SavedGame? _loadSaved() {
    final data = saveSlot?.load();
    if (data is! Map) return null;
    final draw = NumberDraw.fromJson(data['draw']);
    if (draw == null) return null;
    try {
      final players = [for (final p in data['players'] as List) Player.fromJson(p as Map)];
      if (players.isEmpty || !players.first.human) return null;
      final claimed = <String, Player>{
        for (final e in (data['claimed'] as Map).entries) e.key as String: players.firstWhere((p) => p.id == e.value),
      };
      return _SavedGame(draw, players, claimed);
    } catch (_) {
      return null;
    }
  }

  // ---------- Game flow ----------

  void start() {
    settings.save();
    newGame();
  }

  void newGame() {
    _clearTimers();
    final names = (List.of(botNames)..shuffle(rng)).take(settings.bots).toList();
    final name = settings.name.trim();
    players = [
      Player(id: 0, name: name.isEmpty ? 'You' : name, color: _myColor, tickets: _deal()),
      for (var i = 0; i < names.length; i++)
        Player(
          id: i + 1,
          name: names[i],
          color: botColors[i % botColors.length],
          tickets: _deal(),
          skill: 0.55 + rng.nextDouble() * 0.35,
        ),
    ];
    _reset(NumberDraw.shuffled(rng));
    _saved = null;
    if (settings.manual) {
      callText = 'Tap the bag to draw';
    } else {
      callText = 'Shuffling the coins…';
      _scheduleDraw(const Duration(milliseconds: 1800));
    }
    fx.keepAwake(true);
    _save();
    notifyListeners();
  }

  /// Carries on the game saved earlier (from this visit or a previous one).
  void resume() {
    final saved = _saved;
    if (saved == null) return;
    settings.save();
    _clearTimers();
    players = saved.players;
    _reset(saved.draw);
    claimed.addAll(saved.claimed);
    _saved = null;
    for (var i = 0; i < me.tickets.length; i++) {
      final t = me.tickets[i];
      for (final n in t.dabs) {
        (dabLooks[t] ??= {})[n] = DabLook(rng);
        if (!isCalled(n)) wrong.add('$i:$n');
      }
    }
    final calledNow = _draw.called;
    currentCoin = _draw.last;
    if (calledNow.length > 1) {
      tray.addAll(calledNow.sublist(max(0, calledNow.length - 7), calledNow.length - 1).reversed);
    }
    paused = !settings.manual;
    callText = settings.manual ? 'Welcome back. Tap the bag to draw' : 'Welcome back. Press ▶ to carry on';
    fx.keepAwake(true);
    _botsConsider();
    notifyListeners();
  }

  void _reset(NumberDraw draw) {
    _draw = draw;
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
  }

  List<Ticket> _deal() => createTickets(settings.tickets, fromRandom(rng));

  void openSetup() {
    _clearTimers();
    fx.hush();
    if (stage == Stage.playing && !over) {
      paused = true;
      _saved = _SavedGame(_draw, players, Map.of(claimed));
    }
    stage = Stage.setup;
    notifyListeners();
  }

  void _scheduleDraw(Duration d) {
    _drawTimer?.cancel();
    if (over || paused || settings.manual || stage != Stage.playing) return;
    _drawTimer = Timer(d, drawNext);
  }

  Duration get _speed => Duration(milliseconds: settings.speed);

  /// Changes the time between calls, including mid-game.
  void setSpeed(int ms) {
    final wasManual = settings.manual;
    settings.speed = ms;
    settings.save();
    if (stage == Stage.playing && !over) {
      if (settings.manual) {
        _drawTimer?.cancel();
        paused = false;
        callText = 'Tap the bag to draw';
      } else if (wasManual) {
        paused = true;
        callText = 'Press ▶ to start the caller';
      } else {
        _scheduleDraw(_speed);
      }
    }
    notifyListeners();
  }

  void drawNext() {
    if (over || stage != Stage.playing) return;
    if (_holding) {
      if (!settings.manual) _scheduleDraw(const Duration(milliseconds: 300));
      return;
    }
    final n = _draw.next();
    if (n == null) {
      _endGame();
      return;
    }
    _save();
    emit(BagShakeEvent());
    fx.play(Sfx.rummage);

    _later(const Duration(milliseconds: 550), () {
      final prev = currentCoin;
      if (prev != null) {
        tray.insert(0, prev);
        if (tray.length > 6) tray.removeLast();
      }
      currentCoin = n;
      _later(const Duration(milliseconds: 350), () => fx.play(Sfx.clack));
      callText = describeCall(n, settings.voice.style).display;
      fx.say(settings.voice.speechFor(n));

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

  @override
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
      callText = 'Paused. Take a breather';
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
    settings.save();
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
      _save();
      notifyListeners();
      return;
    }
    _dab(t, n);
    fx.play(Sfx.dab);
    fx.buzz(Buzz.dab);
    if (!isCalled(n)) {
      wrong.add(key);
      toast("$n hasn't been called yet. Tap again to undo");
    }
    _save();
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
    _save();
  }

  // ---------- Computer players ----------

  void _botsConsider() {
    for (final bot in players.skip(1)) {
      for (final p in prizes) {
        if (claimed.containsKey(p.key)) continue;
        final key = '${bot.id}:${p.key}';
        if (_pending.contains(key)) continue;
        if (!bot.tickets.any((t) => meets(p.key, t, isCalled))) continue;
        if (rng.nextDouble() > bot.skill) continue; // didn't notice this time; may spot it next call
        _pending.add(key);
        final base = settings.manual ? 4500 : settings.speed;
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
    final winning = me.tickets.indexWhere((t) => meets(key, t, (n) => isCalled(n) && t.dabs.contains(n)));
    if (winning >= 0) {
      _award(me, key, ticketIndex: winning);
      return;
    }
    if (me.tickets.any((t) => meets(key, t, isCalled))) {
      toast('So close! Dab all the numbers for that prize first.');
      return;
    }
    fx.play(Sfx.bogey);
    fx.say('Bogey!');
    emit(AnnounceEvent('Bogey!', 'Not quite. Keep playing', bogey: true));
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
      emit(AnnounceEvent(prize.label, 'You win ${prize.points} points!'));
      fx.say('${prize.label}! Well done ${player.name}!');
    } else {
      fx.play(Sfx.lose);
      emit(AnnounceEvent(prize.label, '${player.name} claims it, checked ✓'));
      fx.say('${prize.label} to ${player.name}!');
    }

    if (key == 'full') {
      over = true;
      _drawTimer?.cancel();
      _later(const Duration(milliseconds: 2900), _endGame);
    } else {
      _scheduleDraw(Duration(milliseconds: max(settings.speed, 3200)));
    }
    _save();
    notifyListeners();
  }

  void _endGame() {
    _clearTimers();
    over = true;
    _save();
    fx.keepAwake(false);
    stage = Stage.results;
    notifyListeners();
  }

  List<Player> get ranked => List.of(players)..sort((a, b) => b.points != a.points ? b.points - a.points : a.id - b.id);

  @override
  void dispose() {
    _clearTimers();
    fx.keepAwake(false);
    closeEvents();
    super.dispose();
  }
}

class _SavedGame {
  _SavedGame(this.draw, this.players, this.claimed);
  final NumberDraw draw;
  final List<Player> players;
  final Map<String, Player> claimed;
}
