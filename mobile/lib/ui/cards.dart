import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_services.dart';
import '../game/controller.dart';
import 'caller_settings.dart';
import '../core/prizes.dart';
import 'controls.dart';
import 'look.dart';
import 'tools_menu.dart';

class SetupCard extends StatefulWidget {
  const SetupCard({super.key, required this.game, required this.services});
  final GameController game;
  final AppServices services;

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

  void _resume() {
    widget.game.settings.name = _name.text;
    FocusScope.of(context).unfocus();
    widget.game.resume();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.game.settings;
    final resumable = widget.game.resumableCount;
    return PaperCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text("Let's play Housey", textAlign: TextAlign.center, style: cardTitle),
          const SizedBox(height: 16),
          const FieldLabel('Your name'),
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
          const FieldLabel('Tickets'),
          Segments(
            options: const {1: '1', 2: '2', 3: '3'},
            value: s.tickets,
            onChanged: (v) => setState(() => s.tickets = v),
          ),
          const SizedBox(height: 14),
          const FieldLabel('Players at the table'),
          Segments(
            options: const {0: 'Just me', 2: '+2', 4: '+4', 6: '+6'},
            value: s.bots,
            onChanged: (v) => setState(() => s.bots = v),
          ),
          const SizedBox(height: 14),
          const FieldLabel('Calling speed'),
          SpeedControl(value: s.speed, onChanged: (v) => setState(() => s.speed = v)),
          const SizedBox(height: 6),
          CheckToggle(label: 'Auto-dab for me', value: s.auto, onChanged: (v) => setState(() => s.auto = v)),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: 8),
              iconColor: Palette.ink,
              collapsedIconColor: Palette.ink,
              title: const Text(
                "Caller's voice",
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Palette.ink),
              ),
              children: [VoiceSettingsPanel(settings: s, fx: widget.game.fx)],
            ),
          ),
          if (resumable != null) ...[
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                border: Border.all(color: Palette.ticketRed, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'You have a game in progress: $resumable of 90 numbers called.',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Palette.ink),
                  ),
                  const SizedBox(height: 6),
                  BigButton(label: 'Resume game', onPressed: _resume),
                ],
              ),
            ),
          ],
          BigButton(label: resumable == null ? 'Deal tickets' : 'Deal a new game', onPressed: _start),
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
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final tool in Tool.values)
                ActionChip(
                  avatar: Icon(tool.icon, size: 18, color: Palette.ink),
                  label: Text(tool.label),
                  labelStyle: const TextStyle(color: Palette.ink, fontWeight: FontWeight.w700),
                  color: WidgetStatePropertyAll(Colors.white.withValues(alpha: .45)),
                  side: const BorderSide(color: Palette.ink, width: 1.5),
                  onPressed: () => openTool(context, widget.services, tool),
                ),
            ],
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
          Text(title, textAlign: TextAlign.center, style: cardTitle),
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
