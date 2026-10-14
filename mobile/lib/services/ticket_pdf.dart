// Printable ticket sheets as an A4 PDF: the same design as the website's print page.

import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../core/print_options.dart';
import '../core/tickets.dart';
import 'ticket_service.dart';

/// Fonts for the PDF. Without them the PDF uses the built-in Helvetica.
class PdfFonts {
  const PdfFonts({this.display, this.body, this.mono});
  final pw.Font? display, body, mono;
}

/// Sizes for each page layout, in millimetres (font sizes in points).
class _Metrics {
  const _Metrics({
    required this.cell,
    required this.number,
    required this.title,
    required this.small,
    required this.qr,
    required this.gap,
    required this.pad,
  });
  final double cell, number, title, small, qr, gap, pad;
}

const _metrics = {
  'large': _Metrics(cell: 13, number: 22, title: 15, small: 9, qr: 28, gap: 8, pad: 3.5),
  'standard': _Metrics(cell: 8.5, number: 16, title: 12, small: 8, qr: 22, gap: 5, pad: 2.5),
  'compact': _Metrics(cell: 6.5, number: 10, title: 9, small: 6, qr: 14, gap: 4, pad: 1.8),
};

const _mm = PdfPageFormat.mm;

PdfColor _tint(int argb, double amount) {
  final c = PdfColor.fromInt(argb);
  return PdfColor(1 - (1 - c.red) * amount, 1 - (1 - c.green) * amount, 1 - (1 - c.blue) * amount);
}

/// Builds the PDF for [tickets], [options.pageLayout.perPage] to an A4 page.
Future<Uint8List> buildTicketsPdf(List<Ticket> tickets, PrintOptions options, {PdfFonts fonts = const PdfFonts()}) {
  final layout = options.pageLayout;
  final m = _metrics[layout.key]!;
  final doc = pw.Document(title: options.title.isEmpty ? 'Housey tickets' : options.title, author: 'Housey');

  pw.Widget ticketBox(Ticket t, int index) {
    final color = PdfColor.fromInt(options.colorFor(index));
    final empty = _tint(options.colorFor(index), .16);
    final grid = pw.Table(
      defaultColumnWidth: const pw.FlexColumnWidth(),
      border: pw.TableBorder.all(color: color, width: .35 * _mm),
      children: [
        for (final row in t.grid)
          pw.TableRow(
            children: [
              for (final n in row)
                pw.Container(
                  height: m.cell * _mm,
                  color: n == 0 ? empty : PdfColors.white,
                  alignment: pw.Alignment.center,
                  child: n == 0
                      ? null
                      : pw.Text(
                          '$n',
                          style: pw.TextStyle(font: fonts.body, fontWeight: pw.FontWeight.bold, fontSize: m.number),
                        ),
                ),
            ],
          ),
      ],
    );
    return pw.Container(
      padding: pw.EdgeInsets.all(m.pad * _mm),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color, width: .6 * _mm),
        borderRadius: pw.BorderRadius.circular(2 * _mm),
      ),
      child: pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Text(
                  options.title.isEmpty ? 'Housey' : options.title,
                  maxLines: 1,
                  style: pw.TextStyle(font: fonts.display, color: color, fontSize: m.title),
                ),
              ),
              pw.Text(
                'TICKET ${options.startNumber + index}',
                style: pw.TextStyle(font: fonts.body, fontWeight: pw.FontWeight.bold, fontSize: m.small),
              ),
            ],
          ),
          pw.SizedBox(height: m.pad * .6 * _mm),
          // Explicit widths rather than Expanded: the pdf package's layout check trips over
          // floating-point rounding when an Expanded grid sits beside the QR code.
          pw.LayoutBuilder(
            builder: (context, constraints) {
              final qrWidth = options.showQr ? (m.qr + m.pad) * _mm : 0.0;
              return pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.SizedBox(width: constraints!.maxWidth - qrWidth - .5, child: grid),
                  if (options.showQr)
                    pw.SizedBox(
                      width: qrWidth,
                      child: pw.Column(
                        mainAxisSize: pw.MainAxisSize.min,
                        children: [
                          pw.BarcodeWidget(
                            barcode: pw.Barcode.qrCode(),
                            data: ticketLink(t.code),
                            width: m.qr * _mm,
                            height: m.qr * _mm,
                          ),
                          pw.SizedBox(height: .8 * _mm),
                          pw.Text(
                            t.code,
                            style: pw.TextStyle(font: fonts.mono, fontSize: m.small),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
          if (options.footer.isNotEmpty) ...[
            pw.SizedBox(height: m.pad * .5 * _mm),
            pw.Text(
              options.footer,
              textAlign: pw.TextAlign.center,
              // Roboto Slab has no ₹ sign; Alfa Slab One does.
              style: pw.TextStyle(
                font: fonts.body,
                fontFallback: [?fonts.display],
                fontSize: m.small,
                color: PdfColors.grey800,
              ),
            ),
          ],
        ],
      ),
    );
  }

  final pages = paginate(List.generate(tickets.length, (i) => i), layout.perPage);
  for (final page in pages) {
    final boxes = [for (final i in page) ticketBox(tickets[i], i)];
    final rowsOfBoxes = paginate(boxes, layout.columns);
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(10 * _mm),
        build: (_) => pw.Column(
          children: [
            for (var r = 0; r < rowsOfBoxes.length; r++) ...[
              if (r > 0) pw.SizedBox(height: m.gap * _mm),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  for (var c = 0; c < layout.columns; c++) ...[
                    if (c > 0) pw.SizedBox(width: 6 * _mm),
                    pw.Expanded(child: c < rowsOfBoxes[r].length ? rowsOfBoxes[r][c] : pw.SizedBox()),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
  return doc.save();
}
