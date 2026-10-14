// Printable tickets: choose how many, the colours and the layout, then print
// or save as PDF. Each ticket carries its code and a QR code that opens it on
// a phone, so the number caller can check it.

import { $, el, registerServiceWorker, toast } from '../ui/dom.js';
import {
  CUSTOM_THEME, MIXED_THEME, PAGE_LAYOUTS, PRINT_PRESETS, PRINT_THEMES,
  paginate, sanitizePrintOptions, ticketColor,
} from '../core/print-options.js';
import { createTickets, ticketFromCode } from '../core/tickets.js';
import { KEYS, storage } from '../services/storage.js';
import { qrSvg } from '../ui/qr.js';
import { ticketLink } from '../services/ticket-service.js';

const A4_WIDTH_PX = 794; // 210mm at 96 dpi

const saved = storage.get(KEYS.printOptions, {});
let options = sanitizePrintOptions(saved.options);
let tickets = (saved.codes ?? []).map(ticketFromCode).filter(Boolean).slice(0, options.count);

const qrCache = new Map();
const qrFor = code => {
  if (!qrCache.has(code)) qrCache.set(code, qrSvg(ticketLink(code), { margin: 1 }));
  return qrCache.get(code);
};

const save = () => storage.set(KEYS.printOptions, { options, codes: tickets.map(t => t.code) });

/** Adds or drops tickets to match the chosen count, keeping the ones already made. */
function matchCount() {
  if (tickets.length > options.count) tickets = tickets.slice(0, options.count);
  else if (tickets.length < options.count) {
    const have = new Set(tickets.map(t => t.code));
    tickets.push(...createTickets(options.count - tickets.length).filter(t => !have.has(t.code)));
  }
}

// ---------- Sheets ----------
function printableTicket(ticket, index) {
  const color = ticketColor(options, index);
  const pt = el('div', 'pt');
  pt.style.setProperty('--c', color);

  const head = el('div', 'pt-head');
  head.append(el('span', 'pt-title', options.title || 'Housey'), el('span', 'pt-no', `Ticket ${options.startNumber + index}`));

  const grid = el('div', 'pt-grid');
  ticket.grid.flat().forEach(n => grid.append(el('div', n ? 'pt-cell' : 'pt-cell empty', n || '')));

  const body = el('div', 'pt-body');
  body.append(grid);
  if (options.showQr) {
    const qr = el('div', 'pt-qr');
    qr.innerHTML = qrFor(ticket.code);
    qr.append(el('span', 'pt-code', ticket.code));
    body.append(qr);
  }

  pt.append(head, body);
  if (options.footer) pt.append(el('div', 'pt-foot', options.footer));
  return pt;
}

function renderSheets() {
  const layout = PAGE_LAYOUTS.find(l => l.key === options.layout);
  const pages = paginate(tickets, layout.perPage);
  const preview = $('#preview');
  preview.innerHTML = '';
  pages.forEach((pageTickets, p) => {
    const page = el('section', `print-page layout-${layout.key}`);
    page.setAttribute('aria-label', `Page ${p + 1} of ${pages.length}`);
    pageTickets.forEach((t, i) => page.append(printableTicket(t, p * layout.perPage + i)));
    preview.append(page);
  });
  $('#printSummary').textContent =
    `${tickets.length} ticket${tickets.length === 1 ? '' : 's'} on ${pages.length} A4 page${pages.length === 1 ? '' : 's'}.`;
  fitPreview();
}

/** Scales the A4 preview down to fit narrow screens (printing is always full size). */
function fitPreview() {
  const preview = $('#preview');
  preview.style.zoom = Math.min(1, (preview.parentElement.clientWidth - 8) / A4_WIDTH_PX);
}

function update(patch, { regenerate = false } = {}) {
  options = sanitizePrintOptions({ ...options, ...patch });
  if (regenerate) tickets = [];
  matchCount();
  save();
  syncForm();
  renderSheets();
}

// ---------- Form ----------
function syncForm() {
  $('#countInput').value = options.count;
  $('#titleInput').value = options.title;
  $('#footerInput').value = options.footer;
  $('#startInput').value = options.startNumber;
  $('#qrInput').checked = options.showQr;
  $('#customColor').value = options.customColor;
  $('#swatches .custom').style.background = options.customColor;
  document.querySelectorAll('#layoutSeg button').forEach(b => b.classList.toggle('on', b.dataset.layout === options.layout));
  document.querySelectorAll('#swatches .swatch').forEach(b => b.classList.toggle('on', b.dataset.theme === options.theme));
}

function buildForm() {
  PRINT_PRESETS.forEach(preset => {
    const b = el('button', 'preset');
    b.type = 'button';
    b.append(el('b', '', preset.label), el('small', '', preset.hint));
    b.addEventListener('click', () => update(preset.options, { regenerate: true }));
    $('#presets').append(b);
  });

  PAGE_LAYOUTS.forEach(layout => {
    const b = el('button', '', layout.label);
    b.type = 'button';
    b.dataset.layout = layout.key;
    b.addEventListener('click', () => update({ layout: layout.key }));
    $('#layoutSeg').append(b);
  });

  const swatch = (theme, label, background) => {
    const b = el('button', 'swatch');
    b.type = 'button';
    b.dataset.theme = theme;
    b.title = label;
    b.setAttribute('aria-label', label);
    b.style.background = background;
    b.addEventListener('click', () => update({ theme }));
    $('#swatches').insertBefore(b, $('#swatches .custom'));
  };
  PRINT_THEMES.forEach(t => swatch(t.key, t.label, t.color));
  const colourful = PRINT_THEMES.filter(t => t.key !== 'ink').map(t => t.color);
  swatch(MIXED_THEME, 'Mixed colours', `conic-gradient(${colourful.join(', ')}, ${colourful[0]})`);

  $('#customColor').addEventListener('input', e => update({ theme: CUSTOM_THEME, customColor: e.target.value }));
  $('#countInput').addEventListener('change', e => update({ count: e.target.value }));
  $('#startInput').addEventListener('change', e => update({ startNumber: e.target.value }));
  $('#titleInput').addEventListener('input', e => update({ title: e.target.value }));
  $('#footerInput').addEventListener('input', e => update({ footer: e.target.value }));
  $('#qrInput').addEventListener('change', e => update({ showQr: e.target.checked }));

  $('#generateBtn').addEventListener('click', () => {
    update({}, { regenerate: true });
    toast('New tickets made');
  });
  $('#printBtn').addEventListener('click', () => window.print());
  $('#csvBtn').addEventListener('click', downloadCodes);
}

/** A spreadsheet of ticket numbers, codes and links, for the host's records. */
function downloadCodes() {
  const rows = [['Ticket', 'Code', 'Link'], ...tickets.map((t, i) => [options.startNumber + i, t.code, ticketLink(t.code)])];
  const blob = new Blob([rows.map(r => r.join(',')).join('\n')], { type: 'text/csv' });
  const a = el('a');
  a.href = URL.createObjectURL(blob);
  a.download = 'housey-tickets.csv';
  a.click();
  setTimeout(() => URL.revokeObjectURL(a.href), 1000);
}

buildForm();
matchCount();
save();
syncForm();
renderSheets();
window.addEventListener('resize', fitPreview);
registerServiceWorker();
