// Random numbers. The seeded generator must match js/core/random.js bit for
// bit: a ticket code becomes the same numbers in the app and on the website.
// test/core_test.dart checks this against tests/fixtures/ticket-codes.json.

import 'dart:math';

const _mask = 0xFFFFFFFF;

/// 32-bit multiply, like JavaScript's Math.imul (as an unsigned result).
int _imul(int a, int b) => (a * b) & _mask;

/// Hashes a string to four 32-bit words (cyrb128). Used to seed generators.
List<int> hashString(String str) {
  var h1 = 1779033703, h2 = 3144134277, h3 = 1013904242, h4 = 2773480762;
  for (final k in str.codeUnits) {
    h1 = h2 ^ _imul(h1 ^ k, 597399067);
    h2 = h3 ^ _imul(h2 ^ k, 2869860233);
    h3 = h4 ^ _imul(h3 ^ k, 951274213);
    h4 = h1 ^ _imul(h4 ^ k, 2716044179);
  }
  h1 = _imul(h3 ^ (h1 >> 18), 597399067);
  h2 = _imul(h4 ^ (h2 >> 22), 2869860233);
  h3 = _imul(h1 ^ (h3 >> 17), 951274213);
  h4 = _imul(h2 ^ (h4 >> 19), 2716044179);
  h1 ^= h2 ^ h3 ^ h4;
  h2 ^= h1;
  h3 ^= h1;
  h4 ^= h1;
  return [h1, h2, h3, h4];
}

/// A source of floats in [0, 1).
typedef RandomSource = double Function();

/// A deterministic generator (sfc32) seeded from a string. Never change it
/// without versioning the seed: printed tickets depend on it.
RandomSource seededRandom(String seed) {
  var [a, b, c, d] = hashString(seed);
  return () {
    final t = (a + b + d) & _mask;
    d = (d + 1) & _mask;
    a = b ^ (b >> 9);
    b = (c + (c << 3)) & _mask;
    c = ((c << 21) | (c >> 11)) & _mask;
    c = (c + t) & _mask;
    return t / 4294967296;
  };
}

/// Adapts a [Random] (e.g. Random.secure()) to a [RandomSource].
RandomSource fromRandom(Random random) => random.nextDouble;

int randomInt(int n, RandomSource rnd) => (rnd() * n).floor();

/// Shuffles [items] in place (Fisher–Yates, the same steps as the web version) and returns it.
List<T> shuffleWith<T>(List<T> items, RandomSource rnd) {
  for (var i = items.length - 1; i > 0; i--) {
    final j = randomInt(i + 1, rnd);
    final tmp = items[i];
    items[i] = items[j];
    items[j] = tmp;
  }
  return items;
}

/// A stable sort (equal items keep their order), like JavaScript's Array.sort.
List<T> stableSort<T>(List<T> items, int Function(T a, T b) compare) {
  for (var i = 1; i < items.length; i++) {
    final item = items[i];
    var j = i - 1;
    while (j >= 0 && compare(items[j], item) > 0) {
      items[j + 1] = items[j];
      j--;
    }
    items[j + 1] = item;
  }
  return items;
}
