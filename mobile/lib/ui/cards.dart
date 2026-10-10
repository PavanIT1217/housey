import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../game/controller.dart';
import '../game/rules.dart';
import 'look.dart';

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

const _cardTitle = TextStyle(fontFamily: Fonts.display, color: Palette.ticketRed, fontSize: 26);

class SetupCard extends StatefulWidget {
  const SetupCard({super.key, required this.game});
  final GameController game;

  @override
  State<SetupCard> createState() => _SetupCardState();
}

class _SetupCardState extends State<SetupCard> {
  late final _name = TextEditingController(text: widget.game.settings.name);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _start() {
    widget.game.settings.name = _name.text;
    FocusScope.of(context).unfocus();
    widget.game.start();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.game.settings;
    return PaperCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text("Let's play Housey", textAlign: TextAlign.center, style: _cardTitle),
          const SizedBox(height: 16),
          const _Label('Your name'),
          TextField(
            controller: _name,
            maxLength: 14,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.go,
            onSubmitted: (_) => _start(),
            style: const TextStyle(fontSize: 17, color: Palette.ink),
            decoration: InputDecoration(
              hintText: 'You',
              counterText: '',
              isDense: true,
              filled: true,
              fillColor: Colors.white.withValues(alpha: .6),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Palette.ink, width: 2)),
              focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Palette.ticketRed, width: 2)),
            ),
          ),
          const SizedBox(height: 14),
          const _Label('Tickets'),
          _Segments(
            options: const {1: '1', 2: '2', 3: '3'},
            value: s.tickets,
            onChanged: (v) => setState(() => s.tickets = v),
          ),
          const SizedBox(height: 14),
          const _Label('Players at the table'),
          _Segments(
            options: const {0: 'Just me', 2: '+2', 4: '+4', 6: '+6'},
            value: s.bots,
            onChanged: (v) => setState(() => s.bots = v),
          ),
          const SizedBox(height: 14),
          const _Label('Calling speed'),
          _Segments(
            options: const {8000: 'Relaxed', 5500: 'Normal', 3500: 'Quick', 0: "I'll tap"},
            value: s.speed,
            onChanged: (v) => setState(() => s.speed = v),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 16,
            children: [
              _Toggle(label: "Caller's voice", value: s.voice, onChanged: (v) => setState(() => s.voice = v)),
              _Toggle(label: 'Auto-dab for me', value: s.auto, onChanged: (v) => setState(() => s.auto = v)),
            ],
          ),
          const SizedBox(height: 10),
          BigButton(label: 'Deal tickets', onPressed: _start),
          const SizedBox(height: 6),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: const ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.only(bottom: 4),
              iconColor: Palette.ink,
              collapsedIconColor: Palette.ink,
              title: Text(
                'How to play',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Palette.ink),
              ),
              children: [_Rules()],
            ),
          ),
          const _InfoLinks(),
        ],
      ),
    );
  }
}

/// Support, privacy policy and terms, on the website.
class _InfoLinks extends StatelessWidget {
  const _InfoLinks();

  static const _site = 'https://housey.webappslab.com/';

  @override
  Widget build(BuildContext context) {
    Widget link(String label, String page) => TextButton(
      onPressed: () => launchUrl(Uri.parse('$_site$page'), mode: LaunchMode.externalApplication),
      style: TextButton.styleFrom(
        foregroundColor: Palette.ink.withValues(alpha: .75),
        textStyle: const TextStyle(fontSize: 13, decoration: TextDecoration.underline),
        visualDensity: VisualDensity.compact,
      ),
      child: Text(label),
    );
    return Wrap(
      alignment: WrapAlignment.center,
      children: [link('Support', 'support.html'), link('Privacy', 'privacy.html'), link('Terms', 'terms.html')],
    );
  }
}

class _Rules extends StatelessWidget {
  const _Rules();

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(fontSize: 14, height: 1.5, color: Palette.ink);
    const bold = TextStyle(fontWeight: FontWeight.w800);
    Widget item(List<InlineSpan> spans) => Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  ', style: style),
          Expanded(
            child: Text.rich(TextSpan(children: spans), style: style),
          ),
        ],
      ),
    );
    return Column(
      children: [
        item(const [TextSpan(text: 'Numbers 1–90 are pulled from the bag one at a time and called out.')]),
        item(const [TextSpan(text: 'If the number is on your ticket, tap it to dab it with ink.')]),
        item(const [
          TextSpan(text: 'Early Five', style: bold),
          TextSpan(text: ': first 5 numbers dabbed on a ticket. '),
          TextSpan(text: 'Top / Middle / Bottom Line', style: bold),
          TextSpan(text: ': every number in that row. '),
          TextSpan(text: 'Full House', style: bold),
          TextSpan(text: ': all 15 numbers.'),
        ]),
        item(const [
          TextSpan(
            text: 'Press the prize button to claim it. Claim a prize you haven\'t got and the caller shouts “Bogey!”.',
          ),
        ]),
        item(const [TextSpan(text: 'The game ends when someone wins Full House.')]),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
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

class _Segments extends StatelessWidget {
  const _Segments({required this.options, required this.value, required this.onChanged});
  final Map<int, String> options;
  final int value;
  final ValueChanged<int> onChanged;

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

class _Toggle extends StatelessWidget {
  const _Toggle({required this.label, required this.value, required this.onChanged});
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
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Palette.ink),
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

class ResultsCard extends StatelessWidget {
  const ResultsCard({super.key, required this.game});
  final GameController game;

  @override
  Widget build(BuildContext context) {
    final ranked = game.ranked;
    final top = ranked.first;
    final title = top.points == 0
        ? 'Game over'
        : top.human
        ? 'You won! 🎉'
        : '${top.name} wins!';
    const medals = ['🥇', '🥈', '🥉'];
    return PaperCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, textAlign: TextAlign.center, style: _cardTitle),
          const SizedBox(height: 16),
          for (var i = 0; i < ranked.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Palette.ink.withValues(alpha: .3))),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 28,
                    child: Text(
                      ranked[i].points > 0 && i < 3 ? medals[i] : '',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ranked[i].displayName,
                          style: const TextStyle(fontWeight: FontWeight.w800, color: Palette.ink),
                        ),
                        Text(
                          ranked[i].wins.isEmpty
                              ? 'No prizes this time'
                              : ranked[i].wins.map((k) => prizeByKey(k).label).join(' · '),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: Palette.ink.withValues(alpha: .65),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${ranked[i].points}',
                    style: const TextStyle(fontFamily: Fonts.display, color: Palette.ticketRed),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 14),
          BigButton(label: 'Play again', onPressed: game.start),
          TextButton(
            onPressed: game.openSetup,
            child: const Text(
              'Change settings',
              style: TextStyle(color: Palette.ink, fontWeight: FontWeight.w600, decoration: TextDecoration.underline),
            ),
          ),
        ],
      ),
    );
  }
}
