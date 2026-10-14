// Tambola tickets: 3 rows x 9 columns, 5 numbers per row, 15 in all.
// Generation follows js/core/tickets.js step for step, so a code gives the
// same ticket in the app and on the website.

import 'random.dart';
import 'ticket_code.dart';

const rows = 3;
const columns = 9;
const numbersPerRow = 5;
const highestNumber = 90;

// Part of every ticket's seed. Bump it only together with a code format change.
const _generatorVersion = 'v1';

/// The lowest and highest number column [c] can hold.
(int, int) columnRange(int c) => (c == 0 ? 1 : c * 10, c == columns - 1 ? highestNumber : c * 10 + 9);

/// A paper ticket. 0 marks an empty cell. [dabs] are the numbers inked on it.
class Ticket {
  Ticket(this.code, this.grid);

  final String code;
  final List<List<int>> grid;
  final Set<int> dabs = {};

  List<int> row(int r) => grid[r].where((n) => n != 0).toList();
  List<int> get numbers => [for (final r in grid) ...r.where((n) => n != 0)];
  bool contains(int n) => grid.any((r) => r.contains(n));
}

/// Builds a ticket grid using the given random source.
List<List<int>> generateGrid(RandomSource rnd) {
  for (;;) {
    // How many numbers each column gets: 1 each, then 6 more spread around (max 3).
    final counts = List.filled(columns, 1);
    for (var extra = rows * numbersPerRow - columns; extra > 0;) {
      final c = randomInt(columns, rnd);
      if (counts[c] < rows) {
        counts[c]++;
        extra--;
      }
    }

    // Which rows those numbers sit in, keeping 5 per row. Fullest columns go first.
    final layout = List.generate(rows, (_) => List.filled(columns, false));
    final rowCount = List.filled(rows, 0);
    final order = stableSort(shuffleWith(List.generate(columns, (i) => i), rnd), (a, b) => counts[b] - counts[a]);
    var ok = true;
    for (final c in order) {
      final free = shuffleWith([
        for (var r = 0; r < rows; r++)
          if (rowCount[r] < numbersPerRow) r,
      ], rnd);
      stableSort(free, (a, b) => rowCount[a] - rowCount[b]);
      if (free.length < counts[c]) {
        ok = false;
        break;
      }
      for (final r in free.take(counts[c])) {
        layout[r][c] = true;
        rowCount[r]++;
      }
    }
    if (!ok || rowCount.any((n) => n != numbersPerRow)) continue;

    final grid = List.generate(rows, (_) => List.filled(columns, 0));
    for (var c = 0; c < columns; c++) {
      final (lo, hi) = columnRange(c);
      final pool = shuffleWith(List.generate(hi - lo + 1, (i) => lo + i), rnd).take(counts[c]).toList()..sort();
      for (var r = 0; r < rows; r++) {
        if (layout[r][c]) grid[r][c] = pool.removeAt(0);
      }
    }
    return grid;
  }
}

/// The ticket a code stands for, or null if the code isn't valid.
Ticket? ticketFromCode(String? input) {
  final code = normalizeTicketCode(input);
  if (code == null) return null;
  return Ticket(code, generateGrid(seededRandom('housey-ticket-$_generatorVersion:$code')));
}

/// A brand-new ticket with a fresh code.
Ticket createTicket([RandomSource? rnd]) => ticketFromCode(createTicketCode(rnd))!;

/// [count] tickets with no repeated codes.
List<Ticket> createTickets(int count, [RandomSource? rnd]) {
  final tickets = <String, Ticket>{};
  while (tickets.length < count) {
    final t = createTicket(rnd);
    tickets[t.code] = t;
  }
  return tickets.values.toList();
}
