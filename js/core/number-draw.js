// The bag of 90 numbers: draws, undo, and a plain-JSON form for saving.
// The game and the standalone number caller both draw through this.

import { HIGHEST_NUMBER } from './tickets.js';
import { secureRandom, shuffle } from './random.js';

export class NumberDraw {
  #remaining;
  #called;

  /** Use NumberDraw.shuffled() or NumberDraw.fromJSON() rather than this. */
  constructor(remaining, called = []) {
    this.#remaining = [...remaining];
    this.#called = [...called];
  }

  /** A full bag in a fair random order. */
  static shuffled(rnd = secureRandom) {
    return new NumberDraw(shuffle(Array.from({ length: HIGHEST_NUMBER }, (_, i) => i + 1), rnd));
  }

  /** Rebuilds a saved draw, or returns null if the data isn't a valid bag. */
  static fromJSON(data) {
    const { remaining, called } = data ?? {};
    if (!Array.isArray(remaining) || !Array.isArray(called)) return null;
    const all = [...remaining, ...called];
    const valid = all.length === HIGHEST_NUMBER
      && new Set(all).size === HIGHEST_NUMBER
      && all.every(n => Number.isInteger(n) && n >= 1 && n <= HIGHEST_NUMBER);
    return valid ? new NumberDraw(remaining, called) : null;
  }

  toJSON() { return { remaining: [...this.#remaining], called: [...this.#called] }; }

  /** Numbers called so far, oldest first. */
  get called() { return [...this.#called]; }
  get count() { return this.#called.length; }
  get last() { return this.#called.at(-1) ?? null; }
  get isFinished() { return this.#remaining.length === 0; }
  has(n) { return this.#called.includes(n); }

  /** Takes the next number out of the bag, or null when it's empty. */
  next() {
    const n = this.#remaining.pop();
    if (n === undefined) return null;
    this.#called.push(n);
    return n;
  }

  /** Puts the last number back on top of the bag (it comes out next). */
  undo() {
    const n = this.#called.pop();
    if (n === undefined) return null;
    this.#remaining.push(n);
    return n;
  }
}
