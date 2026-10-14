// "Open a ticket" box: type a ticket code or scan its QR code.

import { findTicket } from '../services/ticket-service.js';
import { scanQrCode } from './qr.js';
import { el, toast } from './dom.js';

/**
 * Builds the lookup form in `container`. Calls `onTicket(ticket)` with each
 * ticket found; shows a message when a code isn't valid.
 */
export function mountTicketLookup(container, { buttonLabel = 'Open', onTicket }) {
  const form = el('form', 'lookup');
  const input = el('input');
  Object.assign(input, {
    type: 'text', placeholder: 'Ticket code, e.g. HNZV-C92Z', autocomplete: 'off',
    autocapitalize: 'characters', spellcheck: false, maxLength: 120,
  });
  input.setAttribute('aria-label', 'Ticket code');
  const submit = el('button', 'small-btn', buttonLabel);
  const scan = el('button', 'small-btn ghost', '📷 Scan QR');
  scan.type = 'button';
  const error = el('p', 'lookup-error');
  error.setAttribute('role', 'alert');
  form.append(input, submit, scan, error);

  const open = async text => {
    const ticket = await findTicket(text);
    if (!ticket) {
      error.textContent = "That code doesn't look right. Check it against the ticket and try again.";
      return;
    }
    error.textContent = '';
    input.value = '';
    onTicket(ticket);
  };

  form.addEventListener('submit', e => {
    e.preventDefault();
    if (input.value.trim()) open(input.value);
  });
  scan.addEventListener('click', async () => {
    try {
      const text = await scanQrCode();
      if (text) open(text);
    } catch {
      toast("The camera isn't available here. Type the code from the ticket instead.");
    }
  });

  container.replaceChildren(form);
  return { open };
}
