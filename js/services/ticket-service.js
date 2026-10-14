// Looking up tickets and making links to them.
//
// This is the seam for the online version: today a ticket is rebuilt from its
// code on the device. With a backend, findTicket() would ask the server first
// (and fall back to the local rebuild when offline). It is async already so
// callers won't need to change.

import { extractTicketCode } from '../core/ticket-code.js';
import { ticketFromCode } from '../core/tickets.js';

/** Where printed QR codes point when the page isn't served over HTTPS (e.g. opened from disk). */
export const SITE_URL = 'https://housey.webappslab.com/';

/** The ticket in a typed code, scanned QR text or ticket link, or null. */
export async function findTicket(input) {
  const code = extractTicketCode(input);
  return code ? ticketFromCode(code) : null;
}

/** A link that opens the ticket on any phone, e.g. https://…/ticket.html?t=HNZV-C92Z */
export function ticketLink(code) {
  const base = globalThis.location?.protocol === 'https:' ? globalThis.location.href : SITE_URL;
  const url = new URL('ticket.html', base);
  url.searchParams.set('t', code);
  return url.href;
}
