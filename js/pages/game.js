// The Housey table: you and the computer players race to claim prizes.

import { $, $$, announce, createWakeLock, el, registerServiceWorker, toast, vibrate } from '../ui/dom.js';
import { MANUAL_SPEED, loadGameSettings, saveGameSettings, voiceSettings } from '../services/settings.js';
import { PRIZES, meetsPrize, prizeByKey } from '../core/prizes.js';
import { addDab, cellFor, removeDab, renderTicket } from '../ui/ticket-view.js';
import { between, shuffle } from '../core/random.js';
import { createTicket, createTickets, ticketFromCode, ticketNumbers } from '../core/tickets.js';
import { markCalled, renderBoard, showCalled } from '../ui/board.js';
import { mountSpeedControl, mountVoiceSettings } from '../ui/caller-settings.js';
import { CallerDisplay } from '../ui/caller-display.js';
import { NumberDraw } from '../core/number-draw.js';
import { describeCall } from '../core/calls.js';
import { savedGameRecord } from '../services/storage.js';
import { sound } from '../services/sound.js';
import { speaker } from '../services/speech.js';

const BOT_NAMES = ['Priya', 'Ravi', 'Aunty Meena', 'Uncle Joe', 'Fatima', 'Sam', 'Grandpa Dev', 'Lucy', 'Arjun', 'Rosa'];
const COLORS = ['#c0392b', '#2471a3', '#7d3c98', '#1e8449', '#b9770e', '#a04000', '#117a65', '#884ea0'];
const ME_COLOR = '#b3261e';

const settings = loadGameSettings();
const wakeLock = createWakeLock();
const board = $('#board');
const display = new CallerDisplay({ slot: $('#coinSlot'), tray: $('#tray'), text: $('#callText'), count: $('#callCount') });
speaker.isMuted = () => !sound.on;

/** The game in play, or null before the first deal. */
let game = null;
let timers = [];
let drawTimer = null;

const isManual = () => settings.speed === MANUAL_SPEED;
const isCalled = n => game.draw.has(n);
const later = (fn, ms) => {
  const id = setTimeout(() => { timers = timers.filter(t => t !== id); fn(); }, ms);
  timers.push(id);
  return id;
};
const clearTimers = () => {
  timers.forEach(clearTimeout);
  timers = [];
  clearTimeout(drawTimer);
  drawTimer = null;
};

// ---------- Saving (so a refresh doesn't lose the game) ----------
function saveGame() {
  if (!game) return;
  if (game.over) { savedGameRecord.clear(); return; }
  savedGameRecord.save({
    draw: game.draw.toJSON(),
    prizes: Object.fromEntries(PRIZES.map(p => [p.key, game.prizes[p.key]?.id ?? null])),
    players: game.players.map(p => ({
      id: p.id, name: p.name, human: p.human, color: p.color, points: p.points, wins: p.wins, skill: p.skill,
      tickets: p.tickets.map(t => ({ code: t.code, dabs: [...t.dabs] })),
    })),
  });
}

/** Rebuilds a saved game, or returns null if the saved data can't be used. */
function loadSavedGame() {
  const data = savedGameRecord.load();
  const draw = NumberDraw.fromJSON(data?.draw);
  if (!draw || !Array.isArray(data.players)) return null;
  try {
    const players = data.players.map(p => ({
      ...p,
      wins: [...p.wins],
      tickets: p.tickets.map(t => {
        const ticket = ticketFromCode(t.code);
        if (!ticket) throw new Error(`Bad ticket code ${t.code}`);
        return { ...ticket, dabs: new Set(t.dabs) };
      }),
    }));
    const me = players.find(p => p.human);
    if (!me) return null;
    const prizes = Object.fromEntries(PRIZES.map(p => [p.key, players.find(pl => pl.id === data.prizes?.[p.key]) ?? null]));
    return newGameState(players, me, draw, prizes);
  } catch {
    return null;
  }
}

const newGameState = (players, me, draw, prizes) => ({
  players, me, draw, prizes,
  paused: false, over: false, holdUntil: 0, pending: new Set(),
});

// ---------- Starting ----------
function dealNewGame() {
  clearTimers();
  const me = { id: 0, name: settings.name.trim() || 'You', human: true, color: ME_COLOR, points: 0, wins: [] };
  const bots = shuffle(BOT_NAMES.slice()).slice(0, settings.bots).map((name, i) => ({
    id: i + 1, name, human: false, color: COLORS[i % COLORS.length], points: 0, wins: [], skill: between(0.55, 0.9),
  }));
  const players = [me, ...bots];
  players.forEach(p => { p.tickets = createTickets(settings.tickets).map(t => ({ ...t, dabs: new Set() })); });
  game = newGameState(players, me, NumberDraw.shuffled(), Object.fromEntries(PRIZES.map(p => [p.key, null])));

  renderAll();
  display.reset('Shuffling the coins…');
  syncMode();
  if (isManual()) display.setMessage('Tap the bag to draw');
  else scheduleDraw(1800);
  wakeLock.request();
  saveGame();
}

