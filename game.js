(() => {
  'use strict';

  // ---------- Helpers ----------
  const $ = (s, root = document) => root.querySelector(s);
  const rand = n => Math.floor(Math.random() * n);
  const between = (a, b) => a + Math.random() * (b - a);
  const shuffle = a => { for (let i = a.length - 1; i > 0; i--) { const j = rand(i + 1); [a[i], a[j]] = [a[j], a[i]]; } return a; };
  const el = (tag, cls, text) => { const e = document.createElement(tag); if (cls) e.className = cls; if (text != null) e.textContent = text; return e; };
  const store = {
    get(k, d) { try { const v = localStorage.getItem(k); return v == null ? d : JSON.parse(v); } catch { return d; } },
    set(k, v) { try { localStorage.setItem(k, JSON.stringify(v)); } catch { /* storage unavailable */ } },
  };

  // ---------- Traditional calls ----------
  const CALLS = ['',
    "Kelly's eye", 'One little duck', 'Cup of tea', 'Knock at the door', 'Man alive', 'Half a dozen', 'Lucky seven', 'Garden gate', "Doctor's orders", 'Cock and hen',
    'Legs eleven', 'One dozen', 'Unlucky for some', "Valentine's day", 'Young and keen', 'Sweet sixteen', 'Dancing queen', 'Coming of age', 'Goodbye teens', 'One score',
    'Key of the door', 'Two little ducks', 'Thee and me', 'Two dozen', 'Duck and dive', 'Pick and mix', 'Gateway to heaven', 'Overweight', 'Rise and shine', 'Dirty Gertie',
    'Get up and run', 'Buckle my shoe', 'All the threes', 'Ask for more', 'Jump and jive', 'Three dozen', 'More than eleven', 'Christmas cake', 'Climb the steps', 'Naughty forty',
    'Time for fun', 'Winnie the Pooh', 'Down on your knees', 'Droopy drawers', 'Halfway there', 'Up to tricks', 'Four and seven', 'Four dozen', 'P.C.', 'Half a century',
    'Tweak of the thumb', 'Danny La Rue', 'Stuck in the tree', 'Clean the floor', 'Snakes alive', 'Was she worth it', 'Heinz varieties', 'Make them wait', 'Brighton line', 'Five dozen',
    "Baker's bun", 'Turn the screw', 'Tickle me', 'Red raw', 'Old age pension', 'Clickety click', 'Stairway to heaven', 'Saving grace', 'Either way up', 'Three score and ten',
    'Bang on the drum', 'Six dozen', 'Queen bee', 'Candy store', 'Strive and strive', 'Trombones', 'Sunset strip', "Heaven's gate", 'One more time', 'Eight and blank',
    'Stop and run', 'Straight on through', 'Time for tea', 'Seven dozen', 'Staying alive', 'Between the sticks', 'Torquay in Devon', 'Two fat ladies', 'Nearly there', 'Top of the shop',
  ];
  const DIGITS = ['zero', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine'];
  const spoken = n => n < 10 ? `${CALLS[n]}. Number ${n}.` : `${CALLS[n]}. ${DIGITS[Math.floor(n / 10)]} and ${DIGITS[n % 10]}, ${n}.`;

  const PRIZES = [
    { key: 'early5', label: 'Early Five', pts: 50 },
    { key: 'top', label: 'Top Line', pts: 100 },
    { key: 'middle', label: 'Middle Line', pts: 100 },
    { key: 'bottom', label: 'Bottom Line', pts: 100 },
    { key: 'full', label: 'Full House', pts: 250 },
  ];
  const BOT_NAMES = ['Priya', 'Ravi', 'Aunty Meena', 'Uncle Joe', 'Fatima', 'Sam', 'Grandpa Dev', 'Lucy', 'Arjun', 'Rosa'];
  const COLORS = ['#c0392b', '#2471a3', '#7d3c98', '#1e8449', '#b9770e', '#a04000', '#117a65', '#884ea0'];

  // ---------- Ticket generation (3 rows x 9 columns, 5 numbers per row) ----------
  function makeTicket() {
    for (;;) {
      const counts = Array(9).fill(1);
      for (let extra = 6; extra > 0;) { const c = rand(9); if (counts[c] < 3) { counts[c]++; extra--; } }

      const layout = [0, 1, 2].map(() => Array(9).fill(false));
      const rowCount = [0, 0, 0];
      const order = shuffle([...Array(9).keys()]).sort((a, b) => counts[b] - counts[a]);
      let ok = true;
      for (const c of order) {
        const rows = shuffle([0, 1, 2].filter(r => rowCount[r] < 5)).sort((a, b) => rowCount[a] - rowCount[b]);
        if (rows.length < counts[c]) { ok = false; break; }
        rows.slice(0, counts[c]).forEach(r => { layout[r][c] = true; rowCount[r]++; });
      }
      if (!ok || rowCount.some(x => x !== 5)) continue;

      const grid = [0, 1, 2].map(() => Array(9).fill(0));
      for (let c = 0; c < 9; c++) {
        const lo = c === 0 ? 1 : c * 10, hi = c === 8 ? 90 : c * 10 + 9;
        const pool = shuffle(Array.from({ length: hi - lo + 1 }, (_, i) => lo + i)).slice(0, counts[c]).sort((a, b) => a - b);
        for (let r = 0; r < 3; r++) if (layout[r][c]) grid[r][c] = pool.shift();
      }
      return { grid, dabs: new Set(), serial: String(10000 + rand(89999)) };
    }
  }

  const rowNums = (t, r) => t.grid[r].filter(Boolean);
  const allNums = t => t.grid.flat().filter(Boolean);
  function meets(prize, t, has) {
    switch (prize) {
      case 'early5': return allNums(t).filter(has).length >= 5;
      case 'top': return rowNums(t, 0).every(has);
      case 'middle': return rowNums(t, 1).every(has);
      case 'bottom': return rowNums(t, 2).every(has);
      case 'full': return allNums(t).every(has);
    }
    return false;
  }

  // ---------- Sound (synthesised, no files needed) ----------
  const sound = {
    ctx: null, on: store.get('housey.sound', true),
    init() { if (!this.ctx) { try { this.ctx = new (window.AudioContext || window.webkitAudioContext)(); } catch { /* no audio */ } } if (this.ctx && this.ctx.state === 'suspended') this.ctx.resume(); },
    noise(dur) {
      const b = this.ctx.createBuffer(1, Math.ceil(this.ctx.sampleRate * dur), this.ctx.sampleRate);
      const d = b.getChannelData(0); for (let i = 0; i < d.length; i++) d[i] = Math.random() * 2 - 1;
      const s = this.ctx.createBufferSource(); s.buffer = b; return s;
    },
    clack(when = 0, pitch = 1) { // wooden coins knocking together
      if (!this.on || !this.ctx) return;
      const t = this.ctx.currentTime + when;
      const n = this.noise(.06), f = this.ctx.createBiquadFilter(), g = this.ctx.createGain();
      f.type = 'bandpass'; f.frequency.value = 1500 * pitch; f.Q.value = 4;
      g.gain.setValueAtTime(.5, t); g.gain.exponentialRampToValueAtTime(.001, t + .06);
      n.connect(f).connect(g).connect(this.ctx.destination); n.start(t);
      const o = this.ctx.createOscillator(), og = this.ctx.createGain();
      o.frequency.value = 820 * pitch; og.gain.setValueAtTime(.18, t); og.gain.exponentialRampToValueAtTime(.001, t + .05);
      o.connect(og).connect(this.ctx.destination); o.start(t); o.stop(t + .06);
    },
    rummage() { for (let i = 0; i < 6; i++) this.clack(i * .07 + Math.random() * .04, between(.8, 1.25)); },
    dab() { // dauber thump
      if (!this.on || !this.ctx) return;
      const t = this.ctx.currentTime;
      const o = this.ctx.createOscillator(), g = this.ctx.createGain();
      o.frequency.setValueAtTime(170, t); o.frequency.exponentialRampToValueAtTime(55, t + .09);
      g.gain.setValueAtTime(.45, t); g.gain.exponentialRampToValueAtTime(.001, t + .12);
      o.connect(g).connect(this.ctx.destination); o.start(t); o.stop(t + .13);
      const n = this.noise(.05), f = this.ctx.createBiquadFilter(), ng = this.ctx.createGain();
      f.type = 'lowpass'; f.frequency.value = 900; ng.gain.setValueAtTime(.25, t); ng.gain.exponentialRampToValueAtTime(.001, t + .05);
      n.connect(f).connect(ng).connect(this.ctx.destination); n.start(t);
    },
    tones(notes, type = 'triangle', vol = .2) {
      if (!this.on || !this.ctx) return;
      const t0 = this.ctx.currentTime;
      notes.forEach(([freq, at, dur]) => {
        const o = this.ctx.createOscillator(), g = this.ctx.createGain(), t = t0 + at;
        o.type = type; o.frequency.value = freq;
        g.gain.setValueAtTime(0, t); g.gain.linearRampToValueAtTime(vol, t + .02); g.gain.exponentialRampToValueAtTime(.001, t + dur);
        o.connect(g).connect(this.ctx.destination); o.start(t); o.stop(t + dur + .05);
      });
    },
    win() { this.tones([[523, 0, .3], [659, .12, .3], [784, .24, .3], [1047, .36, .7]]); },
    lose() { this.tones([[392, 0, .25], [330, .15, .4]], 'sine', .15); },
    bogey() { this.tones([[140, 0, .5], [110, .05, .55]], 'sawtooth', .12); },
  };

  const voice = {
    v: null,
    pick() {
      if (!('speechSynthesis' in window)) return;
      const vs = speechSynthesis.getVoices();
      this.v = vs.find(v => /en-IN/i.test(v.lang)) || vs.find(v => /en-GB/i.test(v.lang)) || vs.find(v => /^en/i.test(v.lang)) || null;
    },
    say(text) {
      if (!settings.voice || !sound.on || !('speechSynthesis' in window)) return;
      speechSynthesis.cancel();
      const u = new SpeechSynthesisUtterance(text);
      if (this.v) u.voice = this.v;
      u.rate = .95; u.pitch = 1;
      speechSynthesis.speak(u);
    },
  };
  if ('speechSynthesis' in window) { voice.pick(); speechSynthesis.onvoiceschanged = () => voice.pick(); }

  // ---------- State ----------
  const settings = Object.assign({ name: '', tickets: 1, bots: 4, speed: 5500, voice: true, auto: false }, store.get('housey.settings', {}));
  let game = null;
  let timers = [];
  let drawTimer = null;
  let wakeLock = null;

  const later = (fn, ms) => { const id = setTimeout(() => { timers = timers.filter(t => t !== id); fn(); }, ms); timers.push(id); return id; };
  const clearTimers = () => { timers.forEach(clearTimeout); timers = []; clearTimeout(drawTimer); drawTimer = null; };

  function newGame() {
    clearTimers();
    const me = { id: 0, name: settings.name.trim() || 'You', human: true, color: '#b3261e', points: 0, wins: [] };
    const names = shuffle(BOT_NAMES.slice()).slice(0, settings.bots);
    const bots = names.map((name, i) => ({ id: i + 1, name, human: false, color: COLORS[i % COLORS.length], points: 0, wins: [], skill: between(.55, .9) }));
    const players = [me, ...bots];
    players.forEach(p => { p.tickets = Array.from({ length: settings.tickets }, makeTicket); });
    game = {
      players, me,
      remaining: shuffle(Array.from({ length: 90 }, (_, i) => i + 1)),
      called: [], calledSet: new Set(),
      prizes: Object.fromEntries(PRIZES.map(p => [p.key, null])),
      paused: false, over: false, holdUntil: 0, pending: new Set(),
    };
    renderAll();
    setCall('Shuffling the coins…', '');
    $('#coinSlot').innerHTML = '<div class="coin-placeholder">?</div>';
    $('#tray').innerHTML = '';
    document.body.classList.toggle('manual', settings.speed === 0);
    updatePauseBtn();
    if (settings.speed === 0) setCall('Tap the bag to draw', '');
    else scheduleDraw(1800);
    requestWakeLock();
  }

  // ---------- Rendering ----------
  function renderAll() { renderTickets(); renderBoard(); renderClaims(); renderPlayers(); }

  function renderTickets() {
    const wrap = $('#tickets'); wrap.innerHTML = '';
    game.me.tickets.forEach((t, ti) => {
      const tk = el('div', 'ticket');
      tk.style.setProperty('--rot', `${between(-1.2, 1.2).toFixed(2)}deg`);
      tk.dataset.index = ti;
      const head = el('div', 'ticket-head');
      head.append(el('span', 'brand', 'Housey'), el('span', '', `Ticket ${ti + 1} of ${game.me.tickets.length}`), el('span', 'serial', `Nº ${t.serial}`));
      const grid = el('div', 'grid');
      t.grid.forEach(row => row.forEach(n => {
        if (!n) { grid.append(el('div', 'cell empty')); return; }
        const b = el('button', 'cell num-cell');
        b.dataset.n = n;
        b.setAttribute('aria-label', `Number ${n}`);
        b.append(el('span', 'num', n));
        b.addEventListener('click', () => toggleDab(t, n, b));
        grid.append(b);
      }));
      tk.append(head, grid);
      wrap.append(tk);
    });
  }

  function addDab(cell, fresh) {
    if (cell.querySelector('.dab')) return;
    const d = el('span', 'dab' + (fresh ? ' fresh' : ''));
    d.style.setProperty('--r', `${rand(360)}deg`);
    d.style.setProperty('--dx', `${between(-4, 4).toFixed(1)}%`);
    d.style.setProperty('--dy', `${between(-4, 4).toFixed(1)}%`);
    d.style.setProperty('--s', between(.92, 1.06).toFixed(2));
    d.style.filter = `url(#ink${rand(4)})`;
    cell.append(d);
  }

  function toggleDab(t, n, cell) {
    if (!game || game.over) return;
    sound.init();
    if (t.dabs.has(n)) {
      t.dabs.delete(n); cell.querySelector('.dab')?.remove(); cell.classList.remove('wrong');
      return;
    }
    t.dabs.add(n);
    addDab(cell, true);
    sound.dab();
    if (navigator.vibrate) navigator.vibrate(15);
    if (!game.calledSet.has(n)) {
      cell.classList.add('wrong');
      toast(`${n} hasn't been called yet — tap again to undo`);
    }
  }

  function renderBoard() {
    const b = $('#board'); b.innerHTML = '';
    for (let n = 1; n <= 90; n++) {
      const c = el('div', 'bcell'); c.id = `b${n}`;
      c.append(el('span', '', n));
      b.append(c);
    }
  }

  function renderClaims() {
    const wrap = $('#claims'); wrap.innerHTML = '';
    PRIZES.forEach(p => {
      const b = el('button', 'claim'); b.id = `claim-${p.key}`;
      b.innerHTML = `${p.label}<small>${p.pts} pts</small>`;
      b.addEventListener('click', () => humanClaim(p.key));
      wrap.append(b);
    });
  }

  function markClaimed(key, player) {
    const b = $(`#claim-${key}`);
    b.disabled = true;
    b.classList.toggle('mine', player.human);
    const s = el('span', 'stamp', player.human ? 'Yours!' : player.name);
    b.append(s);
  }

  function renderPlayers() {
    const wrap = $('#players'); wrap.innerHTML = '';
    wrap.append(el('h3', '', 'At the table'));
    [...game.players].sort((a, b) => b.points - a.points || a.id - b.id).forEach(p => {
      const row = el('div', 'player' + (p.human ? ' me' : '')); row.id = `p${p.id}`;
      const av = el('div', 'avatar', p.name[0].toUpperCase()); av.style.background = p.color;
      const nm = el('div', 'pname', p.human && p.name !== 'You' ? `${p.name} (you)` : p.name);
      nm.append(el('small', '', p.wins.length ? p.wins.map(k => PRIZES.find(x => x.key === k).label).join(', ') : `${p.tickets.length} ticket${p.tickets.length > 1 ? 's' : ''}`));
      row.append(av, nm, el('div', 'points', p.points));
      wrap.append(row);
    });
  }

  function makeCoin(n) {
    const c = el('div', 'coin' + (n === 6 || n === 9 || n === 66 || n === 69 || n === 96 ? ' underline' : ''), n);
    return c;
  }

  function setCall(text, count) {
    $('#callText').textContent = text;
    if (count != null) $('#callCount').textContent = count;
  }

  // ---------- Calling ----------
  function scheduleDraw(ms) {
    clearTimeout(drawTimer);
    if (!game || game.over || game.paused || settings.speed === 0) return;
    drawTimer = setTimeout(drawNext, ms);
  }

  function drawNext() {
    if (!game || game.over) return;
    const wait = game.holdUntil - Date.now();
    if (wait > 0) { if (settings.speed) scheduleDraw(wait + 300); return; }
    if (!game.remaining.length) { endGame(); return; }

    const n = game.remaining.pop();
    game.called.push(n); game.calledSet.add(n);

    const bag = $('#bag');
    bag.classList.remove('shake'); void bag.offsetWidth; bag.classList.add('shake');
    sound.rummage();

    later(() => {
      // move previous coin into the tray
      const slot = $('#coinSlot');
      const prev = slot.querySelector('.coin');
      if (prev) {
        const small = makeCoin(Number(prev.textContent));
        const tray = $('#tray');
        tray.prepend(small);
        while (tray.children.length > 6) tray.lastChild.remove();
      }
      slot.innerHTML = '';
      const coin = makeCoin(n); coin.classList.add('emerge');
      slot.append(coin);
      sound.clack(.35, .9);

      setCall(CALLS[n], `${game.called.length} / 90 called`);
      voice.say(spoken(n));

      document.querySelectorAll('.bcell.latest').forEach(c => c.classList.remove('latest'));
      const bc = $(`#b${n}`); bc.classList.add('called', 'latest'); bc.prepend(el('i', 'chip'));

      // clear "not called yet" warnings on cells that now are
      document.querySelectorAll(`.cell.wrong[data-n="${n}"]`).forEach(c => c.classList.remove('wrong'));

      if (settings.auto) autoDab(n);
      else if (game.me.tickets.some(t => allNums(t).includes(n)) && navigator.vibrate) navigator.vibrate([10, 60, 10]);

      botsConsider();
    }, 550);

    scheduleDraw(settings.speed);
  }

  function autoDab(n) {
    game.me.tickets.forEach((t, ti) => {
      if (!allNums(t).includes(n) || t.dabs.has(n)) return;
      t.dabs.add(n);
      const cell = document.querySelector(`.ticket[data-index="${ti}"] .cell[data-n="${n}"]`);
      if (cell) later(() => { addDab(cell, true); sound.dab(); }, 700);
    });
  }

  // ---------- Bots ----------
  function botsConsider() {
    const has = n => game.calledSet.has(n);
    for (const bot of game.players) {
      if (bot.human) continue;
      for (const p of PRIZES) {
        if (game.prizes[p.key]) continue;
        const key = `${bot.id}:${p.key}`;
        if (game.pending.has(key)) continue;
        if (!bot.tickets.some(t => meets(p.key, t, has))) continue;
        if (Math.random() > bot.skill) continue; // didn't notice this time — may spot it next call
        game.pending.add(key);
        const base = settings.speed || 4500;
        later(() => {
          game.pending.delete(key);
          if (!game.over && !game.prizes[p.key]) award(bot, p.key);
        }, between(base * .3, base * .85) + 800);
      }
    }
  }

  // ---------- Claims ----------
  function humanClaim(key) {
    if (!game || game.over) return;
    sound.init();
    if (game.prizes[key]) { toast(`Already claimed by ${game.prizes[key].name}`); return; }
    const me = game.me;
    const ok = t => meets(key, t, n => game.calledSet.has(n) && t.dabs.has(n));
    const winning = me.tickets.findIndex(ok);
    if (winning >= 0) { award(me, key, winning); return; }
    if (me.tickets.some(t => meets(key, t, n => game.calledSet.has(n)))) {
      toast('So close! Dab all the numbers for that prize first.');
      return;
    }
    sound.bogey();
    voice.say('Bogey!');
    announce('Bogey!', 'Not quite — keep playing', true);
  }

  function award(player, key, ticketIndex) {
    const prize = PRIZES.find(p => p.key === key);
    game.prizes[key] = player;
    player.points += prize.pts;
    player.wins.push(key);
    markClaimed(key, player);
    renderPlayers();
    $(`#p${player.id}`)?.classList.add('claiming');

    game.holdUntil = Date.now() + 2800;
    if (player.human) {
      sound.win();
      if (navigator.vibrate) navigator.vibrate([40, 40, 80]);
      const tk = document.querySelector(`.ticket[data-index="${ticketIndex}"]`);
      if (tk) { tk.classList.add('winner'); later(() => tk.classList.remove('winner'), 3500); }
      announce(prize.label, `You win ${prize.pts} points!`);
      voice.say(`${prize.label}! Well done ${player.name}!`);
    } else {
      sound.lose();
      announce(prize.label, `${player.name} claims it — checked ✓`);
      voice.say(`${prize.label} to ${player.name}!`);
    }

    if (key === 'full') { game.over = true; clearTimeout(drawTimer); later(endGame, 2900); }
    else scheduleDraw(Math.max(settings.speed, 3200));
  }

  function endGame() {
    clearTimers();
    if (!game) return;
    game.over = true;
    releaseWakeLock();
    const ranked = [...game.players].sort((a, b) => b.points - a.points || a.id - b.id);
    const list = $('#ranking'); list.innerHTML = '';
    const medals = ['🥇', '🥈', '🥉'];
    ranked.forEach((p, i) => {
      const li = el('li');
      li.append(el('span', 'medal', p.points ? (medals[i] || '') : ''));
      const who = el('span', 'who', p.human && p.name !== 'You' ? `${p.name} (you)` : p.name);
      who.append(el('small', '', p.wins.length ? p.wins.map(k => PRIZES.find(x => x.key === k).label).join(' · ') : 'No prizes this time'));
      li.append(who, el('span', 'pts', p.points));
      list.append(li);
    });
    const top = ranked[0];
    $('#resultsTitle').textContent = !top.points ? 'Game over' : top.human ? 'You won! 🎉' : `${top.name} wins!`;
    $('#results').classList.remove('hidden');
  }

  // ---------- UI bits ----------
  let toastTimer;
  function toast(msg) {
    const t = $('#toast'); t.textContent = msg; t.classList.add('show');
    clearTimeout(toastTimer); toastTimer = setTimeout(() => t.classList.remove('show'), 2600);
  }
  function announce(title, sub, bad) {
    const a = $('#announce'); a.innerHTML = '';
    const b = el('div', 'banner' + (bad ? ' bogey' : ''), title);
    b.append(el('small', '', sub));
    a.append(b);
  }

  function updatePauseBtn() {
    const b = $('#pauseBtn');
    b.style.visibility = settings.speed === 0 ? 'hidden' : 'visible';
    b.textContent = game && game.paused ? '▶' : '⏸';
  }

  async function requestWakeLock() {
    try { if ('wakeLock' in navigator && !wakeLock) { wakeLock = await navigator.wakeLock.request('screen'); wakeLock.addEventListener('release', () => { wakeLock = null; }); } } catch { /* not allowed */ }
  }
  function releaseWakeLock() { try { wakeLock?.release(); } catch { /* ignore */ } wakeLock = null; }

  // ---------- Setup screen ----------
  function initSetup() {
    $('#nameInput').value = settings.name;
    $('#voiceInput').checked = settings.voice;
    $('#autoInput').checked = settings.auto;
    document.querySelectorAll('.seg').forEach(seg => {
      const name = seg.dataset.name;
      const sync = () => seg.querySelectorAll('button').forEach(b => b.classList.toggle('on', Number(b.dataset.v) === settings[name]));
      seg.querySelectorAll('button').forEach(b => b.addEventListener('click', () => { settings[name] = Number(b.dataset.v); sync(); }));
      sync();
    });
  }

  function start() {
    settings.name = $('#nameInput').value;
    settings.voice = $('#voiceInput').checked;
    settings.auto = $('#autoInput').checked;
    store.set('housey.settings', settings);
    sound.init();
    $('#setup').classList.add('hidden');
    $('#results').classList.add('hidden');
    newGame();
  }

  function openSetup() {
    clearTimers();
    if (game) game.paused = true;
    $('#results').classList.add('hidden');
    $('#setup').classList.remove('hidden');
  }

  // ---------- Wire up ----------
  $('#startBtn').addEventListener('click', start);
  $('#againBtn').addEventListener('click', start);
  $('#settingsBtn').addEventListener('click', openSetup);
  $('#newBtn').addEventListener('click', openSetup);
  $('#bag').addEventListener('click', () => {
    if (!game || game.over) return;
    sound.init();
    if (settings.speed === 0) drawNext();
    else if (game.paused) togglePause();
  });
  function togglePause() {
    if (!game || game.over || settings.speed === 0) return;
    game.paused = !game.paused;
    if (game.paused) { clearTimeout(drawTimer); setCall('Paused — take a breather', null); window.speechSynthesis?.cancel(); }
    else { setCall('Here we go…', null); scheduleDraw(1200); }
    updatePauseBtn();
  }
  $('#pauseBtn').addEventListener('click', togglePause);
  const soundBtn = $('#soundBtn');
  const syncSound = () => { soundBtn.textContent = sound.on ? '🔊' : '🔇'; };
  soundBtn.addEventListener('click', () => {
    sound.on = !sound.on; store.set('housey.sound', sound.on); syncSound();
    if (!sound.on && 'speechSynthesis' in window) speechSynthesis.cancel();
    sound.init();
  });
  syncSound();
  document.addEventListener('visibilitychange', () => { if (document.visibilityState === 'visible' && game && !game.over) requestWakeLock(); });
  document.addEventListener('keydown', e => {
    if (!$('#setup').classList.contains('hidden')) { if (e.key === 'Enter') start(); return; }
    if (e.key === ' ' && e.target === document.body) { e.preventDefault(); settings.speed === 0 ? drawNext() : togglePause(); }
  });

  $('#boardBox').open = window.matchMedia('(min-width: 901px)').matches;
  initSetup();
  // Preview tickets behind the setup card so the table never looks empty
  game = { players: [], me: { tickets: [makeTicket()] }, calledSet: new Set(), prizes: {}, over: true };
  renderTickets(); renderBoard(); renderClaims();
  $('#players').innerHTML = '';

  // Offline support: cache the game so it opens without a connection.
  if ('serviceWorker' in navigator && location.protocol !== 'file:') {
    window.addEventListener('load', () => navigator.serviceWorker.register('sw.js').catch(() => {}));
  }
})();
