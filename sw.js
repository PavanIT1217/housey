// Bump VERSION when the file list changes; edits to cached files update on their own.
const VERSION = 'housey-v4';
const FILES = [
  './', 'index.html', 'caller.html', 'print.html', 'ticket.html', 'manifest.webmanifest',
  'css/style.css', 'css/tools.css', 'css/print.css', 'css/legal.css',
  'js/core/calls.js', 'js/core/number-draw.js', 'js/core/print-options.js', 'js/core/prizes.js',
  'js/core/random.js', 'js/core/ticket-code.js', 'js/core/tickets.js',
  'js/services/settings.js', 'js/services/sound.js', 'js/services/speech.js', 'js/services/storage.js',
  'js/services/ticket-service.js',
  'js/ui/board.js', 'js/ui/caller-display.js', 'js/ui/caller-settings.js', 'js/ui/dom.js', 'js/ui/qr.js',
  'js/ui/ticket-lookup.js', 'js/ui/ticket-view.js',
  'js/pages/caller.js', 'js/pages/game.js', 'js/pages/print.js', 'js/pages/ticket.js',
  'js/vendor/qrcode.js', 'js/vendor/jsQR.js',
  'icons/icon.svg', 'icons/icon-192.png', 'icons/icon-512.png', 'icons/apple-touch-icon.png',
  'privacy.html', 'terms.html', 'support.html', 'how-to-play.html', 'tambola-calls.html',
  'fonts/alfa-slab-one.woff2', 'fonts/caveat-700.woff2', 'fonts/courier-prime-700.woff2', 'fonts/roboto-slab.woff2',
];

self.addEventListener('install', e => {
  e.waitUntil(caches.open(VERSION).then(c => c.addAll(FILES)).then(() => self.skipWaiting()));
});

self.addEventListener('activate', e => {
  e.waitUntil(caches.keys()
    .then(keys => Promise.all(keys.filter(k => k !== VERSION).map(k => caches.delete(k))))
    .then(() => self.clients.claim()));
});

// Serve from the cache so the game opens instantly and works offline, then
// refresh the cached copy in the background so updates arrive on the next visit.
self.addEventListener('fetch', e => {
  const req = e.request;
  if (req.method !== 'GET' || new URL(req.url).origin !== location.origin) return;
  e.respondWith(caches.open(VERSION).then(async cache => {
    const hit = await cache.match(req, { ignoreSearch: true });
    const fresh = fetch(req).then(res => {
      if (res.ok) cache.put(req, res.clone());
      return res;
    }).catch(() => null);
    if (hit) { e.waitUntil(fresh); return hit; }
    return (await fresh) || (req.mode === 'navigate' && await cache.match('index.html')) || Response.error();
  }));
});
