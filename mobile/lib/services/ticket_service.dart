// Looking up tickets and making links to them.
//
// This is the seam for online play: today a ticket is rebuilt from its code on
// the phone. With a backend, findTicket() would ask the server first and fall
// back to the local rebuild when offline. It's async already for that reason.

import '../core/ticket_code.dart';
import '../core/tickets.dart';

const siteUrl = 'https://housey.webappslab.com/';

/// The ticket in a typed code, scanned QR text or ticket link, or null.
Future<Ticket?> findTicket(String input) async {
  final code = extractTicketCode(input);
  return code == null ? null : ticketFromCode(code);
}

/// A link that opens the ticket on any phone, e.g. https://…/ticket.html?t=HNZV-C92Z
String ticketLink(String code) => Uri.parse('${siteUrl}ticket.html').replace(queryParameters: {'t': code}).toString();
