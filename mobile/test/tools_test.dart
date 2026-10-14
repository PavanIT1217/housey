import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:housey/core/print_options.dart';
import 'package:housey/core/tickets.dart';
import 'package:housey/game/caller_controller.dart';
import 'package:housey/game/my_tickets.dart';
import 'package:housey/services/settings.dart';
import 'package:housey/services/storage.dart';
import 'package:housey/services/ticket_pdf.dart';
import 'package:housey/services/ticket_service.dart';

void main() {
  group('number caller', () {
    test('calls on a timer, pauses, undoes and is saved', () {
      fakeAsync((async) {
        final store = MemoryStore();
        final slot = JsonRecord(store, StoreKeys.callerSession, 1);
        final s = Settings()..callerSpeed = 3000;
        final c = CallerController(settings: s, saveSlot: slot);
        expect(c.called, isEmpty);
        c.start();
        expect(c.called, hasLength(1));
        async.elapse(const Duration(seconds: 9));
        expect(c.called, hasLength(4));
        expect(c.callText, 'Number ${c.currentCoin}');
        c.stop();
        async.elapse(const Duration(minutes: 1));
        expect(c.called, hasLength(4));

        final last = c.called.last;
        c.undo();
        expect(c.called, hasLength(3));
        expect(c.callText, '$last put back in the bag');

        final again = CallerController(settings: s, saveSlot: slot);
        expect(again.called, c.called);
        again.tapBag();
        expect(again.called.last, last, reason: 'an undone number comes out next');

        again.newGame();
        expect(again.called, isEmpty);
        c.dispose();
        again.dispose();
      });
    });

    test('checks a ticket against the numbers called', () {
      final c = CallerController(settings: Settings());
      final ticket = ticketFromCode('HNZV-C92Z')!;
      c.check(ticket);
      expect(c.checkedHits, 0);
      while (!ticket.row(0).every(c.isCalled)) {
        c.tapBag();
      }
      expect(c.checkedPrizes.map((p) => p.key), contains('top'));
      c.dispose();
    });

    test('stops when the bag is empty', () {
      final c = CallerController(settings: Settings());
      for (var i = 0; i < 95; i++) {
        c.tapBag();
      }
      expect(c.called, hasLength(90));
      expect(c.isFinished, isTrue);
      expect(c.callText, 'All 90 numbers have been called');
      c.dispose();
    });
  });

  test('my tickets keeps tickets and dabs, with no duplicates', () async {
    final slot = JsonRecord(MemoryStore(), StoreKeys.myTickets, 1);
    final mine = MyTickets(saveSlot: slot);
    final ticket = (await findTicket(ticketLink('HNZV-C92Z')))!;
    mine.add(ticket);
    mine.add(ticketFromCode('hnzv c92z')!);
    expect(mine.tickets, hasLength(1));
    mine.toggleDab(ticket, ticket.numbers.first);

    final again = MyTickets(saveSlot: slot);
    expect(again.tickets.single.code, 'HNZV-C92Z');
    expect(again.tickets.single.dabs, {ticket.numbers.first});
    again.remove(again.tickets.single);
    expect(MyTickets(saveSlot: slot).tickets, isEmpty);
    expect(await findTicket('ABCD-EFGH'), isNull);
  });

  test('settings keep the old voice switch and range-check new values', () {
    final store = MemoryStore()..setString(StoreKeys.settings, '{"speed": 999999, "voice": false, "tickets": 9}');
    final s = Settings.load(store);
    expect(s.voice.on, isFalse);
    expect(s.speed, Speed.max);
    expect(s.tickets, 3);
    s.voice.rate = 1.3;
    s.save();
    expect(Settings.load(store).voice.rate, 1.3);
  });

  test('the ticket PDF has one A4 page per sheet of tickets', () async {
    final tickets = createTickets(13);
    for (final layout in pageLayouts) {
      final options = PrintOptions(count: 13, layout: layout.key, theme: mixedTheme, footer: 'Sunday 7 pm');
      final bytes = await buildTicketsPdf(tickets, options);
      final pdf = String.fromCharCodes(bytes);
      expect(pdf, startsWith('%PDF'));
      final pages = RegExp(r'/Type\s*/Page\b').allMatches(pdf).length;
      expect(pages, (13 / layout.perPage).ceil(), reason: layout.key);
    }
  });
}
