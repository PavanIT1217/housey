// The service worker caches a hand-written file list; make sure nothing the site needs is missing from it.
import { readFileSync, readdirSync } from 'node:fs';
import assert from 'node:assert/strict';
import { join } from 'node:path';
import { test } from 'node:test';

const root = new URL('..', import.meta.url).pathname;
const walk = dir => readdirSync(join(root, dir), { withFileTypes: true })
  .flatMap(e => (e.isDirectory() ? walk(join(dir, e.name)) : [join(dir, e.name)]));

test('every page, script and stylesheet is cached for offline play', () => {
  const sw = readFileSync(join(root, 'sw.js'), 'utf8');
  const listed = new Set([...sw.matchAll(/'([^']+\.[a-z0-9]+)'/g)].map(m => m[1]));
  const needed = [
    ...readdirSync(root).filter(f => f.endsWith('.html') && f !== '404.html'),
    ...walk('js'), ...walk('css'),
  ];
  const missing = needed.filter(f => !listed.has(f));
  assert.deepEqual(missing, [], `Add these to FILES in sw.js (and bump VERSION): ${missing.join(', ')}`);
});
