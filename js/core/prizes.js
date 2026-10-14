// The prizes and how a ticket wins each one.

import { rowNumbers, ticketNumbers } from './tickets.js';

export const PRIZES = Object.freeze([
  { key: 'early5', label: 'Early Five', points: 50 },
  { key: 'top', label: 'Top Line', points: 100 },
  { key: 'middle', label: 'Middle Line', points: 100 },
  { key: 'bottom', label: 'Bottom Line', points: 100 },
  { key: 'full', label: 'Full House', points: 250 },
]);

export const prizeByKey = key => PRIZES.find(p => p.key === key);

/** Whether `grid` wins `prizeKey` when `has(n)` says which numbers count (called, dabbed…). */
export function meetsPrize(prizeKey, grid, has) {
  switch (prizeKey) {
    case 'early5': return ticketNumbers(grid).filter(has).length >= 5;
    case 'top': return rowNumbers(grid, 0).every(has);
    case 'middle': return rowNumbers(grid, 1).every(has);
    case 'bottom': return rowNumbers(grid, 2).every(has);
    case 'full': return ticketNumbers(grid).every(has);
    default: return false;
  }
}

/** Every prize the grid has completed. */
export const prizesMet = (grid, has) => PRIZES.filter(p => meetsPrize(p.key, grid, has));
