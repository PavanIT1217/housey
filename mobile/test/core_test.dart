import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:housey/core/calls.dart';
import 'package:housey/core/number_draw.dart';
import 'package:housey/core/prizes.dart';
import 'package:housey/core/print_options.dart';
import 'package:housey/core/random.dart';
import 'package:housey/core/ticket_code.dart';
import 'package:housey/core/tickets.dart';

void expectValidGrid(List<List<int>> grid) {
  final t = Ticket('TEST', grid);
  expect(t.numbers, hasLength(15));
  expect(t.numbers.toSet(), hasLength(15), reason: 'no repeats');
  for (var r = 0; r < 3; r++) {
    expect(t.row(r), hasLength(5), reason: 'five numbers per row');
  }
  for (var c = 0; c < 9; c++) {
    final col = [for (var r = 0; r < 3; r++) grid[r][c]].where((n) => n != 0).toList();
    expect(col, isNotEmpty, reason: 'every column is used');
    final (lo, hi) = columnRange(c);
    expect(col.every((n) => n >= lo && n <= hi), isTrue, reason: 'column $c holds its decade');
    expect(col, orderedEquals(List.of(col)..sort()), reason: 'sorted down the column');
  }
}

void main() {
  group('tickets', () {
    test('follow the Housey layout', () {
      final rnd = seededRandom('rules');
      for (var i = 0; i < 2000; i++) {
        expectValidGrid(generateGrid(rnd));
      }
    });

    // The website (js/core) checks the same file: a code must give the same
    // ticket in the app and on the web, or printed tickets stop matching.
    test('match the website for every shared fixture code', () {
      final file = File('../tests/fixtures/ticket-codes.json');
      final fixtures = (jsonDecode(file.readAsStringSync()) as Map)['tickets'] as List;
      expect(fixtures.length, greaterThanOrEqualTo(40));
      for (final f in fixtures) {
        final ticket = ticketFromCode(f['code'] as String)!;
        expect(ticket.grid, f['grid'], reason: f['code'] as String);
      }
    });

    test('a batch has no repeated codes', () {
      final tickets = createTickets(300);
      expect(tickets.map((t) => t.code).toSet(), hasLength(300));
    });
  });

  group('ticket codes', () {
    test('are cleaned up and checked', () {
      expect(normalizeTicketCode(' hnzv c92z '), 'HNZV-C92Z');
      expect(normalizeTicketCode('HNZVC92Z'), 'HNZV-C92Z');
      expect(normalizeTicketCode(''), isNull);
      expect(normalizeTicketCode('HNZV-C92'), isNull);
      expect(normalizeTicketCode('HNZV-C9#Z'), isNull);
      expect(ticketFromCode('nonsense'), isNull);
    });

    test('read look-alike letters as digits', () {
      final code = createTicketCode(seededRandom('lookalike'));
      expect(normalizeTicketCode(code.replaceAll('0', 'O').replaceAll('1', 'I')), code);
    });

    test('reject most typos', () {
      const alphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';
      final rnd = seededRandom('typos');
      var typos = 0, caught = 0;
      for (var i = 0; i < 100; i++) {
        final raw = createTicketCode(rnd).replaceAll('-', '');
        for (var pos = 0; pos < raw.length; pos++) {
          for (final ch in alphabet.split('')) {
            if (ch == raw[pos]) continue;
            typos++;
            if (normalizeTicketCode(raw.replaceRange(pos, pos + 1, ch)) == null) caught++;
          }
        }
      }
      expect(caught / typos, greaterThan(.95));
    });

    test('are found in ticket links and scanned text', () {
      expect(extractTicketCode('https://housey.webappslab.com/ticket.html?t=hnzv-c92z'), 'HNZV-C92Z');
      expect(extractTicketCode('https://example.com/ticket.html#t=HNZV-C92Z'), 'HNZV-C92Z');
      expect(extractTicketCode('HNZV-C92Z'), 'HNZV-C92Z');
      expect(extractTicketCode('https://example.com/'), isNull);
    });
  });

  test('prize rules', () {
    final t = ticketFromCode('HNZV-C92Z')!;
    final top = t.row(0).toSet();
    expect(meets('top', t, top.contains), isTrue);
    expect(meets('middle', t, top.contains), isFalse);
    expect(meets('early5', t, top.contains), isTrue);
    expect(meets('early5', t, top.skip(1).toSet().contains), isFalse);
    expect(meets('full', t, t.numbers.toSet().contains), isTrue);
    expect(prizesMet(t, top.contains).map((p) => p.key), ['early5', 'top']);
  });

  group('calls', () {
    test('the default is just the number, with no traditional phrase', () {
      expect(describeCall(22), (display: 'Number 22', speech: 'Number 22.'));
    });

    test('every style says every number', () {
      for (final style in CallStyle.values) {
        for (var n = 1; n <= 90; n++) {
          expect(describeCall(n, style).speech, contains('$n'));
        }
      }
      expect(describeCall(22, CallStyle.traditional).speech, 'Two little ducks. two and two, 22.');
      expect(describeCall(7, CallStyle.digits).display, 'Single number 7');
      expect(traditionalCalls, hasLength(91));
    });
  });

  group('the bag', () {
    test('gives each number once, and undo puts the last one back', () {
      final draw = NumberDraw.shuffled();
      final a = draw.next(), b = draw.next();
      expect(draw.undo(), b);
      expect(draw.called, [a]);
      expect(draw.next(), b);
      while (draw.next() != null) {}
      expect(draw.called.toSet(), hasLength(90));
      expect(draw.isFinished, isTrue);
    });

    test('survives saving and loading, and rejects damaged data', () {
      final draw = NumberDraw.shuffled();
      for (var i = 0; i < 17; i++) {
        draw.next();
      }
      final again = NumberDraw.fromJson(jsonDecode(jsonEncode(draw.toJson())))!;
      expect(again.called, draw.called);
      expect(again.next(), draw.next());
      final good = NumberDraw.shuffled().toJson();
      expect(NumberDraw.fromJson(null), isNull);
      expect(NumberDraw.fromJson({'remaining': (good['remaining'] as List).skip(1).toList(), 'called': []}), isNull);
      expect(NumberDraw.fromJson({'remaining': 'x', 'called': []}), isNull);
    });
  });

  group('print options', () {
    test('are filled in and kept in range', () {
      final o = PrintOptions.fromJson({
        'count': 99999,
        'layout': 'huge',
        'theme': 'neon',
        'startNumber': -3,
        'title': 'x' * 99,
      });
      expect(o.count, maxPrintTickets);
      expect(o.layout, 'standard');
      expect(o.theme, 'classic');
      expect(o.startNumber, 1);
      expect(o.title, hasLength(40));
      expect(PrintOptions.fromJson({'count': 'abc'}).count, 6);
    });

    test('presets are valid', () {
      for (final p in printPresets) {
        final o = const PrintOptions().merge(p.options);
        expect(o.toJson(), containsPair('count', p.options['count']));
        expect(o.theme, p.options['theme']);
      }
    });

    test('mixed colours vary by ticket, and tickets split into pages', () {
      final mix = const PrintOptions(theme: mixedTheme);
      expect(mix.colorFor(0), isNot(mix.colorFor(1)));
      expect(paginate([1, 2, 3, 4, 5, 6, 7], 3), [
        [1, 2, 3],
        [4, 5, 6],
        [7],
      ]);
    });
  });
}
