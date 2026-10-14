// Controls for how the caller calls: speed between numbers, and the voice.
// Used on the game's setup card, the in-game settings and the number caller.

import { CALL_STYLES } from '../core/calls.js';
import { MANUAL_SPEED, PITCH, RATE, SPEED, updateVoiceSettings, voiceSettings } from '../services/settings.js';
import { randomInt } from '../core/random.js';
import { speaker } from '../services/speech.js';
import { el } from './dom.js';

const SPEED_PRESETS = [
  { label: 'Relaxed', ms: 8000 },
  { label: 'Normal', ms: 5500 },
  { label: 'Quick', ms: 3500 },
];

function field(label, ...children) {
  const f = el('div', 'field');
  f.append(el('span', '', label), ...children);
  return f;
}

function range({ min, max, step, value }) {
  const input = el('input');
  Object.assign(input, { type: 'range', min, max, step, value });
  return input;
}

function segmented(options, onPick) {
  const seg = el('div', 'seg');
  const buttons = options.map(({ label, value }) => {
    const b = el('button', '', label);
    b.type = 'button';
    b.addEventListener('click', () => onPick(value));
    seg.append(b);
    return { b, value };
  });
  seg.sync = current => buttons.forEach(({ b, value }) => b.classList.toggle('on', value === current));
  return seg;
}

function toggle(label, checked, onChange) {
  const wrap = el('label', 'toggle');
  const input = el('input');
  input.type = 'checkbox';
  input.checked = checked;
  input.addEventListener('change', () => onChange(input.checked));
  wrap.append(input, el('span', '', label));
  return wrap;
}

/**
 * Speed presets plus a slider for any time between calls.
 * Returns a handle with the current `value`.
 */
export function mountSpeedControl(container, { value, allowManual = true, onChange }) {
  let current = value;
  const presets = [...SPEED_PRESETS, ...(allowManual ? [{ label: "I'll tap", ms: MANUAL_SPEED }] : [])];
  const seg = segmented(presets.map(p => ({ label: p.label, value: p.ms })), ms => set(ms));

  const slider = range({ min: SPEED.min, max: SPEED.max, step: SPEED.step, value: current || SPEED.default });
  slider.setAttribute('aria-label', 'Seconds between numbers');
  const readout = el('output');
  const sliderRow = el('div', 'slider-row');
  sliderRow.append(el('small', '', 'Seconds between numbers'), slider, readout);
  slider.addEventListener('input', () => set(Number(slider.value)));

  function sync() {
    seg.sync(current);
    sliderRow.hidden = current === MANUAL_SPEED;
    if (current !== MANUAL_SPEED) slider.value = current;
    readout.textContent = `${(current / 1000).toFixed(1)} s`;
  }
  function set(ms) {
    current = ms;
    sync();
    onChange?.(ms);
  }

  container.replaceChildren(seg, sliderRow);
  sync();
  return { get value() { return current; } };
}

/** The caller's voice: on/off, which voice, call style, speaking speed, pitch, repeat, and a test button. */
export function mountVoiceSettings(container) {
  const save = patch => updateVoiceSettings(patch);
  const parts = [toggle("Caller's voice", voiceSettings.on, on => save({ on }))];

  if (!speaker.supported) {
    parts.push(el('p', 'note', "This browser can't speak, so numbers are shown on screen only."));
  } else {
    const select = el('select');
    select.setAttribute('aria-label', 'Voice');
    const fillVoices = () => {
      select.replaceChildren(new Option('Automatic (Indian or British English)', ''));
      speaker.voices().forEach(v => select.append(new Option(`${v.name} (${v.lang})`, v.voiceURI)));
      select.value = voiceSettings.voiceURI;
      if (select.value !== voiceSettings.voiceURI) select.value = '';
    };
    fillVoices();
    speaker.onVoicesChanged(fillVoices);
    select.addEventListener('change', () => save({ voiceURI: select.value }));
    parts.push(field('Voice', select));

    const example = el('small', 'note');
    const style = segmented(CALL_STYLES.map(s => ({ label: s.label, value: s.key })), key => {
      save({ style: key });
      syncStyle();
    });
    const syncStyle = () => {
      style.sync(voiceSettings.style);
      example.textContent = `Says ${CALL_STYLES.find(s => s.key === voiceSettings.style).example}`;
    };
    syncStyle();
    parts.push(field('What the caller says', style, example));

    const slider = (label, limits, key, format) => {
      const input = range({ ...limits, value: voiceSettings[key] });
      input.setAttribute('aria-label', label);
      const out = el('output', '', format(voiceSettings[key]));
      input.addEventListener('input', () => {
        save({ [key]: Number(input.value) });
        out.textContent = format(Number(input.value));
      });
      const row = el('div', 'slider-row');
      row.append(input, out);
      return field(label, row);
    };
    parts.push(
      slider('Speaking speed', RATE, 'rate', v => `${v.toFixed(2)}×`),
      slider('Voice pitch', PITCH, 'pitch', v => (v < 0.95 ? 'Deeper' : v > 1.05 ? 'Higher' : 'Normal')),
    );

    const test = el('button', 'small-btn', '▶ Test voice');
    test.type = 'button';
    test.addEventListener('click', () => speaker.callNumber(randomInt(90) + 1, { force: true }));
    const row = el('div', 'field toggles');
    row.append(toggle('Say each number twice', voiceSettings.repeat, repeat => save({ repeat })), test);
    parts.push(row);
  }

  const wrap = el('div', 'voice-settings');
  wrap.append(...parts);
  container.replaceChildren(wrap);
}
