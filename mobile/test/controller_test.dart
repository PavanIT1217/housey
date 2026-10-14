import 'dart:math';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:housey/game/controller.dart';
import 'package:housey/core/prizes.dart';
import 'package:housey/services/settings.dart';
import 'package:housey/services/storage.dart';

GameController newGame({int bots = 0, int speed = 3500, bool auto = false}) {
  final s = Settings()
    ..bots = bots
    ..speed = speed
    ..auto = auto;
  return GameController(settings: s, random: Random(7))..newGame();
}

void main() {
  test('the caller draws every number once on a timer', () {
    fakeAsync((async) {
      final g = newGame();
      async.elapse(const Duration(minutes: 10));
      expect(g.called, hasLength(90));
      expect(g.called.toSet(), hasLength(90));
      expect(g.stage, Stage.results);
    });
  });

  test('pause stops the caller', () {
    fakeAsync((async) {
      final g = newGame();
      async.elapse(const Duration(seconds: 10));
      final n = g.called.length;
      g.togglePause();
      async.elapse(const Duration(minutes: 1));
      expect(g.called.length, n);
      g.togglePause();
      async.elapse(const Duration(seconds: 10));
      expect(g.called.length, greaterThan(n));
    });
  });

  test('manual mode only draws when the bag is tapped', () {
    fakeAsync((async) {
      final g = newGame(speed: 0);
      async.elapse(const Duration(minutes: 1));
      expect(g.called, isEmpty);
      g.tapBag();
      async.elapse(const Duration(seconds: 1));
      expect(g.called, hasLength(1));
      expect(g.currentCoin, g.called.single);
    });
  });

  test('claims: bogey, near miss, then a real win', () {
    fakeAsync((async) {
      final g = newGame(speed: 0);
      final events = <TableEvent>[];
      g.events.listen(events.add);

      g.claim('top');
      async.flushMicrotasks();
      expect(events.whereType<AnnounceEvent>().single.bogey, isTrue);

      // Draw until the top row of ticket 1 is complete.
      final ticket = g.me.tickets.first;
      while (!ticket.row(0).every(g.isCalled)) {
        g.tapBag();
        async.elapse(const Duration(seconds: 1));
      }
      g.claim('top');
      async.flushMicrotasks();
      expect(events.whereType<ToastEvent>().last.message, contains('So close'));
      expect(g.claimed['top'], isNull);

      for (final n in ticket.row(0)) {
        g.toggleDab(0, n);
      }
      g.claim('top');
      expect(g.claimed['top'], same(g.me));
      expect(g.me.points, prizeByKey('top').points);
    });
  });

  test('dabbing a number before it is called is flagged until it comes up', () {
    fakeAsync((async) {
      final g = newGame(speed: 0);
      final n = g.me.tickets.first.numbers.first;
      g.toggleDab(0, n);
      expect(g.wrong, contains('0:$n'));
      g.toggleDab(0, n);
      expect(g.wrong, isEmpty);
      expect(g.me.tickets.first.dabs, isEmpty);
    });
  });

  test('auto-dab marks my numbers and computer players claim prizes', () {
    fakeAsync((async) {
      final g = newGame(bots: 6, auto: true);
      async.elapse(const Duration(minutes: 15));
      expect(g.stage, Stage.results);
      expect(g.claimed.keys, containsAll(prizes.map((p) => p.key)));
      final mine = g.me.tickets.expand((t) => t.numbers).where(g.isCalled);
      expect(g.me.tickets.expand((t) => t.dabs), containsAll(mine));
      final total = g.players.fold<int>(0, (sum, p) => sum + p.points);
      expect(total, prizes.fold<int>(0, (sum, p) => sum + p.points));
    });
  });

  test('a game is saved as it goes and can be resumed after a restart', () {
    fakeAsync((async) {
      final store = MemoryStore();
      final slot = JsonRecord(store, StoreKeys.savedGame, 1);
      final s = Settings()..speed = 0;
      final g = GameController(settings: s, random: Random(3), saveSlot: slot)..newGame();
      for (var i = 0; i < 8; i++) {
        g.tapBag();
        async.elapse(const Duration(seconds: 1));
      }
      final n = g.me.tickets.first.numbers.first;
      g.toggleDab(0, n);
      final called = List.of(g.called);
      final codes = g.me.tickets.map((t) => t.code).toList();

      // A fresh controller is what the app makes after being closed.
      final again = GameController(settings: s, random: Random(4), saveSlot: slot);
      expect(again.resumableCount, 8);
      again.resume();
      expect(again.stage, Stage.playing);
      expect(again.called, called);
      expect(again.me.tickets.map((t) => t.code), codes);
      expect(again.me.tickets.first.dabs, contains(n));
      expect(again.currentCoin, called.last);
      again.tapBag();
      async.elapse(const Duration(seconds: 1));
      expect(again.called, hasLength(9));
    });
  });

  test('a finished game is not offered for resuming', () {
    fakeAsync((async) {
      final slot = JsonRecord(MemoryStore(), StoreKeys.savedGame, 1);
      final s = Settings()..speed = 2000;
      GameController(settings: s, random: Random(5), saveSlot: slot).newGame();
      async.elapse(const Duration(minutes: 10));
      expect(GameController(settings: s, saveSlot: slot).resumableCount, isNull);
    });
  });

  test('the caller calls just the number by default, and the speed can change mid-game', () {
    fakeAsync((async) {
      final g = newGame(speed: 3500);
      async.elapse(const Duration(seconds: 3));
      expect(g.callText, 'Number ${g.currentCoin}');
      g.setSpeed(20000);
      final n = g.called.length;
      async.elapse(const Duration(seconds: 15));
      expect(g.called.length, n);
      async.elapse(const Duration(seconds: 6));
      expect(g.called.length, n + 1);
      g.setSpeed(0);
      async.elapse(const Duration(minutes: 1));
      expect(g.called.length, n + 1);
      expect(g.callText, 'Tap the bag to draw');
    });
  });
}
