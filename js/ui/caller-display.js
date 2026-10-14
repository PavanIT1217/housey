// The caller's mat: the coin just drawn, the tray of recent coins and the call text.

import { HIGHEST_NUMBER } from '../core/tickets.js';
import { el } from './dom.js';

// 6 and 9 look alike upside down, so those coins are underlined.
const UNDERLINED = new Set([6, 9, 66, 69, 96]);

export const makeCoin = n => el('div', `coin${UNDERLINED.has(n) ? ' underline' : ''}`, n);

export class CallerDisplay {
  constructor({ slot, tray, text, count, trayLength = 6 }) {
    Object.assign(this, { slot, tray, text, count, trayLength });
  }

  setMessage(message) { this.text.textContent = message; }

  #setCount(called) { this.count.textContent = `${called} / ${HIGHEST_NUMBER} called`; }

  /** Empties the mat. */
  reset(message = '') {
    this.slot.innerHTML = '<div class="coin-placeholder">?</div>';
    this.tray.innerHTML = '';
    this.setMessage(message);
    this.#setCount(0);
  }

  /** Brings out a newly drawn coin, moving the previous one into the tray. */
  show(n, { message, called }) {
    const prev = this.slot.querySelector('.coin');
    if (prev) {
      this.tray.prepend(makeCoin(Number(prev.textContent)));
      while (this.tray.children.length > this.trayLength) this.tray.lastChild.remove();
    }
    const coin = makeCoin(n);
    coin.classList.add('emerge');
    this.slot.replaceChildren(coin);
    this.setMessage(message);
    this.#setCount(called);
  }

  /** Redraws the mat for numbers already called (after a reload or an undo), without animation. */
  restore(called, message = '') {
    this.reset(message);
    if (!called.length) return;
    this.slot.replaceChildren(makeCoin(called.at(-1)));
    called.slice(-1 - this.trayLength, -1).reverse().forEach(n => this.tray.append(makeCoin(n)));
    this.#setCount(called.length);
  }
}