function resumeGame(saved) {
  clearTimers();
  game = saved;
  game.paused = !isManual();
  renderAll();
  showCalled(board, game.draw.called);
  display.restore(game.draw.called, isManual() ? 'Welcome back. Tap the bag to draw' : 'Welcome back. Press ▶ to carry on');
  syncMode();
  wakeLock.request();
  botsConsider();
}

// ---------- Rendering ----------
function renderAll() {
  renderTickets();
  renderBoard(board);
  renderClaims();
  renderPlayers();
}

function renderTickets() {
  const wrap = $('#tickets');
  wrap.innerHTML = '';
  const { tickets } = game.me;
  tickets.forEach((t, i) => {
    const tk = renderTicket(t, {
      heading: `Ticket ${i + 1} of ${tickets.length}`,
      onCellClick: (n, cell) => toggleDab(t, n, cell),
    });
    tk.dataset.index = i;
    t.dabs.forEach(n => {
      const cell = cellFor(tk, n);
      addDab(cell);
      if (game.draw && !isCalled(n)) cell?.classList.add('wrong');
    });
    wrap.append(tk);
  });
}

function toggleDab(ticket, n, cell) {
  if (!game || game.over) return;
  sound.init();
  if (ticket.dabs.has(n)) {
    ticket.dabs.delete(n);
    removeDab(cell);
  } else {
    ticket.dabs.add(n);
    addDab(cell, true);
    sound.dab();
    vibrate(15);
    if (!isCalled(n)) {
      cell.classList.add('wrong');
      toast(`${n} hasn't been called yet. Tap again to undo`);
    }
  }
  saveGame();
}

function renderClaims() {
  const wrap = $('#claims');
  wrap.innerHTML = '';
  PRIZES.forEach(p => {
    const b = el('button', 'claim');
    b.id = `claim-${p.key}`;
    b.innerHTML = `${p.label}<small>${p.points} pts</small>`;
    b.addEventListener('click', () => humanClaim(p.key));
    wrap.append(b);
    if (game.prizes[p.key]) markClaimed(p.key, game.prizes[p.key]);
  });
}

function markClaimed(key, player) {
  const b = $(`#claim-${key}`);
  b.disabled = true;
  b.classList.toggle('mine', player.human);
  b.append(el('span', 'stamp', player.human ? 'Yours!' : player.name));
}

const winsText = (p, sep) => p.wins.map(k => prizeByKey(k).label).join(sep);

function renderPlayers() {
  const wrap = $('#players');
  wrap.innerHTML = '';
  wrap.append(el('h3', '', 'At the table'));
  [...game.players].sort((a, b) => b.points - a.points || a.id - b.id).forEach(p => {
    const row = el('div', `player${p.human ? ' me' : ''}`);
    row.id = `p${p.id}`;
    const avatar = el('div', 'avatar', p.name[0].toUpperCase());
    avatar.style.background = p.color;
    const name = el('div', 'pname', p.human && p.name !== 'You' ? `${p.name} (you)` : p.name);
    const tickets = `${p.tickets.length} ticket${p.tickets.length > 1 ? 's' : ''}`;
    name.append(el('small', '', p.wins.length ? winsText(p, ', ') : tickets));
    row.append(avatar, name, el('div', 'points', p.points));
    wrap.append(row);
  });
}

// ---------- Calling ----------
function scheduleDraw(ms) {
  clearTimeout(drawTimer);
  if (!game || game.over || game.paused || isManual()) return;
  drawTimer = setTimeout(drawNext, ms);
}

function drawNext() {
  if (!game || game.over) return;
  const wait = game.holdUntil - Date.now();
  if (wait > 0) { if (!isManual()) scheduleDraw(wait + 300); return; }
  const n = game.draw.next();
  if (n === null) { endGame(); return; }
  saveGame();

  const bag = $('#bag');
  bag.classList.remove('shake');
  void bag.offsetWidth; // restart the animation
  bag.classList.add('shake');
  sound.rummage();

  later(() => {
    display.show(n, { message: describeCall(n, voiceSettings.style).display, called: game.draw.count });
    sound.clack(0.35, 0.9);
    speaker.callNumber(n);
    markCalled(board, n);
    // Cells dabbed early are fine now their number has come up.
    $$(`.cell.wrong[data-n="${n}"]`).forEach(c => c.classList.remove('wrong'));

    if (settings.auto) autoDab(n);
    else if (game.me.tickets.some(t => ticketNumbers(t.grid).includes(n))) vibrate([10, 60, 10]);
    botsConsider();
  }, 550);

  scheduleDraw(settings.speed);
}

