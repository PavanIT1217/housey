// Ticket codes: short, typeable IDs like "HNZV-C92Z" printed on every ticket.
//
// Today a code is a seed: the ticket's numbers are generated from it, so any
// device can rebuild a ticket from its code with no server. When tickets move
// to a backend, the server can issue codes in this same format and store the
// numbers, and nothing that reads or prints codes has to change.
//
// Format: 7 data symbols + 1 check symbol in Crockford base32 (no I, L, O, U,
// so codes are easy to read aloud). The check symbol catches typos, so a
// mistyped code is rejected instead of silently opening someone else's ticket.

import { hashString, randomInt, secureRandom } from './random.js';

const ALPHABET = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';
const DATA_LENGTH = 7;
export const CODE_LENGTH = DATA_LENGTH + 1;

const checkSymbol = data => ALPHABET[hashString(`check:${data}`)[0] % ALPHABET.length];
const format = raw => `${raw.slice(0, 4)}-${raw.slice(4)}`;

/** Makes a new random ticket code, e.g. "HNZV-C92Z". */
export function createTicketCode(rnd = secureRandom) {
  let data = '';
  for (let i = 0; i < DATA_LENGTH; i++) data += ALPHABET[randomInt(ALPHABET.length, rnd)];
  return format(data + checkSymbol(data));
}

/**
 * Cleans up a typed code and checks it. Accepts any case, spaces and dashes,
 * and the look-alikes O (for 0) and I/L (for 1). Returns the code in its
 * printed form, or null if it isn't a valid code.
 */
export function normalizeTicketCode(input) {
  const raw = String(input ?? '')
    .toUpperCase()
    .replace(/[\s-]/g, '')
    .replace(/O/g, '0')
    .replace(/[IL]/g, '1');
  if (raw.length !== CODE_LENGTH || [...raw].some(ch => !ALPHABET.includes(ch))) return null;
  const data = raw.slice(0, DATA_LENGTH);
  return raw[DATA_LENGTH] === checkSymbol(data) ? format(raw) : null;
}

/** Finds a ticket code in scanned or pasted text: a ticket link or a bare code. */
export function extractTicketCode(text) {
  const value = String(text ?? '').trim();
  try {
    const url = new URL(value);
    const fromLink = url.searchParams.get('t') ?? new URLSearchParams(url.hash.slice(1)).get('t');
    if (fromLink) return normalizeTicketCode(fromLink);
  } catch {
    // Not a link: treat it as a typed code.
  }
  return normalizeTicketCode(value);
}
