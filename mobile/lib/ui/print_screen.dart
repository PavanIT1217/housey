import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../app_services.dart';
import '../core/print_options.dart';
import '../core/tickets.dart';
import '../services/storage.dart';
import '../services/ticket_pdf.dart';
import 'controls.dart';
import 'look.dart';
import 'tool_scaffold.dart';

/// Printable tickets: choose how many, the colours and layout (or a preset),
/// then print or share a PDF. Each ticket has a code and a QR code.
class PrintScreen extends StatefulWidget {
  const PrintScreen({super.key, required this.services});
  final AppServices services;

  @override
  State<PrintScreen> createState() => _PrintScreenState();
}

class _PrintScreenState extends State<PrintScreen> {
  late final JsonRecord _record = widget.services.printOptions;
  late PrintOptions _options;
  late List<Ticket> _tickets;

  late final _title = TextEditingController();
  late final _footer = TextEditingController();
  late final _count = TextEditingController();
  late final _start = TextEditingController();

  @override
  void initState() {
    super.initState();
    final saved = _record.load();
    final map = saved is Map ? saved : const {};
    _options = PrintOptions.fromJson(map['options'] is Map ? Map<String, Object?>.from(map['options'] as Map) : {});
    _tickets = [
      for (final code in (map['codes'] is List ? map['codes'] as List : const [])) ?ticketFromCode(code as String?),
    ];
    _matchCount();
    _syncFields();
  }

  @override
  void dispose() {
    for (final c in [_title, _footer, _count, _start]) {
      c.dispose();
    }
    super.dispose();
  }

  void _matchCount() {
    if (_tickets.length > _options.count) {
      _tickets = _tickets.sublist(0, _options.count);
    } else if (_tickets.length < _options.count) {
      final have = _tickets.map((t) => t.code).toSet();
      _tickets.addAll(createTickets(_options.count - _tickets.length).where((t) => have.add(t.code)));
    }
    _record.save({'options': _options.toJson(), 'codes': _tickets.map((t) => t.code).toList()});
  }

  void _syncFields() {
    _title.text = _options.title;
    _footer.text = _options.footer;
    _count.text = '${_options.count}';
    _start.text = '${_options.startNumber}';
  }

  void _update(Map<String, Object?> changes, {bool regenerate = false, bool syncFields = false}) {
    setState(() {
      _options = _options.merge(changes);
      if (regenerate) _tickets = [];
      _matchCount();
      if (syncFields) _syncFields();
    });
  }

  Future<PdfFonts> _fonts() async {
    Future<pw.Font> load(String file) async => pw.Font.ttf(await rootBundle.load('assets/fonts/$file'));
    return PdfFonts(
      display: await load('AlfaSlabOne-Regular.ttf'),
      body: await load('RobotoSlab.ttf'),
      mono: await load('CourierPrime-Bold.ttf'),
    );
  }

