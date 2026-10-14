// Tambola tickets: 3 rows x 9 columns, 5 numbers per row, 15 in all.
// Column c holds numbers from its own range (1–9, 10–19, … 80–90), sorted
// top to bottom, and every column has at least one number.

import { createTicketCode, normalizeTicketCode } from './ticket-code.js';
import { randomInt, seededRandom, shuffle } from './random.js';

export const ROWS = 3;
export const COLUMNS = 9;
export const NUMBERS_PER_ROW = 5;
export const HIGHEST_NUMBER = 90;

// Part of every ticket's seed. Bump it only together with a code format change:
// codes already printed must keep producing the same numbers.
const GENERATOR_VERSION = 'v1';

export const columnRange = c => [c === 0 ? 1 : c * 10, c === COLUMNS - 1 ? HIGHEST_NUMBER : c * 10 + 9];

/** Builds a ticket grid (0 marks an empty cell) using the given random source. */
export function generateGrid(rnd = Math.random) {
  for (;;) {
    // How many numbers each column gets: 1 each, then 6 more spread around (max 3).
    const counts = Array(COLUMNS).fill(1);
    for (let extra = ROWS * NUMBERS_PER_ROW - COLUMNS; extra > 0;) {
      const c = randomInt(COLUMNS, rnd);
      if (counts[c] < ROWS) { counts[c]++; extra--; }
    }

    // Which rows those numbers sit in, keeping 5 per row. Fullest columns go first.
    const layout = Array.from({ length: ROWS }, () => Array(COLUMNS).fill(false));
    const rowCount = Array(ROWS).fill(0);
    const order = shuffle([...Array(COLUMNS).keys()], rnd).sort((a, b) => counts[b] - counts[a]);
    let ok = true;
    for (const c of order) {
      const rows = shuffle([...Array(ROWS).keys()].filter(r => rowCount[r] < NUMBERS_PER_ROW), rnd)
        .sort((a, b) => rowCount[a] - rowCount[b]);
      if (rows.length < counts[c]) { ok = false; break; }
      rows.slice(0, counts[c]).forEach(r => { layout[r][c] = true; rowCount[r]++; });
    }
    if (!ok || rowCount.some(n => n !== NUMBERS_PER_ROW)) continue;

    const grid = Array.from({ length: ROWS }, () => Array(COLUMNS).fill(0));
    for (let c = 0; c < COLUMNS; c++) {
      const [lo, hi] = columnRange(c);
      const pool = shuffle(Array.from({ length: hi - lo + 1 }, (_, i) => lo + i), rnd)
        .slice(0, counts[c])
        .sort((a, b) => a - b);
      for (let r = 0; r < ROWS; r++) if (layout[r][c]) grid[r][c] = pool.shift();
    }
    return grid;
  }
}

/** The ticket a code stands for, or null if the code isn't valid. */
export function ticketFromCode(input) {
  const code = normalizeTicketCode(input);
  if (!code) return null;
  return { code, grid: generateGrid(seededRandom(`housey-ticket-${GENERATOR_VERSION}:${code}`)) };
}

/** A brand-new ticket with a fresh code. */
export const createTicket = rnd => ticketFromCode(createTicketCode(rnd));

/** `count` tickets with no repeated codes. */
export function createTickets(count, rnd) {
  const tickets = new Map();
  while (tickets.size < count) {
    const t = createTicket(rnd);
    tickets.set(t.code, t);
  }
  return [...tickets.values()];
}

export const ticketNumbers = grid => grid.flat().filter(Boolean);
export const rowNumbers = (grid, r) => grid[r].filter(Boolean);
