import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_services.dart';
import '../core/tickets.dart';
import '../game/controller.dart' show DabLook;
import '../game/my_tickets.dart';
import '../services/fx.dart';
import '../services/ticket_service.dart';
import 'look.dart';
import 'table_parts.dart';
import 'ticket_lookup.dart';
import 'tool_scaffold.dart';

/// Tickets opened on this phone from a QR code or code, dabbed on screen.
class MyTicketsScreen extends StatefulWidget {
  const MyTicketsScreen({super.key, required this.services});
  final AppServices services;

  @override
  State<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen> {
  late final _tickets = MyTickets(saveSlot: widget.services.myTickets);
  final _looks = <Ticket, Map<int, DabLook>>{};
  final _rng = Random();

  @override
  void dispose() {
    _tickets.dispose();
    super.dispose();
  }

  DabLook? _look(Ticket t, int n) => t.dabs.contains(n) ? (_looks[t] ??= {}).putIfAbsent(n, () => DabLook(_rng)) : null;

  void _dab(Ticket t, int n) {
    final fx = widget.services.fx;
    if (!t.dabs.contains(n)) {
      fx.play(Sfx.dab);
      fx.buzz(Buzz.dab);
    }
    _looks[t]?.remove(n);
    _tickets.toggleDab(t, n);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _tickets,
      builder: (context, _) => ToolScaffold(
        title: 'My tickets',
        children: [
          Panel(
            title: 'Open a ticket',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Note('Scan the QR code on a printed Housey ticket, or type the code printed next to it.'),
                const SizedBox(height: 10),
                TicketLookup(onTicket: _tickets.add),
              ],
            ),
          ),
          if (_tickets.tickets.isEmpty)
            Text(
              'Your tickets will show up here. They stay on this phone, along with your dabs.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Palette.cream.withValues(alpha: .75)),
            ),
          for (final t in _tickets.tickets)
            Column(
              key: ValueKey(t.code),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PaperTicket(
                  ticket: t,
                  heading: 'TAP TO DAB',
                  tilt: PaperTicket.tiltFor(t.code),
                  dabLook: (n) => _look(t, n),
                  onTap: (n) => _dab(t, n),
                ),
                const SizedBox(height: 8),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  children: [
                    _Action('Clear dabs', () {
                      _looks.remove(t);
                      _tickets.clearDabs(t);
                    }),
                    _Action('Copy link', () async {
                      await Clipboard.setData(ClipboardData(text: ticketLink(t.code)));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link copied')));
                      }
                    }),
                    _Action('Remove', () => _tickets.remove(t)),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action(this.label, this.onPressed);
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton(
    style: OutlinedButton.styleFrom(
      foregroundColor: Palette.cream,
      side: BorderSide(color: Palette.cream.withValues(alpha: .5)),
    ),
    onPressed: onPressed,
    child: Text(label),
  );
}
