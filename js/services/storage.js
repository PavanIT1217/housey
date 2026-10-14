// Small JSON wrapper around localStorage that never throws: private windows
// and blocked storage just mean nothing is remembered.

/** Every key Housey stores, in one place. */
export const KEYS = Object.freeze({
  gameSettings: 'housey.settings',
  sound: 'housey.sound',
  voice: 'housey.voice',
  callerSettings: 'housey.caller.settings',
  savedGame: 'housey.game',
  callerSession: 'housey.caller.session',
  myTickets: 'housey.mytickets',
  printOptions: 'housey.print',
});

function backend() {
  try { return globalThis.localStorage ?? null; } catch { return null; }
}

export const storage = {
  get(key, fallback = null) {
    try {
      const raw = backend()?.getItem(key);
      return raw == null ? fallback : JSON.parse(raw);
    } catch {
      return fallback;
    }
  },
  set(key, value) {
    try { backend()?.setItem(key, JSON.stringify(value)); } catch { /* storage full or unavailable */ }
  },
  remove(key) {
    try { backend()?.removeItem(key); } catch { /* storage unavailable */ }
  },
};

/**
 * A stored record with a schema version, so old or foreign data is ignored
 * rather than crashing the page. In-progress games, caller sessions and saved
 * tickets all go through one of these; swapping one for a server-backed
 * version later doesn't touch the pages that use it.
 */
export function versionedRecord(key, version) {
  return {
    load() {
      const record = storage.get(key);
      return record && record.version === version ? record.data : null;
    },
    save(data) { storage.set(key, { version, savedAt: Date.now(), data }); },
    clear() { storage.remove(key); },
  };
}

export const savedGameRecord = versionedRecord(KEYS.savedGame, 1);
export const callerSessionRecord = versionedRecord(KEYS.callerSession, 1);
export const myTicketsRecord = versionedRecord(KEYS.myTickets, 1);
