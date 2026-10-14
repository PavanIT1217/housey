import { COLUMNS, NUMBERS_PER_ROW, ROWS, columnRange, createTickets, generateGrid, ticketFromCode, ticketNumbers } from '../js/core/tickets.js';
import { createTicketCode, extractTicketCode, normalizeTicketCode } from '../js/core/ticket-code.js';
import assert from 'node:assert/strict';
import { seededRandom } from '../js/core/random.js';
import { test } from 'node:test';

function assertValidGrid(grid) {
  assert.equal(grid.length, ROWS);
  grid.forEach(row => {
    assert.equal(row.length, COLUMNS);
    assert.equal(row.filter(Boolean).length, NUMBERS_PER_ROW);
  });
  for (let c = 0; c < COLUMNS; c++) {
    const column = grid.map(row => row[c]).filter(Boolean);
    const [lo, hi] = columnRange(c);
    assert.ok(column.length >= 1, `column ${c} is empty`);
    column.forEach(n => assert.ok(n >= lo && n <= hi, `${n} is outside column ${c}`));
    assert.deepEqual(column, [...column].sort((a, b) => a - b), `column ${c} isn't sorted`);
  }
  assert.equal(new Set(ticketNumbers(grid)).size, 15);
}

test('generated tickets follow the Tambola rules', () => {
  const rnd = seededRandom('rules');
  for (let i = 0; i < 2000; i++) assertValidGrid(generateGrid(rnd));
});

test('a code always gives the same ticket', () => {
  const code = createTicketCode();
  assert.deepEqual(ticketFromCode(code), ticketFromCode(code.toLowerCase()));
  assertValidGrid(ticketFromCode(code).grid);
});

// Printed tickets must keep their numbers forever. If this fails, the ticket
// generator or the random source changed: version the seed instead.
test('ticket codes are stable across releases', () => {
  assert.deepEqual(ticketFromCode('HNZV-C92Z').grid, [
    [0, 17, 22, 0, 0, 53, 64, 72, 0],
    [0, 18, 0, 35, 40, 58, 67, 0, 0],
    [4, 0, 0, 0, 43, 59, 69, 0, 85],
  ]);
});

test('codes are cleaned up and checked', () => {
  assert.equal(normalizeTicketCode(' hnzv c92z '), 'HNZV-C92Z');
  assert.equal(normalizeTicketCode('HNZVC92Z'), 'HNZV-C92Z');
  assert.equal(normalizeTicketCode(''), null);
  assert.equal(normalizeTicketCode('HNZV-C92'), null);
  assert.equal(normalizeTicketCode('HNZV-C92ZZ'), null);
  assert.equal(normalizeTicketCode('HNZV-C9#Z'), null);
  assert.equal(ticketFromCode('nonsense'), null);
});

test('look-alike letters are read as digits', () => {
  const code = createTicketCode(seededRandom('lookalike'));
  const withLookalikes = code.replace(/0/g, 'O').replace(/1/g, 'I');
  assert.equal(normalizeTicketCode(withLookalikes), code);
});

test('most single-character typos are rejected', () => {
  const alphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';
  const rnd = seededRandom('typos');
  let typos = 0, caught = 0;
  for (let i = 0; i < 200; i++) {
    const raw = createTicketCode(rnd).replace('-', '');
    for (let pos = 0; pos < raw.length; pos++) {
      for (const ch of alphabet) {
        if (ch === raw[pos]) continue;
        typos++;
        if (!normalizeTicketCode(raw.slice(0, pos) + ch + raw.slice(pos + 1))) caught++;
      }
    }
  }
  assert.ok(caught / typos > 0.95, `only ${((caught / typos) * 100).toFixed(1)}% of typos caught`);
});

test('codes are found in ticket links and scanned text', () => {
  assert.equal(extractTicketCode('https://housey.webappslab.com/ticket.html?t=hnzv-c92z'), 'HNZV-C92Z');
  assert.equal(extractTicketCode('https://example.com/ticket.html#t=HNZV-C92Z'), 'HNZV-C92Z');
  assert.equal(extractTicketCode('HNZV-C92Z'), 'HNZV-C92Z');
  assert.equal(extractTicketCode('https://example.com/'), null);
});

test('a batch of tickets has no repeated codes', () => {
  const tickets = createTickets(300);
  assert.equal(tickets.length, 300);
  assert.equal(new Set(tickets.map(t => t.code)).size, 300);
});
