import 'dart:math';

import 'package:flutter/material.dart';

import '../app_services.dart';
import '../game/caller_controller.dart';
import '../game/controller.dart' show DabLook;
import 'caller.dart';
import 'caller_settings.dart';
import 'controls.dart';
import 'look.dart';
import 'table_parts.dart';
import 'ticket_lookup.dart';
import 'tool_scaffold.dart';

/// The number caller: draws and calls numbers for a game on paper tickets.
class CallerScreen extends StatefulWidget {
  const CallerScreen({super.key, required this.services, this.controller});
  final AppServices services;

  /// For tests; normally the screen makes its own, restoring the saved session.
  final CallerController? controller;

  @override
  State<CallerScreen> createState() => _CallerScreenState();
}

class _CallerScreenState extends State<CallerScreen> with WidgetsBindingObserver {
  late final CallerController caller =
      widget.controller ??
      CallerController(
        settings: widget.services.settings,
        fx: widget.services.fx,
        saveSlot: widget.services.callerSession,
      );

  /// Each checked ticket gets fixed dab looks so they don't jump on every call.
  final _looks = <int, DabLook>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Don't keep calling numbers to an empty room.
    if (state == AppLifecycleState.paused && caller.running) caller.stop();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (widget.controller == null) caller.dispose();
    super.dispose();
  }

  Future<void> _confirmNewGame() async {
    if (caller.called.isEmpty) return caller.newGame();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start a new game?'),
        content: const Text('The numbers called so far will be cleared.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('New game')),
        ],
      ),
    );
    if (ok == true) caller.newGame();
  }

  void _openSettings() => showCallerSettings(
    context,
    settings: widget.services.settings,
    fx: widget.services.fx,
    speed: () => widget.services.settings.callerSpeed,
    onSpeed: caller.setSpeed,
    allowManual: false,
  );

  @override
  Widget build(BuildContext context) {
    final settings = widget.services.settings;
    return ListenableBuilder(
      listenable: caller,
      builder: (context, _) => ToolScaffold(
        title: 'Number caller',
        actions: [
          IconButton(
            tooltip: settings.sound ? 'Sound off' : 'Sound on',
            icon: Icon(settings.sound ? Icons.volume_up_rounded : Icons.volume_off_rounded),
            onPressed: () => setState(() {
              settings.sound = !settings.sound;
              if (!settings.sound) widget.services.fx.hush();
              settings.save();
            }),
          ),
          IconButton(tooltip: 'Speed and voice', icon: const Icon(Icons.tune_rounded), onPressed: _openSettings),
        ],
        children: [
          CallerMat(game: caller, compact: MediaQuery.sizeOf(context).width < 900),
          _Controls(caller: caller, onNewGame: _confirmNewGame),
          CallersBoard(isCalled: caller.isCalled, latest: caller.currentCoin, initiallyOpen: true),
          Panel(
            title: 'Check a ticket',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Note(
                  "Someone shouting a prize? Type the code from their ticket or scan its QR code to see what's been called.",
                ),
                const SizedBox(height: 10),
                TicketLookup(
                  buttonLabel: 'Check',
                  onTicket: (t) {
                    _looks.clear();
                    caller.check(t);
                  },
                ),
                if (caller.checked != null) ...[
                  const SizedBox(height: 14),
                  _CheckResult(caller: caller, looks: _looks),
                ],
              ],
            ),
          ),
          Panel(
            title: 'Speed and voice',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const FieldLabel('Time between numbers'),
                SpeedControl(value: settings.callerSpeed, allowManual: false, onChanged: caller.setSpeed),
                const SizedBox(height: 10),
                VoiceSettingsPanel(settings: settings, fx: widget.services.fx),
              ],
            ),
          ),
          const Panel(
            title: 'How it works',
            child: Note(
              'Hand out paper tickets (print them from Print tickets), press Start calling, and numbers come out on '
              'their own at the speed you set. Or tap the bag or Next number for each call. Undo puts a number back. '
              'The game is saved as you go, so closing the app doesn\'t lose it.',
            ),
          ),
        ],
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({required this.caller, required this.onNewGame});
  final CallerController caller;
  final VoidCallback onNewGame;

  @override
  Widget build(BuildContext context) {
    final label = caller.running
        ? 'Pause'
        : caller.called.isEmpty
        ? 'Start calling'
        : 'Carry on';
    final style = FilledButton.styleFrom(
      backgroundColor: const Color(0xFF3B2210),
      foregroundColor: Palette.cream,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      textStyle: const TextStyle(fontFamily: Fonts.slab, fontWeight: FontWeight.w800, fontSize: 15),
    );
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: [
        SizedBox(
          width: 220,
          child: Opacity(
            opacity: caller.isFinished ? .45 : 1,
            child: BigButton(label: label, onPressed: caller.toggle),
          ),
        ),
        FilledButton(
          style: style,
          onPressed: caller.isFinished ? null : caller.tapBag,
          child: const Text('Next number'),
        ),
        FilledButton(style: style, onPressed: caller.canUndo ? caller.undo : null, child: const Text('↶ Undo')),
        FilledButton(style: style, onPressed: onNewGame, child: const Text('New game')),
      ],
    );
  }
}

final _rng = Random();

class _CheckResult extends StatelessWidget {
  const _CheckResult({required this.caller, required this.looks});
  final CallerController caller;
  final Map<int, DabLook> looks;

  @override
  Widget build(BuildContext context) {
    final ticket = caller.checked!;
    final won = caller.checkedPrizes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PaperTicket(
          ticket: ticket,
          heading: 'CHECKING',
          dabLook: (n) => caller.isCalled(n) ? looks.putIfAbsent(n, () => DabLook(_rng)) : null,
        ),
        const SizedBox(height: 10),
        Text(
          '${caller.checkedHits} of 15 numbers on this ticket have been called.',
          style: const TextStyle(fontWeight: FontWeight.w700, color: Palette.ink),
        ),
        const SizedBox(height: 4),
        if (won.isEmpty)
          const Note('No prize complete yet.')
        else
          for (final p in won)
            Text(
              '✓ ${p.label}',
              style: const TextStyle(color: Color(0xFF1D6B38), fontWeight: FontWeight.w800, fontSize: 15),
            ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            style: TextButton.styleFrom(foregroundColor: Palette.ink),
            onPressed: () => caller.check(null),
            child: const Text('Clear', style: TextStyle(decoration: TextDecoration.underline)),
          ),
        ),
      ],
    );
  }
}
