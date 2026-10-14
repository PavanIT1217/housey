// Random numbers: a seeded generator for things that must be reproducible
// (tickets made from a code) and a secure one for things that must be fair
// (the order numbers come out of the bag).

/** Hashes a string to four 32-bit words (cyrb128). Used to seed generators. */
export function hashString(str) {
  let h1 = 1779033703, h2 = 3144134277, h3 = 1013904242, h4 = 2773480762;
  for (let i = 0; i < str.length; i++) {
    const k = str.charCodeAt(i);
    h1 = h2 ^ Math.imul(h1 ^ k, 597399067);
    h2 = h3 ^ Math.imul(h2 ^ k, 2869860233);
    h3 = h4 ^ Math.imul(h3 ^ k, 951274213);
    h4 = h1 ^ Math.imul(h4 ^ k, 2716044179);
  }
  h1 = Math.imul(h3 ^ (h1 >>> 18), 597399067);
  h2 = Math.imul(h4 ^ (h2 >>> 22), 2869860233);
  h3 = Math.imul(h1 ^ (h3 >>> 17), 951274213);
  h4 = Math.imul(h2 ^ (h4 >>> 19), 2716044179);
  h1 ^= h2 ^ h3 ^ h4; h2 ^= h1; h3 ^= h1; h4 ^= h1;
  return [h1 >>> 0, h2 >>> 0, h3 >>> 0, h4 >>> 0];
}

/**
 * A deterministic generator (sfc32) seeded from a string. The same seed gives
 * the same sequence in every browser, which is what lets a ticket code stand
 * in for the ticket itself. Never change this without versioning the seed.
 */
export function seededRandom(seed) {
  let [a, b, c, d] = hashString(seed);
  return () => {
    a |= 0; b |= 0; c |= 0; d |= 0;
    const t = (((a + b) | 0) + d) | 0;
    d = (d + 1) | 0;
    a = b ^ (b >>> 9);
    b = (c + (c << 3)) | 0;
    c = (c << 21) | (c >>> 11);
    c = (c + t) | 0;
    return (t >>> 0) / 4294967296;
  };
}

/** A float in [0, 1) from the platform's cryptographic generator. */
export function secureRandom() {
  const buf = new Uint32Array(1);
  globalThis.crypto.getRandomValues(buf);
  return buf[0] / 4294967296;
}

export const randomInt = (n, rnd = Math.random) => Math.floor(rnd() * n);
export const between = (lo, hi, rnd = Math.random) => lo + rnd() * (hi - lo);

/** Shuffles an array in place (Fisher–Yates) and returns it. */
export function shuffle(items, rnd = Math.random) {
  for (let i = items.length - 1; i > 0; i--) {
    const j = randomInt(i + 1, rnd);
    [items[i], items[j]] = [items[j], items[i]];
  }
  return items;
}
