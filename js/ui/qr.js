// QR codes: drawing them on tickets and scanning them with the camera.

import qrcode from '../vendor/qrcode.js';
import { el } from './dom.js';

/** An SVG QR code (as markup) for `text`, black on white with a quiet zone. */
export function qrSvg(text, { margin = 2 } = {}) {
  const qr = qrcode(0, 'M');
  qr.addData(text);
  qr.make();
  const n = qr.getModuleCount();
  let path = '';
  for (let r = 0; r < n; r++) {
    for (let c = 0; c < n; c++) if (qr.isDark(r, c)) path += `M${c + margin} ${r + margin}h1v1h-1z`;
  }
  const size = n + margin * 2;
  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${size} ${size}" shape-rendering="crispEdges" role="img" aria-label="QR code"><rect width="${size}" height="${size}" fill="#fff"/><path d="${path}" fill="#000"/></svg>`;
}

/** Uses the browser's own QR reader when it has one, else the bundled jsQR. */
async function createDecoder() {
  if ('BarcodeDetector' in window) {
    try {
      const formats = await window.BarcodeDetector.getSupportedFormats();
      if (formats.includes('qr_code')) {
        const detector = new window.BarcodeDetector({ formats: ['qr_code'] });
        return async video => (await detector.detect(video))[0]?.rawValue ?? null;
      }
    } catch { /* fall back to jsQR */ }
  }
  await import('../vendor/jsQR.js'); // UMD build: sets window.jsQR
  const canvas = document.createElement('canvas');
  const ctx = canvas.getContext('2d', { willReadFrequently: true });
  return async video => {
    if (!video.videoWidth) return null;
    canvas.width = video.videoWidth;
    canvas.height = video.videoHeight;
    ctx.drawImage(video, 0, 0);
    const img = ctx.getImageData(0, 0, canvas.width, canvas.height);
    return window.jsQR(img.data, img.width, img.height, { inversionAttempts: 'dontInvert' })?.data ?? null;
  };
}

/**
 * Opens the camera and resolves with the text of the first QR code it sees,
 * or null if the player cancels. Rejects if there's no camera to use.
 */
export async function scanQrCode() {
  if (!navigator.mediaDevices?.getUserMedia) throw new Error('No camera access in this browser');
  const stream = await navigator.mediaDevices.getUserMedia({ video: { facingMode: 'environment' }, audio: false });

  const overlay = el('div', 'scanner');
  overlay.setAttribute('role', 'dialog');
  overlay.setAttribute('aria-label', 'Scan a ticket QR code');
  const video = el('video');
  Object.assign(video, { muted: true, playsInline: true, srcObject: stream });
  const frame = el('div', 'scanner-view');
  frame.append(video, el('div', 'scanner-frame'));
  const cancel = el('button', 'big-btn', 'Cancel');
  overlay.append(frame, el('p', '', 'Point the camera at the QR code on a ticket'), cancel);
  document.body.append(overlay);

  return new Promise(resolve => {
    let done = false;
    const finish = result => {
      if (done) return;
      done = true;
      stream.getTracks().forEach(t => t.stop());
      overlay.remove();
      document.removeEventListener('keydown', onKey);
      resolve(result);
    };
    const onKey = e => { if (e.key === 'Escape') finish(null); };
    cancel.addEventListener('click', () => finish(null));
    document.addEventListener('keydown', onKey);

    video.play().catch(() => {});
    createDecoder().then(decode => {
      const tick = async () => {
        if (done) return;
        try {
          const text = await decode(video);
          if (text) { finish(text); return; }
        } catch { /* frame not ready */ }
        setTimeout(tick, 200);
      };
      tick();
    }).catch(() => finish(null));
  });
}
