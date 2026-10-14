// Options for printed ticket sheets: colours, page layouts and presets.
// The same choices as js/core/print-options.js on the website.

const maxPrintTickets = 600;

class PrintTheme {
  const PrintTheme(this.key, this.label, this.color);
  final String key;
  final String label;

  /// 0xAARRGGBB.
  final int color;
}

const printThemes = <PrintTheme>[
  PrintTheme('classic', 'Classic red', 0xFFB3261E),
  PrintTheme('blue', 'Royal blue', 0xFF1F4E9C),
  PrintTheme('green', 'Festive green', 0xFF1E7A46),
  PrintTheme('purple', 'Purple', 0xFF6A2C91),
  PrintTheme('marigold', 'Marigold', 0xFFC8641A),
  PrintTheme('pink', 'Pink', 0xFFC2185B),
  PrintTheme('ink', 'Ink saver (black)', 0xFF222222),
];

/// Theme key for a different colour on each ticket.
const mixedTheme = 'mix';

/// Tickets per A4 page and how they're arranged.
class PageLayout {
  const PageLayout(this.key, this.label, this.perPage, this.columns);
  final String key;
  final String label;
  final int perPage;
  final int columns;
}

const pageLayouts = <PageLayout>[
  PageLayout('large', '4 large', 4, 1),
  PageLayout('standard', '6', 6, 1),
  PageLayout('compact', '12 small', 12, 2),
];

PageLayout layoutByKey(String key) => pageLayouts.firstWhere((l) => l.key == key, orElse: () => pageLayouts[1]);

class PrintOptions {
  const PrintOptions({
    this.count = 6,
    this.layout = 'standard',
    this.theme = 'classic',
    this.title = 'Housey',
    this.footer = '',
    this.startNumber = 1,
    this.showQr = true,
  });

  /// Fills in and range-checks options from storage or a form.
  factory PrintOptions.fromJson(Map<String, Object?> json) {
    const d = PrintOptions();
    int intOf(Object? v, int lo, int hi, int fallback) {
      final n = v is num ? v.round() : int.tryParse('$v');
      return n == null ? fallback : n.clamp(lo, hi);
    }

    final theme = json['theme'];
    final layout = json['layout'];
    return PrintOptions(
      count: intOf(json['count'], 1, maxPrintTickets, d.count),
      layout: pageLayouts.any((l) => l.key == layout) ? layout as String : d.layout,
      theme: theme == mixedTheme || printThemes.any((t) => t.key == theme) ? theme as String : d.theme,
      title: _cut(json['title'] as String? ?? d.title, 40),
      footer: _cut(json['footer'] as String? ?? d.footer, 60),
      startNumber: intOf(json['startNumber'], 1, 99999, d.startNumber),
      showQr: json['showQr'] as bool? ?? d.showQr,
    );
  }

  final int count;
  final String layout;
  final String theme;
  final String title;
  final String footer;
  final int startNumber;
  final bool showQr;

  Map<String, Object> toJson() => {
    'count': count,
    'layout': layout,
    'theme': theme,
    'title': title,
    'footer': footer,
    'startNumber': startNumber,
    'showQr': showQr,
  };

  /// A copy with some options changed, checked the same way as loaded ones.
  PrintOptions merge(Map<String, Object?> changes) => PrintOptions.fromJson({...toJson(), ...changes});

  PageLayout get pageLayout => layoutByKey(layout);

  /// The ink colour for the ticket at [index] (0-based).
  int colorFor(int index) {
    if (theme == mixedTheme) {
      final colourful = printThemes.where((t) => t.key != 'ink').toList();
      return colourful[index % colourful.length].color;
    }
    return printThemes.firstWhere((t) => t.key == theme, orElse: () => printThemes.first).color;
  }
}

String _cut(String s, int max) => s.length <= max ? s : s.substring(0, max);

class PrintPreset {
  const PrintPreset(this.label, this.hint, this.options);
  final String label;
  final String hint;
  final Map<String, Object> options;
}

const printPresets = <PrintPreset>[
  PrintPreset('Family night', '6 tickets', {
    'count': 6,
    'layout': 'large',
    'theme': 'classic',
    'title': 'Family Housey Night',
  }),
  PrintPreset('Kitty party', '24, mixed colours', {
    'count': 24,
    'layout': 'standard',
    'theme': mixedTheme,
    'title': 'Kitty Party Tambola',
  }),
  PrintPreset('Diwali / festival', '60, marigold', {
    'count': 60,
    'layout': 'compact',
    'theme': 'marigold',
    'title': 'Diwali Tambola',
  }),
  PrintPreset('Office event', '100, mixed colours', {
    'count': 100,
    'layout': 'compact',
    'theme': mixedTheme,
    'title': 'Office Tambola',
  }),
  PrintPreset('Ink saver', '36, black only', {'count': 36, 'layout': 'compact', 'theme': 'ink', 'title': 'Housey'}),
];

/// Splits [items] into pages of [perPage].
List<List<T>> paginate<T>(List<T> items, int perPage) => [
  for (var i = 0; i < items.length; i += perPage)
    items.sublist(i, i + perPage > items.length ? items.length : i + perPage),
];
