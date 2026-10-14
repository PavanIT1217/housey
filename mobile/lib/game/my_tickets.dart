import 'package:flutter/foundation.dart';

import '../core/tickets.dart';
import '../services/storage.dart';

/// Tickets opened on this phone (from a QR code or a typed code), with their dabs.
class MyTickets extends ChangeNotifier {
  MyTickets({this.saveSlot}) {
    final saved = saveSlot?.load();
    if (saved is List) {
      for (final item in saved) {
        if (item is! Map) continue;
        final ticket = ticketFromCode(item['code'] as String?);
        final dabs = item['dabs'];
        if (ticket == null) continue;
        if (dabs is List) ticket.dabs.addAll(dabs.whereType<int>());
        tickets.add(ticket);
      }
    }
  }

  /// Where the state is saved; null to not save (tests).
  final JsonRecord? saveSlot;

  /// Newest first.
  final List<Ticket> tickets = [];

  void _save() => saveSlot?.save([
    for (final t in tickets) {'code': t.code, 'dabs': t.dabs.toList()},
  ]);

  /// Adds a ticket unless it's already here. Returns its position in the list.
  int add(Ticket ticket) {
    final existing = tickets.indexWhere((t) => t.code == ticket.code);
    if (existing >= 0) return existing;
    tickets.insert(0, ticket);
    _save();
    notifyListeners();
    return 0;
  }

  void toggleDab(Ticket ticket, int n) {
    if (!ticket.dabs.remove(n)) ticket.dabs.add(n);
    _save();
    notifyListeners();
  }

  void clearDabs(Ticket ticket) {
    ticket.dabs.clear();
    _save();
    notifyListeners();
  }

  void remove(Ticket ticket) {
    tickets.remove(ticket);
    _save();
    notifyListeners();
  }
}
