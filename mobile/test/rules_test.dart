import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:housey/game/rules.dart';

void main() {
  test('tickets follow the Housey layout', () {
    for (var seed = 0; seed < 500; seed++) {
      final t = makeTicket(Random(seed));
      expect(t.numbers, hasLength(15));
      expect(t.numbers.toSet(), hasLength(15), reason: 'no repeats');
      for (var r = 0; r < 3; r++) {
        expect(t.row(r), hasLength(5), reason: 'five numbers per row');
      }
      for (var c = 0; c < 9; c++) {
        final col = [for (var r = 0; r < 3; r++) t.grid[r][c]].where((n) => n != 0).toList();
        expect(col, isNotEmpty, reason: 'every column is used');
        final lo = c == 0 ? 1 : c * 10, hi = c == 8 ? 90 : c * 10 + 9;
        expect(col.every((n) => n >= lo && n <= hi), isTrue, reason: 'column $c holds its decade');
        expect(col, orderedEquals(List.of(col)..sort()), reason: 'sorted down the column');
      }
    }
  });

  test('prize rules', () {
    final t = makeTicket(Random(1));
    final top = t.row(0).toSet();
    expect(meets('top', t, top.contains), isTrue);
    expect(meets('middle', t, top.contains), isFalse);
    expect(meets('early5', t, top.contains), isTrue);
    expect(meets('early5', t, top.skip(1).toSet().contains), isFalse);
    expect(meets('full', t, top.contains), isFalse);
    expect(meets('full', t, t.numbers.toSet().contains), isTrue);
  });

  test('every number has a call', () {
    expect(calls, hasLength(91));
    expect(spoken(7), 'Number 7.');
    expect(spoken(22), 'Number 22.');
    expect(traditionalCall(22), 'Two little ducks. two and two, 22.');
  });
}
