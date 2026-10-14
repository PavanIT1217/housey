// The caller's voice, using the browser's built-in text-to-speech.

import { describeCall } from '../core/calls.js';
import { voiceSettings } from './settings.js';

const synth = globalThis.speechSynthesis ?? null;
const ENGLISH_PREFERENCE = [/^en-IN/i, /^en-GB/i, /^en/i];

const allVoices = () => (synth ? synth.getVoices() : []);

/** The default voice: Indian English, then British, then any English. */
function autoVoice(voices) {
  for (const pattern of ENGLISH_PREFERENCE) {
    const found = voices.find(v => pattern.test(v.lang));
    if (found) return found;
  }
  return null;
}

export const speaker = {
  supported: Boolean(synth),

  /** Set by the page when it has its own mute switch. */
  isMuted: () => false,

  /** Voices to offer, English first, then by language and name. */
  voices() {
    const rank = v => { const i = ENGLISH_PREFERENCE.findIndex(p => p.test(v.lang)); return i < 0 ? 9 : i; };
    return [...allVoices()].sort((a, b) => rank(a) - rank(b) || a.lang.localeCompare(b.lang) || a.name.localeCompare(b.name));
  },

  /** Calls `fn` when the browser's voice list loads or changes (it loads late in Chrome). */
  onVoicesChanged(fn) {
    if (!synth) return;
    if (synth.addEventListener) synth.addEventListener('voiceschanged', fn);
    else synth.onvoiceschanged = fn;
  },

  /** Speaks `text`, cutting off anything still being said. `force` ignores the voice switch (for "Test"). */
  say(text, { force = false } = {}) {
    if (!synth || this.isMuted() || (!voiceSettings.on && !force)) return;
    synth.cancel();
    const u = new SpeechSynthesisUtterance(text);
    const voices = allVoices();
    const voice = voices.find(v => v.voiceURI === voiceSettings.voiceURI) ?? autoVoice(voices);
    if (voice) { u.voice = voice; u.lang = voice.lang; }
    u.rate = voiceSettings.rate;
    u.pitch = voiceSettings.pitch;
    synth.speak(u);
  },

  /** Calls out a drawn number in the chosen style. */
  callNumber(n, options) {
    const { speech } = describeCall(n, voiceSettings.style);
    this.say(voiceSettings.repeat ? `${speech} ${speech}` : speech, options);
  },

  cancel() { synth?.cancel(); },
};
