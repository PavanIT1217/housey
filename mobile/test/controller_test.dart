import 'dart:math';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:housey/game/controller.dart';
import 'package:housey/game/rules.dart';
import 'package:housey/game/settings.dart';

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
      while (!ticket.row(0).every(g.calledSet.contains)) {
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
      final mine = g.me.tickets.expand((t) => t.numbers).where(g.calledSet.contains);
      expect(g.me.tickets.expand((t) => t.dabs), containsAll(mine));
      final total = g.players.fold<int>(0, (sum, p) => sum + p.points);
      expect(total, prizes.fold<int>(0, (sum, p) => sum + p.points));
    });
  });
}
