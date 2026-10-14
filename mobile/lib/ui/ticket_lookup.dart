import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../core/tickets.dart';
import '../services/ticket_service.dart';
import 'look.dart';

/// "Open a ticket": type a ticket code or scan its QR code.
class TicketLookup extends StatefulWidget {
  const TicketLookup({super.key, required this.onTicket, this.buttonLabel = 'Open'});
  final ValueChanged<Ticket> onTicket;
  final String buttonLabel;

  @override
  State<TicketLookup> createState() => _TicketLookupState();
}

class _TicketLookupState extends State<TicketLookup> {
  final _code = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _open(String text) async {
    final ticket = await findTicket(text);
    if (!mounted) return;
    if (ticket == null) {
      setState(() => _error = "That code doesn't look right. Check it against the ticket and try again.");
      return;
    }
    setState(() => _error = null);
    _code.clear();
    FocusScope.of(context).unfocus();
    widget.onTicket(ticket);
  }

  Future<void> _scan() async {
    final text = await Navigator.of(context).push<String>(MaterialPageRoute(builder: (_) => const ScanScreen()));
    if (text != null) await _open(text);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _code,
                textCapitalization: TextCapitalization.characters,
                autocorrect: false,
                enableSuggestions: false,
                textInputAction: TextInputAction.go,
                onSubmitted: _open,
                style: const TextStyle(fontFamily: Fonts.mono, fontSize: 17, letterSpacing: 1, color: Palette.ink),
                decoration: InputDecoration(
                  hintText: 'Ticket code, e.g. HNZV-C92Z',
                  hintStyle: TextStyle(fontFamily: Fonts.slab, fontSize: 15, color: Palette.ink.withValues(alpha: .5)),
                  isDense: true,
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: .6),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Palette.ink, width: 2)),
                  focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Palette.ticketRed, width: 2)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Palette.ink, foregroundColor: Palette.paper),
              onPressed: () => _open(_code.text),
              child: Text(widget.buttonLabel),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Palette.ink,
              side: const BorderSide(color: Palette.ink, width: 2),
            ),
            onPressed: _scan,
            icon: const Icon(Icons.qr_code_scanner_rounded),
            label: const Text('Scan QR code'),
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _error!,
              style: const TextStyle(color: Palette.ticketRed, fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
      ],
    );
  }
}

/// The camera, looking for a ticket's QR code. Pops with the text it read.
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _controller = MobileScannerController(formats: const [BarcodeFormat.qrCode]);
  var _done = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    final text = capture.barcodes.map((b) => b.rawValue).nonNulls.firstOrNull;
    if (text == null || _done) return;
    _done = true;
    Navigator.of(context).pop(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Palette.cream, title: const Text('Scan a ticket')),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  "The camera isn't available. Allow camera access in Settings, or type the code from the ticket.",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Palette.cream, fontSize: 16),
                ),
              ),
            ),
          ),
          IgnorePointer(
            child: Center(
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  border: Border.all(color: Palette.brass, width: 3),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const Positioned(
            left: 24,
            right: 24,
            bottom: 40,
            child: Text(
              'Point the camera at the QR code on a ticket',
              textAlign: TextAlign.center,
              style: TextStyle(color: Palette.cream, fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