function autoDab(n) {
  game.me.tickets.forEach((t, i) => {
    if (!ticketNumbers(t.grid).includes(n) || t.dabs.has(n)) return;
    t.dabs.add(n);
    const cell = cellFor($(`.ticket[data-index="${i}"]`), n);
    later(() => { addDab(cell, true); sound.dab(); }, 700);
  });
  saveGame();
}

// ---------- Computer players ----------
function botsConsider() {
  for (const bot of game.players) {
    if (bot.human) continue;
    for (const p of PRIZES) {
      if (game.prizes[p.key]) continue;
      const key = `${bot.id}:${p.key}`;
      if (game.pending.has(key)) continue;
      if (!bot.tickets.some(t => meetsPrize(p.key, t.grid, isCalled))) continue;
      if (Math.random() > bot.skill) continue; // didn't notice this time; may spot it next call
      game.pending.add(key);
      const base = settings.speed || 4500;
      later(() => {
        game.pending.delete(key);
        if (!game.over && !game.prizes[p.key]) award(bot, p.key);
      }, between(base * 0.3, base * 0.85) + 800);
    }
  }
}

// ---------- Claims ----------
function humanClaim(key) {
  if (!game || game.over) return;
  sound.init();
  if (game.prizes[key]) { toast(`Already claimed by ${game.prizes[key].name}`); return; }
  const { tickets } = game.me;
  const winning = tickets.findIndex(t => meetsPrize(key, t.grid, n => isCalled(n) && t.dabs.has(n)));
  if (winning >= 0) { award(game.me, key, winning); return; }
  if (tickets.some(t => meetsPrize(key, t.grid, isCalled))) {
    toast('So close! Dab all the numbers for that prize first.');
    return;
  }
  sound.bogey();
  speaker.say('Bogey!');
  announce('Bogey!', 'Not quite. Keep playing', true);
}

function award(player, key, ticketIndex) {
  const prize = prizeByKey(key);
  game.prizes[key] = player;
  player.points += prize.points;
  player.wins.push(key);
  markClaimed(key, player);
  renderPlayers();
  $(`#p${player.id}`)?.classList.add('claiming');

  game.holdUntil = Date.now() + 2800;
  if (player.human) {
    sound.win();
    vibrate([40, 40, 80]);
    const tk = $(`.ticket[data-index="${ticketIndex}"]`);
    if (tk) { tk.classList.add('winner'); later(() => tk.classList.remove('winner'), 3500); }
    announce(prize.label, `You win ${prize.points} points!`);
    speaker.say(`${prize.label}! Well done ${player.name}!`);
  } else {
    sound.lose();
    announce(prize.label, `${player.name} claims it, checked ✓`);
    speaker.say(`${prize.label} to ${player.name}!`);
  }

  if (key === 'full') {
    game.over = true;
    clearTimeout(drawTimer);
    later(endGame, 2900);
  } else {
    scheduleDraw(Math.max(settings.speed, 3200));
  }
  saveGame();
}

function endGame() {
  clearTimers();
  if (!game) return;
  game.over = true;
  saveGame();
  wakeLock.release();
  const ranked = [...game.players].sort((a, b) => b.points - a.points || a.id - b.id);
  const list = $('#ranking');
  list.innerHTML = '';
  const medals = ['🥇', '🥈', '🥉'];
  ranked.forEach((p, i) => {
    const li = el('li');
    li.append(el('span', 'medal', p.points ? (medals[i] || '') : ''));
    const who = el('span', 'who', p.human && p.name !== 'You' ? `${p.name} (you)` : p.name);
    who.append(el('small', '', p.wins.length ? winsText(p, ' · ') : 'No prizes this time'));
    li.append(who, el('span', 'pts', p.points));
    list.append(li);
  });
  const top = ranked[0];
  $('#resultsTitle').textContent = !top.points ? 'Game over' : top.human ? 'You won! 🎉' : `${top.name} wins!`;
  $('#results').classList.remove('hidden');
}

// ---------- Pause and speed ----------
function syncMode() {
  document.body.classList.toggle('manual', isManual());
  const b = $('#pauseBtn');
  b.style.visibility = isManual() ? 'hidden' : 'visible';
  b.textContent = game?.paused ? '▶' : '⏸';
  b.setAttribute('aria-label', game?.paused ? 'Resume' : 'Pause');
}

function togglePause() {
  if (!game || game.over || isManual()) return;
  game.paused = !game.paused;
  if (game.paused) {
    clearTimeout(drawTimer);
    display.setMessage('Paused. Take a breather');
    speaker.cancel();
  } else {
    display.setMessage('Here we go…');
    scheduleDraw(1200);
  }
  syncMode();
}

