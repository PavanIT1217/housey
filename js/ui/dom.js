// DOM helpers and small page-level bits (toasts, banners, screen wake lock).

export const $ = (selector, root = document) => root.querySelector(selector);
export const $$ = (selector, root = document) => [...root.querySelectorAll(selector)];

/** Creates an element with an optional class and text. */
export function el(tag, className, text) {
  const e = document.createElement(tag);
  if (className) e.className = className;
  if (text != null) e.textContent = text;
  return e;
}

function singleton(id, className, attrs) {
  let node = document.getElementById(id);
  if (!node) {
    node = el('div', className);
    node.id = id;
    Object.entries(attrs).forEach(([k, v]) => node.setAttribute(k, v));
    document.body.append(node);
  }
  return node;
}

let toastTimer;
/** A short message at the bottom of the screen. */
export function toast(message) {
  const t = singleton('toast', 'toast', { role: 'status' });
  t.textContent = message;
  t.classList.add('show');
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => t.classList.remove('show'), 2600);
}

/** A big rubber-stamp banner in the middle of the screen. */
export function announce(title, subtitle, bad = false) {
  const a = singleton('announce', 'announce', { 'aria-live': 'assertive' });
  a.innerHTML = '';
  const banner = el('div', `banner${bad ? ' bogey' : ''}`, title);
  if (subtitle) banner.append(el('small', '', subtitle));
  a.append(banner);
}

export const vibrate = pattern => navigator.vibrate?.(pattern);

/** Keeps the screen on while a game is running (where the browser allows it). */
export function createWakeLock() {
  let lock = null;
  let wanted = false;
  const request = async () => {
    wanted = true;
    try {
      if ('wakeLock' in navigator && !lock) {
        lock = await navigator.wakeLock.request('screen');
        lock.addEventListener('release', () => { lock = null; });
      }
    } catch { /* not allowed right now */ }
  };
  document.addEventListener('visibilitychange', () => {
    if (wanted && document.visibilityState === 'visible') request();
  });
  return {
    request,
    release() {
      wanted = false;
      try { lock?.release(); } catch { /* already released */ }
      lock = null;
    },
  };
}

/** Saves the site for offline use (not available when opened from disk). */
export function registerServiceWorker() {
  if ('serviceWorker' in navigator && location.protocol !== 'file:') {
    window.addEventListener('load', () => navigator.serviceWorker.register('sw.js').catch(() => {}));
  }
}
