// Ticket codes: short, typeable IDs like "HNZV-C92Z" printed on every ticket.
// The same format and rules as js/core/ticket-code.js: 7 data symbols and a
// check symbol in Crockford base32, so a mistyped code is rejected instead of
// opening someone else's ticket.

import 'dart:math';

import 'random.dart';

const _alphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';
const _dataLength = 7;
const codeLength = _dataLength + 1;

String _checkSymbol(String data) => _alphabet[hashString('check:$data')[0] % _alphabet.length];
String _format(String raw) => '${raw.substring(0, 4)}-${raw.substring(4)}';

/// Makes a new random ticket code, e.g. "HNZV-C92Z".
String createTicketCode([RandomSource? rnd]) {
  final source = rnd ?? fromRandom(Random.secure());
  final data = StringBuffer();
  for (var i = 0; i < _dataLength; i++) {
    data.write(_alphabet[randomInt(_alphabet.length, source)]);
  }
  return _format('$data${_checkSymbol(data.toString())}');
}

/// Cleans up a typed code and checks it. Accepts any case, spaces and dashes,
/// and the look-alikes O (for 0) and I/L (for 1). Returns the printed form, or null.
String? normalizeTicketCode(String? input) {
  final raw = (input ?? '')
      .toUpperCase()
      .replaceAll(RegExp(r'[\s-]'), '')
      .replaceAll('O', '0')
      .replaceAll(RegExp('[IL]'), '1');
  if (raw.length != codeLength || raw.split('').any((ch) => !_alphabet.contains(ch))) return null;
  return raw[_dataLength] == _checkSymbol(raw.substring(0, _dataLength)) ? _format(raw) : null;
}

/// Finds a ticket code in scanned or pasted text: a ticket link or a bare code.
String? extractTicketCode(String? text) {
  final value = (text ?? '').trim();
  final uri = Uri.tryParse(value);
  if (uri != null && uri.hasScheme && uri.host.isNotEmpty) {
    final fromLink = uri.queryParameters['t'] ?? Uri.splitQueryString(uri.fragment)['t'];
    if (fromLink != null) return normalizeTicketCode(fromLink);
  }
  return normalizeTicketCode(value);
}