/** Changes the calling speed, including mid-game. */
function setSpeed(ms) {
  const wasManual = isManual();
  settings.speed = ms;
  saveGameSettings(settings);
  const setupOpen = !$('#setup').classList.contains('hidden');
  if (!game || game.over || setupOpen) return;
  if (isManual()) {
    clearTimeout(drawTimer);
    game.paused = false;
    display.setMessage('Tap the bag to draw');
  } else if (wasManual) {
    game.paused = true;
    display.setMessage('Press ▶ to start the caller');
  } else {
    scheduleDraw(ms);
  }
  syncMode();
}

// ---------- Setup card ----------
let savedGame = null;

function openSetup() {
  clearTimers();
  if (game && !game.over) {
    game.paused = true;
    saveGame();
    savedGame = game;
  }
  syncSetup();
  $('#results').classList.add('hidden');
  $('#setup').classList.remove('hidden');
}

function syncSetup() {
  $('#nameInput').value = settings.name;
  $('#autoInput').checked = settings.auto;
  $$('#setup .seg[data-name]').forEach(seg => {
    seg.querySelectorAll('button').forEach(b => b.classList.toggle('on', Number(b.dataset.v) === settings[seg.dataset.name]));
  });
  mountSpeedControl($('#speedControl'), { value: settings.speed, onChange: ms => { settings.speed = ms; } });
  mountVoiceSettings($('#setupVoice'));

  const resumable = savedGame && !savedGame.over;
  $('#resumeBox').classList.toggle('hidden', !resumable);
  $('#startBtn').textContent = resumable ? 'Deal a new game' : 'Deal tickets';
  if (resumable) {
    const n = savedGame.draw.count;
    $('#resumeText').textContent = `You have a game in progress: ${n} of 90 numbers called.`;
  }
}

function readSetup() {
  settings.name = $('#nameInput').value;
  settings.auto = $('#autoInput').checked;
  saveGameSettings(settings);
  sound.init();
  $('#setup').classList.add('hidden');
  $('#results').classList.add('hidden');
}

function start() {
  readSetup();
  savedGame = null;
  dealNewGame();
}

function resume() {
  readSetup();
  const saved = savedGame;
  savedGame = null;
  resumeGame(saved);
}

$$('#setup .seg[data-name]').forEach(seg => {
  seg.querySelectorAll('button').forEach(b => b.addEventListener('click', () => {
    settings[seg.dataset.name] = Number(b.dataset.v);
    seg.querySelectorAll('button').forEach(x => x.classList.toggle('on', x === b));
  }));
});

// ---------- In-game caller settings ----------
function openCallerSettings() {
  mountSpeedControl($('#gameSpeedControl'), { value: settings.speed, onChange: setSpeed });
  mountVoiceSettings($('#gameVoice'));
  $('#callerSettings').classList.remove('hidden');
}
const closeCallerSettings = () => $('#callerSettings').classList.add('hidden');

// ---------- Wire up ----------
$('#startBtn').addEventListener('click', start);
$('#resumeBtn').addEventListener('click', resume);
$('#againBtn').addEventListener('click', start);
$('#settingsBtn').addEventListener('click', openSetup);
$('#newBtn').addEventListener('click', openSetup);
$('#callerSettingsBtn').addEventListener('click', openCallerSettings);
$('#callerSettingsClose').addEventListener('click', closeCallerSettings);
$('#pauseBtn').addEventListener('click', togglePause);
$('#bag').addEventListener('click', () => {
  if (!game || game.over) return;
  sound.init();
  if (isManual()) drawNext();
  else if (game.paused) togglePause();
});

const soundBtn = $('#soundBtn');
const syncSound = () => { soundBtn.textContent = sound.on ? '🔊' : '🔇'; };
soundBtn.addEventListener('click', () => {
  if (!sound.toggle()) speaker.cancel();
  syncSound();
});
syncSound();

document.addEventListener('keydown', e => {
  if (!$('#setup').classList.contains('hidden')) {
    if (e.key === 'Enter' && e.target.id === 'nameInput') start();
    return;
  }
  if (e.key === 'Escape') closeCallerSettings();
  if (e.key === ' ' && e.target === document.body) {
    e.preventDefault();
    if (isManual()) drawNext(); else togglePause();
  }
});
window.addEventListener('pagehide', saveGame);

// ---------- First load ----------
$('#boardBox').open = window.matchMedia('(min-width: 901px)').matches;
savedGame = loadSavedGame();
syncSetup();
// Preview a ticket behind the setup card so the table never looks empty.
game = { players: [], me: { tickets: [{ ...createTicket(), dabs: new Set() }] }, draw: null, prizes: {}, over: true };
renderTickets();
renderBoard(board);
renderClaims();
game = null;
registerServiceWorker();
