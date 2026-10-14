// Options for printed ticket sheets: colours, page layouts and ready-made presets.

export const MAX_PRINT_TICKETS = 600;

export const PRINT_THEMES = Object.freeze([
  { key: 'classic', label: 'Classic red', color: '#b3261e' },
  { key: 'blue', label: 'Royal blue', color: '#1f4e9c' },
  { key: 'green', label: 'Festive green', color: '#1e7a46' },
  { key: 'purple', label: 'Purple', color: '#6a2c91' },
  { key: 'marigold', label: 'Marigold', color: '#c8641a' },
  { key: 'pink', label: 'Pink', color: '#c2185b' },
  { key: 'ink', label: 'Ink saver (black)', color: '#222222' },
]);
/** Theme keys that aren't a single colour. */
export const MIXED_THEME = 'mix';
export const CUSTOM_THEME = 'custom';

/** Tickets per A4 page and how they're arranged. */
export const PAGE_LAYOUTS = Object.freeze([
  { key: 'large', label: '4 large', perPage: 4, columns: 1 },
  { key: 'standard', label: '6', perPage: 6, columns: 1 },
  { key: 'compact', label: '12 small', perPage: 12, columns: 2 },
]);

export const DEFAULT_PRINT_OPTIONS = Object.freeze({
  count: 6, layout: 'standard', theme: 'classic', customColor: '#0b6e75',
  title: 'Housey', footer: '', startNumber: 1, showQr: true,
});

export const PRINT_PRESETS = Object.freeze([
  { key: 'family', label: 'Family night', hint: '6 tickets', options: { count: 6, layout: 'large', theme: 'classic', title: 'Family Housey Night' } },
  { key: 'kitty', label: 'Kitty party', hint: '24, mixed colours', options: { count: 24, layout: 'standard', theme: MIXED_THEME, title: 'Kitty Party Tambola' } },
  { key: 'festival', label: 'Diwali / festival', hint: '60, marigold', options: { count: 60, layout: 'compact', theme: 'marigold', title: 'Diwali Tambola' } },
  { key: 'office', label: 'Office event', hint: '100, mixed colours', options: { count: 100, layout: 'compact', theme: MIXED_THEME, title: 'Office Tambola' } },
  { key: 'inksaver', label: 'Ink saver', hint: '36, black only', options: { count: 36, layout: 'compact', theme: 'ink', title: 'Housey' } },
]);

const clampInt = (v, lo, hi, fallback) => {
  const n = Math.round(Number(v));
  return Number.isFinite(n) ? Math.min(hi, Math.max(lo, n)) : fallback;
};
const isHexColor = v => /^#[0-9a-f]{6}$/i.test(String(v));

/** Fills in and range-checks print options (from storage, a preset or the form). */
export function sanitizePrintOptions(input = {}) {
  const o = { ...DEFAULT_PRINT_OPTIONS, ...input };
  const themes = [...PRINT_THEMES.map(t => t.key), MIXED_THEME, CUSTOM_THEME];
  return {
    count: clampInt(o.count, 1, MAX_PRINT_TICKETS, DEFAULT_PRINT_OPTIONS.count),
    layout: PAGE_LAYOUTS.some(l => l.key === o.layout) ? o.layout : DEFAULT_PRINT_OPTIONS.layout,
    theme: themes.includes(o.theme) ? o.theme : DEFAULT_PRINT_OPTIONS.theme,
    customColor: isHexColor(o.customColor) ? o.customColor : DEFAULT_PRINT_OPTIONS.customColor,
    title: String(o.title ?? '').slice(0, 40),
    footer: String(o.footer ?? '').slice(0, 60),
    startNumber: clampInt(o.startNumber, 1, 99999, 1),
    showQr: Boolean(o.showQr),
  };
}

/** The ink colour for the ticket at `index` (0-based). */
export function ticketColor(options, index) {
  if (options.theme === CUSTOM_THEME) return options.customColor;
  if (options.theme === MIXED_THEME) {
    const colourful = PRINT_THEMES.filter(t => t.key !== 'ink');
    return colourful[index % colourful.length].color;
  }
  return (PRINT_THEMES.find(t => t.key === options.theme) ?? PRINT_THEMES[0]).color;
}

/** Splits items into pages of `perPage`. */
export function paginate(items, perPage) {
  const pages = [];
  for (let i = 0; i < items.length; i += perPage) pages.push(items.slice(i, i + perPage));
  return pages;
}
