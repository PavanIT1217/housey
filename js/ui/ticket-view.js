// A paper ticket on screen, and the ink dabs on it.

import { between, randomInt } from '../core/random.js';
import { el } from './dom.js';

// Ink filters give each dab a rough, hand-stamped edge.
const INK_FILTERS = `<svg width="0" height="0" style="position:absolute" aria-hidden="true">${
  [[0.08, 1, 7], [0.09, 7, 8], [0.07, 13, 6], [0.1, 29, 9]].map(([freq, seed, scale], i) =>
    `<filter id="ink${i}"><feTurbulence type="fractalNoise" baseFrequency="${freq}" numOctaves="2" seed="${seed}"/><feDisplacementMap in="SourceGraphic" scale="${scale}"/></filter>`,
  ).join('')
}</svg>`;

/** Adds the SVG ink filters to the page once. */
export function ensureInkFilters() {
  if (!document.getElementById('ink0')) document.body.insertAdjacentHTML('afterbegin', INK_FILTERS);
}

/** Stamps an ink dab on a ticket cell. `fresh` plays the stamping animation. */
export function addDab(cell, fresh = false) {
  if (!cell || cell.querySelector('.dab')) return;
  const d = el('span', `dab${fresh ? ' fresh' : ''}`);
  d.style.setProperty('--r', `${randomInt(360)}deg`);
  d.style.setProperty('--dx', `${between(-4, 4).toFixed(1)}%`);
  d.style.setProperty('--dy', `${between(-4, 4).toFixed(1)}%`);
  d.style.setProperty('--s', between(0.92, 1.06).toFixed(2));
  d.style.filter = `url(#ink${randomInt(4)})`;
  cell.append(d);
}

export function removeDab(cell) {
  cell?.querySelector('.dab')?.remove();
  cell?.classList.remove('wrong');
}

/**
 * Renders a ticket. With `onCellClick(n, cell)` the numbers are buttons that
 * can be dabbed; without it the ticket is read-only.
 */
export function renderTicket(ticket, { heading = '', onCellClick, tilt = true } = {}) {
  ensureInkFilters();
  const tk = el('div', 'ticket');
  if (tilt) tk.style.setProperty('--rot', `${between(-1.2, 1.2).toFixed(2)}deg`);
  tk.dataset.code = ticket.code;

  const head = el('div', 'ticket-head');
  head.append(el('span', 'brand', 'Housey'), el('span', '', heading), el('span', 'serial', `Nº ${ticket.code}`));

  const grid = el('div', 'grid');
  ticket.grid.forEach(row => row.forEach(n => {
    if (!n) { grid.append(el('div', 'cell empty')); return; }
    const cell = el(onCellClick ? 'button' : 'div', 'cell num-cell');
    cell.dataset.n = n;
    cell.setAttribute('aria-label', `Number ${n}`);
    cell.append(el('span', 'num', n));
    if (onCellClick) cell.addEventListener('click', () => onCellClick(n, cell));
    grid.append(cell);
  }));

  tk.append(head, grid);
  return tk;
}

export const cellFor = (ticketEl, n) => ticketEl.querySelector(`.cell[data-n="${n}"]`);
