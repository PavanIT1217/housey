// The number caller: draws and calls numbers for a game played on paper
// tickets, with no tickets of its own. The host can check any ticket's code
// against the numbers called so far.

import { $, createWakeLock, el, registerServiceWorker } from '../ui/dom.js';
import { loadCallerSettings, saveCallerSettings, voiceSettings } from '../services/settings.js';
import { markCalled, showCalled } from '../ui/board.js';
import { mountSpeedControl, mountVoiceSettings } from '../ui/caller-settings.js';
import { CallerDisplay } from '../ui/caller-display.js';
import { NumberDraw } from '../core/number-draw.js';
import { addDab, cellFor, renderTicket } from '../ui/ticket-view.js';
import { callerSessionRecord } from '../services/storage.js';
import { describeCall } from '../core/calls.js';
import { mountTicketLookup } from '../ui/ticket-lookup.js';
import { prizesMet } from '../core/prizes.js';
import { sound } from '../services/sound.js';
import { speaker } from '../services/speech.js';
import { ticketNumbers } from '../core/tickets.js';

const settings = loadCallerSettings();
const wakeLock = createWakeLock();
const board = $('#board');
const display = new CallerDisplay({ slot: $('#coinSlot'), tray: $('#tray'), text: $('#callText'), count: $('#callCount') });
speaker.isMuted = () => !sound.on;

let draw = NumberDraw.fromJSON(callerSessionRecord.load()?.draw) ?? NumberDraw.shuffled();
let running = false;
let timer = null;
/** The ticket last checked; it updates live as numbers are called. */
let checkedTicket = null;

const save = () => callerSessionRecord.save({ draw: draw.toJSON() });

// ---------- Calling ----------
function callNext() {
  sound.init();
  const n = draw.next();
  if (n === null) {
    stop();
    display.setMessage('All 90 numbers have been called');
    return;
  }
  save();
  const bag = $('#bag');
  bag.classList.remove('shake');
  void bag.offsetWidth; // restart the animation
  bag.classList.add('shake');
  sound.rummage();
  sound.clack(0.35, 0.9);

  display.show(n, { message: describeCall(n, voiceSettings.style).display, called: draw.count });
  speaker.callNumber(n);
  markCalled(board, n);
  refresh();
}

function schedule() {
  clearTimeout(timer);
  if (running) timer = setTimeout(() => { callNext(); schedule(); }, settings.speed);
}

function start() {
  if (draw.isFinished) return;
  running = true;
  wakeLock.request();
  callNext();
  schedule();
  refresh();
}

function stop() {
  running = false;
  clearTimeout(timer);
  wakeLock.release();
  refresh();
}

function undo() {
  const n = draw.undo();
  if (n === null) return;
  save();
  speaker.cancel();
  showCalled(board, draw.called);
  display.restore(draw.called, `${n} put back in the bag`);
  schedule(); // restart the countdown so the next call isn't rushed
  refresh();
}

function newGame() {
  if (draw.count && !window.confirm('Start a new game? The numbers called so far will be cleared.')) return;
  stop();
  draw = NumberDraw.shuffled();
  save();
  showCalled(board, []);
  display.reset('New game. Press Start when everyone is ready');
  refresh();
}

// ---------- Controls and ticket check ----------
function refresh() {
  $('#playBtn').textContent = running ? '⏸ Pause' : draw.count ? '▶ Carry on' : '▶ Start calling';
  $('#playBtn').disabled = draw.isFinished;
  $('#nextBtn').disabled = draw.isFinished;
  $('#undoBtn').disabled = draw.count === 0;
  if (checkedTicket) showCheck(checkedTicket);
}

function showCheck(ticket) {
  checkedTicket = ticket;
  const has = n => draw.has(n);
  const tk = renderTicket(ticket, { heading: 'Checking', tilt: false });
  ticketNumbers(ticket.grid).filter(has).forEach(n => addDab(cellFor(tk, n)));

  const hits = ticketNumbers(ticket.grid).filter(has).length;
  const won = prizesMet(ticket.grid, has);
  const summary = el('div', 'check-summary');
  summary.append(el('p', '', `${hits} of 15 numbers on this ticket have been called.`));
  const list = el('ul', 'prize-list');
  if (won.length) won.forEach(p => list.append(el('li', 'won', `✓ ${p.label}`)));
  else list.append(el('li', '', 'No prize complete yet.'));
  summary.append(list);
  const close = el('button', 'small-btn ghost', 'Clear');
  close.type = 'button';
  close.addEventListener('click', () => { checkedTicket = null; $('#checkResult').innerHTML = ''; });
  summary.append(close);

  $('#checkResult').replaceChildren(tk, summary);
}

// ---------- Wire up ----------
$('#playBtn').addEventListener('click', () => (running ? stop() : start()));
$('#nextBtn').addEventListener('click', () => { callNext(); schedule(); });
$('#bag').addEventListener('click', () => { callNext(); schedule(); });
$('#undoBtn').addEventListener('click', undo);
$('#resetBtn').addEventListener('click', newGame);
$('#fullscreenBtn').addEventListener('click', () => {
  if (document.fullscreenElement) document.exitFullscreen();
  else document.documentElement.requestFullscreen?.().catch(() => {});
});

const soundBtn = $('#soundBtn');
const syncSound = () => { soundBtn.textContent = sound.on ? '🔊' : '🔇'; };
soundBtn.addEventListener('click', () => {
  if (!sound.toggle()) speaker.cancel();
  syncSound();
});
syncSound();

document.addEventListener('keydown', e => {
  if (e.target.closest('input, select, textarea, button')) return;
  if (e.key === ' ') { e.preventDefault(); if (running) stop(); else start(); }
  if (e.key === 'n' || e.key === 'N') { callNext(); schedule(); }
  if (e.key === 'u' || e.key === 'U') undo();
});

mountSpeedControl($('#speedControl'), {
  value: settings.speed,
  allowManual: false,
  onChange: ms => {
    settings.speed = ms;
    saveCallerSettings(settings);
    schedule();
  },
});
mountVoiceSettings($('#voiceSettings'));
mountTicketLookup($('#lookup'), { buttonLabel: 'Check', onTicket: showCheck });

// ---------- First load: carry on from where we were ----------
showCalled(board, draw.called);
display.restore(draw.called, draw.count
  ? `Welcome back: ${draw.count} numbers called. Press Carry on`
  : 'Press Start when everyone is ready');
refresh();
registerServiceWorker();
