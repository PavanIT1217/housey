import { DEFAULT_PRINT_OPTIONS, MAX_PRINT_TICKETS, PRINT_PRESETS, PRINT_THEMES, paginate, sanitizePrintOptions, ticketColor } from '../js/core/print-options.js';
import assert from 'node:assert/strict';
import { test } from 'node:test';

test('print options are filled in and kept in range', () => {
  assert.deepEqual(sanitizePrintOptions(), { ...DEFAULT_PRINT_OPTIONS });
  const o = sanitizePrintOptions({ count: 99999, layout: 'huge', theme: 'neon', customColor: 'red', startNumber: -3, title: 'x'.repeat(99) });
  assert.equal(o.count, MAX_PRINT_TICKETS);
  assert.equal(o.layout, DEFAULT_PRINT_OPTIONS.layout);
  assert.equal(o.theme, DEFAULT_PRINT_OPTIONS.theme);
  assert.equal(o.customColor, DEFAULT_PRINT_OPTIONS.customColor);
  assert.equal(o.startNumber, 1);
  assert.equal(o.title.length, 40);
  assert.equal(sanitizePrintOptions({ count: 'abc' }).count, DEFAULT_PRINT_OPTIONS.count);
});

test('every preset is a valid set of options', () => {
  for (const preset of PRINT_PRESETS) {
    const o = sanitizePrintOptions(preset.options);
    for (const [key, value] of Object.entries(preset.options)) assert.equal(o[key], value, `${preset.key}.${key}`);
  }
});

test('ticket colours follow the theme', () => {
  assert.equal(ticketColor(sanitizePrintOptions({ theme: 'blue' }), 5), PRINT_THEMES.find(t => t.key === 'blue').color);
  assert.equal(ticketColor(sanitizePrintOptions({ theme: 'custom', customColor: '#123456' }), 0), '#123456');
  const mix = sanitizePrintOptions({ theme: 'mix' });
  assert.notEqual(ticketColor(mix, 0), ticketColor(mix, 1));
});

test('tickets are split into pages', () => {
  assert.deepEqual(paginate([1, 2, 3, 4, 5, 6, 7], 3), [[1, 2, 3], [4, 5, 6], [7]]);
  assert.deepEqual(paginate([], 6), []);
});
