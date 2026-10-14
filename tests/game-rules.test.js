import { CALL_STYLES, DEFAULT_CALL_STYLE, TRADITIONAL_CALLS, describeCall } from '../js/core/calls.js';
import { meetsPrize, prizesMet } from '../js/core/prizes.js';
import { NumberDraw } from '../js/core/number-draw.js';
import assert from 'node:assert/strict';
import { seededRandom } from '../js/core/random.js';
import { test } from 'node:test';

const grid = [
  [0, 17, 22, 0, 0, 53, 64, 72, 0],
  [0, 18, 0, 35, 40, 58, 67, 0, 0],
  [4, 0, 0, 0, 43, 59, 69, 0, 85],
];
const hasOnly = nums => n => nums.includes(n);

test('prizes are checked against the numbers that count', () => {
  assert.ok(meetsPrize('top', grid, hasOnly([17, 22, 53, 64, 72])));
  assert.ok(!meetsPrize('top', grid, hasOnly([17, 22, 53, 64])));
  assert.ok(meetsPrize('early5', grid, hasOnly([4, 18, 22, 59, 85])));
  assert.ok(!meetsPrize('early5', grid, hasOnly([4, 18, 22, 59, 1])));
  assert.ok(meetsPrize('full', grid, () => true));
  assert.ok(!meetsPrize('nonsense', grid, () => true));
  assert.deepEqual(prizesMet(grid, hasOnly([18, 35, 40, 58, 67])).map(p => p.key), ['early5', 'middle']);
});

test('the default call is just the number, with no traditional phrase', () => {
  assert.equal(DEFAULT_CALL_STYLE, 'number');
  const { display, speech } = describeCall(22);
  assert.equal(display, 'Number 22');
  assert.ok(!speech.includes(TRADITIONAL_CALLS[22]));
});

test('every call style has words for every number', () => {
  for (const { key } of CALL_STYLES) {
    for (let n = 1; n <= 90; n++) {
      const { display, speech } = describeCall(n, key);
      assert.ok(display && speech, `${key} ${n}`);
      assert.ok(speech.includes(String(n)), `${key} ${n} doesn't say the number`);
    }
  }
  assert.equal(describeCall(22, 'traditional').speech, 'Two little ducks. two and two, 22.');
  assert.equal(describeCall(7, 'digits').display, 'Single number 7');
});

test('the bag gives each number once', () => {
  const draw = NumberDraw.shuffled(seededRandom('bag'));
  const seen = [];
  for (let n = draw.next(); n !== null; n = draw.next()) seen.push(n);
  assert.equal(seen.length, 90);
  assert.equal(new Set(seen).size, 90);
  assert.ok(draw.isFinished);
  assert.equal(draw.next(), null);
});

test('undo puts the last number back on top', () => {
  const draw = NumberDraw.shuffled(seededRandom('undo'));
  const a = draw.next();
  const b = draw.next();
  assert.equal(draw.undo(), b);
  assert.deepEqual(draw.called, [a]);
  assert.equal(draw.next(), b);
  assert.equal(new NumberDraw([]).undo(), null);
});

test('a draw survives saving and loading', () => {
  const draw = NumberDraw.shuffled(seededRandom('save'));
  for (let i = 0; i < 17; i++) draw.next();
  const restored = NumberDraw.fromJSON(JSON.parse(JSON.stringify(draw)));
  assert.deepEqual(restored.called, draw.called);
  assert.equal(restored.next(), draw.next());
});

test('damaged saved draws are rejected', () => {
  const good = NumberDraw.shuffled().toJSON();
  assert.equal(NumberDraw.fromJSON(null), null);
  assert.equal(NumberDraw.fromJSON({ remaining: good.remaining.slice(1), called: [] }), null);
  assert.equal(NumberDraw.fromJSON({ remaining: [...good.remaining.slice(1), 5], called: [] }), null);
  assert.equal(NumberDraw.fromJSON({ remaining: 'x', called: [] }), null);
});
