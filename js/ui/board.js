// The printed caller's board (1–90) with a red chip on each called number.

import { HIGHEST_NUMBER } from '../core/tickets.js';
import { el } from './dom.js';

export function renderBoard(container) {
  container.innerHTML = '';
  for (let n = 1; n <= HIGHEST_NUMBER; n++) {
    const cell = el('div', 'bcell');
    cell.dataset.n = n;
    cell.append(el('span', '', n));
    container.append(cell);
  }
}

const cellOf = (board, n) => board.querySelector(`.bcell[data-n="${n}"]`);

/** Puts a chip on `n`. `latest` makes it the glowing, most recent one. */
export function markCalled(board, n, { latest = true } = {}) {
  const cell = cellOf(board, n);
  if (!cell) return;
  if (latest) board.querySelectorAll('.bcell.latest').forEach(c => c.classList.remove('latest'));
  if (!cell.classList.contains('called')) cell.prepend(el('i', 'chip'));
  cell.classList.add('called');
  cell.classList.toggle('latest', latest);
}

export function unmarkCalled(board, n) {
  const cell = cellOf(board, n);
  cell?.classList.remove('called', 'latest');
  cell?.querySelector('.chip')?.remove();
}

/** Shows exactly the given called numbers, the last one marked latest. */
export function showCalled(board, called) {
  renderBoard(board);
  called.forEach((n, i) => markCalled(board, n, { latest: i === called.length - 1 }));
}
