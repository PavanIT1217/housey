// "My tickets": open a printed ticket on the phone by its code or QR code and
// dab it there. Tickets and dabs are kept on the device.

import { $, el, registerServiceWorker, toast, vibrate } from '../ui/dom.js';
import { addDab, cellFor, removeDab, renderTicket } from '../ui/ticket-view.js';
import { findTicket, ticketLink } from '../services/ticket-service.js';
import { mountTicketLookup } from '../ui/ticket-lookup.js';
import { myTicketsRecord } from '../services/storage.js';
import { sound } from '../services/sound.js';
import { ticketFromCode } from '../core/tickets.js';

/** Tickets on this device, newest first: { code, grid, dabs: Set }. */
let tickets = (myTicketsRecord.load() ?? [])
  .map(saved => {
    const ticket = ticketFromCode(saved.code);
    return ticket && { ...ticket, dabs: new Set(saved.dabs) };
  })
  .filter(Boolean);

const save = () => myTicketsRecord.save(tickets.map(t => ({ code: t.code, dabs: [...t.dabs] })));

function addTicket(ticket) {
  if (!tickets.some(t => t.code === ticket.code)) {
    tickets.unshift({ ...ticket, dabs: new Set() });
    save();
    render();
  }
  const tk = $(`.my-ticket[data-code="${ticket.code}"]`);
  tk?.scrollIntoView({ behavior: 'smooth', block: 'center' });
  tk?.classList.add('flash');
  setTimeout(() => tk?.classList.remove('flash'), 1600);
}

function toggleDab(ticket, n, cell) {
  sound.init();
  if (ticket.dabs.has(n)) {
    ticket.dabs.delete(n);
    removeDab(cell);
  } else {
    ticket.dabs.add(n);
    addDab(cell, true);
    sound.dab();
    vibrate(15);
  }
  save();
}

function actionButton(label, onClick) {
  const b = el('button', 'small-btn ghost', label);
  b.type = 'button';
  b.addEventListener('click', onClick);
  return b;
}

function render() {
  const wrap = $('#myTickets');
  wrap.innerHTML = '';
  $('#emptyState').hidden = tickets.length > 0;
  tickets.forEach(ticket => {
    const item = el('div', 'my-ticket');
    item.dataset.code = ticket.code;
    const tk = renderTicket(ticket, { heading: 'Tap to dab', onCellClick: (n, cell) => toggleDab(ticket, n, cell) });
    ticket.dabs.forEach(n => addDab(cellFor(tk, n)));

    const actions = el('div', 'ticket-actions');
    actions.append(
      actionButton('Clear dabs', () => {
        ticket.dabs.clear();
        save();
        render();
      }),
      actionButton('Copy link', async () => {
        try {
          await navigator.clipboard.writeText(ticketLink(ticket.code));
          toast('Link copied');
        } catch {
          toast(ticketLink(ticket.code));
        }
      }),
      actionButton('Remove', () => {
        tickets = tickets.filter(t => t !== ticket);
        save();
        render();
      }),
    );
    item.append(tk, actions);
    wrap.append(item);
  });
}

mountTicketLookup($('#lookup'), { onTicket: addTicket });
render();

// Opened from a QR code or link: ticket.html?t=HNZV-C92Z
const fromLink = new URLSearchParams(location.search).get('t');
if (fromLink) {
  findTicket(fromLink).then(ticket => {
    if (ticket) addTicket(ticket);
    else toast("That ticket link isn't valid. Type the code from the ticket instead.");
    history.replaceState(null, '', location.pathname);
  });
}
registerServiceWorker();