  void _preview() {
    final tickets = List.of(_tickets), options = _options;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            backgroundColor: const Color(0xFF1D0F05),
            foregroundColor: Palette.cream,
            title: const Text('Print or share'),
          ),
          body: PdfPreview(
            build: (_) async => buildTicketsPdf(tickets, options, fonts: await _fonts()),
            initialPageFormat: PdfPageFormat.a4,
            canChangePageFormat: false,
            canChangeOrientation: false,
            canDebug: false,
            pdfFileName: 'housey-tickets.pdf',
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = (_tickets.length / _options.pageLayout.perPage).ceil();
    return ToolScaffold(
      title: 'Print tickets',
      children: [
        Panel(
          title: 'Print Tambola tickets',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const FieldLabel('Start from a preset'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final p in printPresets)
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Palette.ink,
                        side: const BorderSide(color: Palette.ink, width: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onPressed: () => _update(p.options, regenerate: true, syncFields: true),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.label, style: const TextStyle(fontWeight: FontWeight.w800)),
                          Text(p.hint, style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              _NumberField(
                label: 'Number of tickets',
                controller: _count,
                onDone: (v) => _update({'count': v}, syncFields: true),
              ),
              const SizedBox(height: 14),
              const FieldLabel('Tickets per page'),
              Segments<String>(
                options: {for (final l in pageLayouts) l.key: l.label},
                value: _options.layout,
                onChanged: (l) => _update({'layout': l}),
              ),
              const SizedBox(height: 14),
              const FieldLabel('Colour'),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final t in printThemes)
                    _Swatch(
                      label: t.label,
                      colors: [Color(t.color)],
                      selected: _options.theme == t.key,
                      onTap: () => _update({'theme': t.key}),
                    ),
                  _Swatch(
                    label: 'Mixed colours',
                    colors: [for (final t in printThemes.where((t) => t.key != 'ink')) Color(t.color)],
                    selected: _options.theme == mixedTheme,
                    onTap: () => _update({'theme': mixedTheme}),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _TextField(label: 'Title on each ticket', controller: _title, onChanged: (v) => _update({'title': v})),
              const SizedBox(height: 14),
              _TextField(
                label: 'Footer line (optional)',
                hint: 'e.g. ₹20 a ticket · Sunday 7 pm',
                controller: _footer,
                onChanged: (v) => _update({'footer': v}),
              ),
              const SizedBox(height: 14),
              _NumberField(
                label: 'First ticket number',
                controller: _start,
                onDone: (v) => _update({'startNumber': v}, syncFields: true),
              ),
              CheckToggle(
                label: 'QR code and ticket code',
                value: _options.showQr,
                onChanged: (v) => _update({'showQr': v}),
              ),
              const SizedBox(height: 10),
              BigButton(label: 'Print or share PDF', onPressed: _preview),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Note(
                      '${_tickets.length} ticket${_tickets.length == 1 ? '' : 's'} on $pages A4 page${pages == 1 ? '' : 's'}.',
                    ),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(foregroundColor: Palette.ticketRed),
                    onPressed: () {
                      _update({}, regenerate: true);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('New tickets made')));
                    },
                    child: const Text('Make new tickets'),
                  ),
                ],
              ),
              const Note(
                'Every ticket is different. Players can scan the QR code to play the ticket on their phone, '
                'and the number caller can check any ticket by its code.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

InputDecoration _decoration({String? hint}) => InputDecoration(
  hintText: hint,
  isDense: true,
  filled: true,
  fillColor: Colors.white.withValues(alpha: .6),
  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Palette.ink, width: 2)),
  focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Palette.ticketRed, width: 2)),
);

class _TextField extends StatelessWidget {
  const _TextField({required this.label, required this.controller, required this.onChanged, this.hint});
  final String label;
  final String? hint;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      FieldLabel(label),
      TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(color: Palette.ink, fontSize: 16),
        decoration: _decoration(hint: hint),
      ),
    ],
  );
}

class _NumberField extends StatelessWidget {
  const _NumberField({required this.label, required this.controller, required this.onDone});
  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onDone;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      FieldLabel(label),
      Focus(
        onFocusChange: (focused) {
          if (!focused) onDone(controller.text);
        },
        child: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onSubmitted: onDone,
          style: const TextStyle(color: Palette.ink, fontSize: 16),
          decoration: _decoration(),
        ),
      ),
    ],
  );
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.label, required this.colors, required this.selected, required this.onTap});
  final String label;
  final List<Color> colors;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: label,
    child: Tooltip(
      message: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors.length == 1 ? colors.first : null,
            gradient: colors.length > 1 ? SweepGradient(colors: [...colors, colors.first]) : null,
            border: Border.all(color: Palette.paper, width: 3),
            boxShadow: [
              BoxShadow(
                color: selected ? Palette.ink : Palette.ink.withValues(alpha: .35),
                spreadRadius: selected ? 3 : 2,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
