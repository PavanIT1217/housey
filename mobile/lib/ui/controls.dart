import 'package:flutter/material.dart';

import 'look.dart';

/// Title style for paper cards.
const cardTitle = TextStyle(fontFamily: Fonts.display, color: Palette.ticketRed, fontSize: 26);

/// A sheet of paper dealt onto the table, used for the setup and results.
class PaperCard extends StatelessWidget {
  const PaperCard({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutBack,
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0, 1),
        child: Transform.translate(
          offset: Offset(0, 40 * (1 - t)),
          child: Transform.rotate(angle: -.07 * (1 - t), child: child),
        ),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment(-.2, -1),
              end: Alignment(.2, 1),
              colors: [Color(0xFFFBF6E8), Palette.paper, Color(0xFFEFE4C7)],
            ),
            borderRadius: BorderRadius.circular(6),
            boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 50, offset: Offset(0, 20))],
          ),
          child: CustomPaint(
            painter: const NoisePainter(seed: 21),
            child: Material(
              type: MaterialType.transparency,
              child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(22, 22, 22, 18), child: child),
            ),
          ),
        ),
      ),
    );
  }
}

/// A small capitalised label above a form field.
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        letterSpacing: 1.5,
        fontWeight: FontWeight.w600,
        color: Palette.ink.withValues(alpha: .7),
      ),
    ),
  );
}

/// A row of choices, one picked.
class Segments<T> extends StatelessWidget {
  const Segments({super.key, required this.options, required this.value, required this.onChanged});
  final Map<T, String> options;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final entries = options.entries.toList();
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Palette.ink, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          children: [
            for (var i = 0; i < entries.length; i++) ...[
              if (i > 0) const VerticalDivider(width: 1.5, thickness: 1.5, color: Palette.ink),
              Expanded(
                child: Semantics(
                  selected: entries[i].key == value,
                  button: true,
                  child: InkWell(
                    onTap: () => onChanged(entries[i].key),
                    child: Container(
                      color: entries[i].key == value ? Palette.ink : Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
                      alignment: Alignment.center,
                      child: Text(
                        entries[i].value,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: entries[i].key == value ? Palette.paper : Palette.ink,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A checkbox with its label.
class CheckToggle extends StatelessWidget {
  const CheckToggle({super.key, required this.label, required this.value, required this.onChanged});
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => onChanged(!value),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
          value: value,
          onChanged: (v) => onChanged(v ?? false),
          activeColor: Palette.ticketRed,
          side: const BorderSide(color: Palette.ink, width: 2),
          visualDensity: VisualDensity.compact,
        ),
        Flexible(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Palette.ink),
          ),
        ),
      ],
    ),
  );
}

class BigButton extends StatefulWidget {
  const BigButton({super.key, required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;

  @override
  State<BigButton> createState() => _BigButtonState();
}

class _BigButtonState extends State<BigButton> {
  var _down = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _down = true),
        onTapUp: (_) => setState(() => _down = false),
        onTapCancel: () => setState(() => _down = false),
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          transform: Matrix4.translationValues(0, _down ? 3 : 0, 0),
          padding: const EdgeInsets.all(14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFD23A2F), Color(0xFF9E1F17)],
            ),
            boxShadow: [
              BoxShadow(color: const Color(0xFF5E0F0A), offset: Offset(0, _down ? 1 : 4)),
              BoxShadow(color: const Color(0x59000000), blurRadius: _down ? 6 : 14, offset: Offset(0, _down ? 3 : 8)),
            ],
          ),
          child: Text(
            widget.label,
            style: const TextStyle(fontFamily: Fonts.display, fontSize: 20, letterSpacing: 1, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
