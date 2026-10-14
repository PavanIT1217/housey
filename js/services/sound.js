// Sound effects, synthesised with Web Audio so there are no audio files.

import { KEYS, storage } from './storage.js';
import { between } from '../core/random.js';

let ctx = null;

function noise(dur) {
  const b = ctx.createBuffer(1, Math.ceil(ctx.sampleRate * dur), ctx.sampleRate);
  const d = b.getChannelData(0);
  for (let i = 0; i < d.length; i++) d[i] = Math.random() * 2 - 1;
  const s = ctx.createBufferSource();
  s.buffer = b;
  return s;
}

export const sound = {
  on: storage.get(KEYS.sound, true),

  /** Starts (or resumes) audio. Browsers only allow this after a tap or key press. */
  init() {
    if (!ctx) {
      try { ctx = new (globalThis.AudioContext || globalThis.webkitAudioContext)(); } catch { /* no audio */ }
    }
    if (ctx?.state === 'suspended') ctx.resume();
  },

  toggle() {
    this.on = !this.on;
    storage.set(KEYS.sound, this.on);
    this.init();
    return this.on;
  },

  get ready() { return this.on && Boolean(ctx); },

  /** Wooden coins knocking together. */
  clack(when = 0, pitch = 1) {
    if (!this.ready) return;
    const t = ctx.currentTime + when;
    const n = noise(0.06), f = ctx.createBiquadFilter(), g = ctx.createGain();
    f.type = 'bandpass'; f.frequency.value = 1500 * pitch; f.Q.value = 4;
    g.gain.setValueAtTime(0.5, t); g.gain.exponentialRampToValueAtTime(0.001, t + 0.06);
    n.connect(f).connect(g).connect(ctx.destination); n.start(t);
    const o = ctx.createOscillator(), og = ctx.createGain();
    o.frequency.value = 820 * pitch; og.gain.setValueAtTime(0.18, t); og.gain.exponentialRampToValueAtTime(0.001, t + 0.05);
    o.connect(og).connect(ctx.destination); o.start(t); o.stop(t + 0.06);
  },

  /** A hand rummaging in the bag. */
  rummage() { for (let i = 0; i < 6; i++) this.clack(i * 0.07 + Math.random() * 0.04, between(0.8, 1.25)); },

  /** The dauber's thump. */
  dab() {
    if (!this.ready) return;
    const t = ctx.currentTime;
    const o = ctx.createOscillator(), g = ctx.createGain();
    o.frequency.setValueAtTime(170, t); o.frequency.exponentialRampToValueAtTime(55, t + 0.09);
    g.gain.setValueAtTime(0.45, t); g.gain.exponentialRampToValueAtTime(0.001, t + 0.12);
    o.connect(g).connect(ctx.destination); o.start(t); o.stop(t + 0.13);
    const n = noise(0.05), f = ctx.createBiquadFilter(), ng = ctx.createGain();
    f.type = 'lowpass'; f.frequency.value = 900; ng.gain.setValueAtTime(0.25, t); ng.gain.exponentialRampToValueAtTime(0.001, t + 0.05);
    n.connect(f).connect(ng).connect(ctx.destination); n.start(t);
  },

  tones(notes, type = 'triangle', vol = 0.2) {
    if (!this.ready) return;
    const t0 = ctx.currentTime;
    notes.forEach(([freq, at, dur]) => {
      const o = ctx.createOscillator(), g = ctx.createGain(), t = t0 + at;
      o.type = type; o.frequency.value = freq;
      g.gain.setValueAtTime(0, t); g.gain.linearRampToValueAtTime(vol, t + 0.02); g.gain.exponentialRampToValueAtTime(0.001, t + dur);
      o.connect(g).connect(ctx.destination); o.start(t); o.stop(t + dur + 0.05);
    });
  },
  win() { this.tones([[523, 0, 0.3], [659, 0.12, 0.3], [784, 0.24, 0.3], [1047, 0.36, 0.7]]); },
  lose() { this.tones([[392, 0, 0.25], [330, 0.15, 0.4]], 'sine', 0.15); },
  bogey() { this.tones([[140, 0, 0.5], [110, 0.05, 0.55]], 'sawtooth', 0.12); },
};
