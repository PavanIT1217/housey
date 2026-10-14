// The prizes and how a ticket wins each one.

import 'tickets.dart';

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

/// Every prize [ticket] has completed.
List<Prize> prizesMet(Ticket ticket, bool Function(int) has) => [
  for (final p in prizes)
    if (meets(p.key, ticket, has)) p,
];
