import 'package:flutter/material.dart';

import '../app_services.dart';
import 'caller_screen.dart';
import 'look.dart';
import 'my_tickets_screen.dart';
import 'print_screen.dart';

/// The tools beyond the game, for playing with paper tickets.
enum Tool {
  caller('Number caller', 'Call numbers for a game on paper tickets', Icons.campaign_rounded),
  myTickets('My tickets', 'Open a ticket by QR code or code and dab it', Icons.confirmation_number_rounded),
  print('Print tickets', 'Make tickets as a PDF to print or share', Icons.print_rounded);

  const Tool(this.label, this.description, this.icon);
  final String label;
  final String description;
  final IconData icon;

  Widget screen(AppServices services) => switch (this) {
    Tool.caller => CallerScreen(services: services),
    Tool.myTickets => MyTicketsScreen(services: services),
    Tool.print => PrintScreen(services: services),
  };
}

Future<void> openTool(BuildContext context, AppServices services, Tool tool) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => tool.screen(services)));

/// A sheet listing the tools.
Future<void> showToolsMenu(BuildContext context, AppServices services) => showModalBottomSheet<void>(
  context: context,
  backgroundColor: Palette.paper,
  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
  builder: (sheet) => SafeArea(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        for (final tool in Tool.values)
          ListTile(
            leading: Icon(tool.icon, color: Palette.ticketRed),
            title: Text(
              tool.label,
              style: const TextStyle(fontWeight: FontWeight.w800, color: Palette.ink),
            ),
            subtitle: Text(tool.description, style: TextStyle(color: Palette.ink.withValues(alpha: .7))),
            onTap: () {
              Navigator.pop(sheet);
              openTool(context, services, tool);
            },
          ),
        const SizedBox(height: 8),
      ],
    ),
  ),
);
