// Player preferences, with defaults and range checks, saved between visits.

import { CALL_STYLES, DEFAULT_CALL_STYLE } from '../core/calls.js';
import { KEYS, storage } from './storage.js';

/** Seconds between calls when the caller runs on its own. */
export const SPEED = Object.freeze({ min: 2000, max: 20000, step: 500, default: 5500 });
/** Speed value meaning "I'll tap to draw each number". */
export const MANUAL_SPEED = 0;

const clamp = (n, lo, hi) => Math.min(hi, Math.max(lo, n));
const asNumber = (v, fallback) => (Number.isFinite(Number(v)) ? Number(v) : fallback);

export function sanitizeSpeed(value, { allowManual = true } = {}) {
  const ms = asNumber(value, SPEED.default);
  if (ms === MANUAL_SPEED && allowManual) return MANUAL_SPEED;
  return clamp(ms, SPEED.min, SPEED.max);
}

// ---------- Game table ----------
const GAME_DEFAULTS = { name: '', tickets: 1, bots: 4, speed: SPEED.default, auto: false };

export function loadGameSettings() {
  const s = { ...GAME_DEFAULTS, ...storage.get(KEYS.gameSettings, {}) };
  return {
    name: String(s.name ?? '').slice(0, 14),
    tickets: clamp(Math.round(asNumber(s.tickets, 1)), 1, 3),
    bots: clamp(Math.round(asNumber(s.bots, 4)), 0, 6),
    speed: sanitizeSpeed(s.speed),
    auto: Boolean(s.auto),
  };
}
export const saveGameSettings = settings => storage.set(KEYS.gameSettings, settings);

// ---------- Standalone number caller ----------
const CALLER_DEFAULTS = { speed: 6000, auto: true };

export function loadCallerSettings() {
  const s = { ...CALLER_DEFAULTS, ...storage.get(KEYS.callerSettings, {}) };
  return { speed: sanitizeSpeed(s.speed, { allowManual: false }), auto: Boolean(s.auto) };
}
export const saveCallerSettings = settings => storage.set(KEYS.callerSettings, settings);

// ---------- Caller's voice (shared by the game and the number caller) ----------
export const RATE = Object.freeze({ min: 0.6, max: 1.5, step: 0.05 });
export const PITCH = Object.freeze({ min: 0.5, max: 1.5, step: 0.05 });

function loadVoiceSettings() {
  const saved = storage.get(KEYS.voice, null);
  // Before voice settings existed the on/off switch lived with the game settings.
  const legacyOn = storage.get(KEYS.gameSettings, {})?.voice;
  const s = { on: legacyOn ?? true, voiceURI: '', rate: 1, pitch: 1, style: DEFAULT_CALL_STYLE, repeat: false, ...saved };
  return {
    on: Boolean(s.on),
    voiceURI: String(s.voiceURI ?? ''),
    rate: clamp(asNumber(s.rate, 1), RATE.min, RATE.max),
    pitch: clamp(asNumber(s.pitch, 1), PITCH.min, PITCH.max),
    style: CALL_STYLES.some(c => c.key === s.style) ? s.style : DEFAULT_CALL_STYLE,
    repeat: Boolean(s.repeat),
  };
}

/** Live voice settings. Change them with updateVoiceSettings() so they're saved. */
export const voiceSettings = loadVoiceSettings();

export function updateVoiceSettings(patch) {
  Object.assign(voiceSettings, patch);
  storage.set(KEYS.voice, voiceSettings);
}
