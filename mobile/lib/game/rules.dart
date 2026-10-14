import 'dart:math';

/// Traditional calls, indexed by number (index 0 is unused).
const calls = <String>[
  '',
  "Kelly's eye",
  'One little duck',
  'Cup of tea',
  'Knock at the door',
  'Man alive',
  'Half a dozen',
  'Lucky seven',
  'Garden gate',
  "Doctor's orders",
  'Cock and hen',
  'Legs eleven',
  'One dozen',
  'Unlucky for some',
  "Valentine's day",
  'Young and keen',
  'Sweet sixteen',
  'Dancing queen',
  'Coming of age',
  'Goodbye teens',
  'One score',
  'Key of the door',
  'Two little ducks',
  'Thee and me',
  'Two dozen',
  'Duck and dive',
  'Pick and mix',
  'Gateway to heaven',
  'Overweight',
  'Rise and shine',
  'Dirty Gertie',
  'Get up and run',
  'Buckle my shoe',
  'All the threes',
  'Ask for more',
  'Jump and jive',
  'Three dozen',
  'More than eleven',
  'Christmas cake',
  'Climb the steps',
  'Naughty forty',
  'Time for fun',
  'Winnie the Pooh',
  'Down on your knees',
  'Droopy drawers',
  'Halfway there',
  'Up to tricks',
  'Four and seven',
  'Four dozen',
  'P.C.',
  'Half a century',
  'Tweak of the thumb',
  'Danny La Rue',
  'Stuck in the tree',
  'Clean the floor',
  'Snakes alive',
  'Was she worth it',
  'Heinz varieties',
  'Make them wait',
  'Brighton line',
  'Five dozen',
  "Baker's bun",
  'Turn the screw',
  'Tickle me',
  'Red raw',
  'Old age pension',
  'Clickety click',
  'Stairway to heaven',
  'Saving grace',
  'Either way up',
  'Three score and ten',
  'Bang on the drum',
  'Six dozen',
  'Queen bee',
  'Candy store',
  'Strive and strive',
  'Trombones',
  'Sunset strip',
  "Heaven's gate",
  'One more time',
  'Eight and blank',
  'Stop and run',
  'Straight on through',
  'Time for tea',
  'Seven dozen',
  'Staying alive',
  'Between the sticks',
  'Torquay in Devon',
  'Two fat ladies',
  'Nearly there',
  'Top of the shop',
];

const _digits = ['zero', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine'];

/// What the caller says for [n]: just the number, e.g. "Number 22."
String spoken(int n) => 'Number $n.';

/// The traditional call for [n] with its digits, e.g. "Two little ducks. two and two, 22."
String traditionalCall(int n) =>
    n < 10 ? '${calls[n]}. Number $n.' : '${calls[n]}. ${_digits[n ~/ 10]} and ${_digits[n % 10]}, $n.';

class Prize {
  const Prize(this.key, this.label, this.points);
  final String key;
  final String label;
  final int points;
}

const prizes = <Prize>[
  Prize('early5', 'Early Five', 50),
  Prize('top', 'Top Line', 100),
  Prize('middle', 'Middle Line', 100),
  Prize('bottom', 'Bottom Line', 100),
  Prize('full', 'Full House', 250),
];

Prize prizeByKey(String key) => prizes.firstWhere((p) => p.key == key);

const botNames = ['Priya', 'Ravi', 'Aunty Meena', 'Uncle Joe', 'Fatima', 'Sam', 'Grandpa Dev', 'Lucy', 'Arjun', 'Rosa'];
const botColors = [0xFFC0392B, 0xFF2471A3, 0xFF7D3C98, 0xFF1E8449, 0xFFB9770E, 0xFFA04000, 0xFF117A65, 0xFF884EA0];

/// A paper ticket: 3 rows x 9 columns, 5 numbers per row, 0 marks a blank.
class Ticket {
  Ticket(this.grid, this.serial);

  final List<List<int>> grid;
  final String serial;
  final Set<int> dabs = {};

  List<int> row(int r) => grid[r].where((n) => n != 0).toList();
  List<int> get numbers => [for (final r in grid) ...r.where((n) => n != 0)];
  bool contains(int n) => grid.any((r) => r.contains(n));
}

List<T> _shuffle<T>(List<T> a, Random rng) => a..shuffle(rng);

/// Deals a valid ticket: every column has 1-3 numbers from its decade
/// (1-9, 10-19 … 80-90), sorted top to bottom, and every row has 5.
Ticket makeTicket(Random rng) {
  for (;;) {
    final counts = List.filled(9, 1);
    for (var extra = 6; extra > 0;) {
      final c = rng.nextInt(9);
      if (counts[c] < 3) {
        counts[c]++;
        extra--;
      }
    }

    final layout = List.generate(3, (_) => List.filled(9, false));
    final rowCount = [0, 0, 0];
    final order = _shuffle(List.generate(9, (i) => i), rng)..sort((a, b) => counts[b] - counts[a]);
    var ok = true;
    for (final c in order) {
      final rows = _shuffle([0, 1, 2].where((r) => rowCount[r] < 5).toList(), rng)
        ..sort((a, b) => rowCount[a] - rowCount[b]);
      if (rows.length < counts[c]) {
        ok = false;
        break;
      }
      for (final r in rows.take(counts[c])) {
        layout[r][c] = true;
        rowCount[r]++;
      }
    }
    if (!ok || rowCount.any((x) => x != 5)) continue;

    final grid = List.generate(3, (_) => List.filled(9, 0));
    for (var c = 0; c < 9; c++) {
      final lo = c == 0 ? 1 : c * 10, hi = c == 8 ? 90 : c * 10 + 9;
      final pool = (_shuffle(List.generate(hi - lo + 1, (i) => lo + i), rng).take(counts[c]).toList())..sort();
      for (var r = 0; r < 3; r++) {
        if (layout[r][c]) grid[r][c] = pool.removeAt(0);
      }
    }
    return Ticket(grid, '${10000 + rng.nextInt(89999)}');
  }
}

/// Whether [ticket] completes the prize [key], counting a number as marked when [has] says so.
bool meets(String key, Ticket ticket, bool Function(int) has) {
  switch (key) {
    case 'early5':
      return ticket.numbers.where(has).length >= 5;
    case 'top':
      return ticket.row(0).every(has);
    case 'middle':
      return ticket.row(1).every(has);
    case 'bottom':
      return ticket.row(2).every(has);
    case 'full':
      return ticket.numbers.every(has);
  }
  return false;
}
