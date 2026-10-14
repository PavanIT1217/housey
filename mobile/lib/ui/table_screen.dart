import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../app_services.dart';
import '../game/controller.dart';
import 'caller_settings.dart';
import 'caller.dart';
import 'cards.dart';
import 'look.dart';
import 'table_parts.dart';
import 'tools_menu.dart';

class TableScreen extends StatefulWidget {
  const TableScreen({super.key, required this.game, required this.services});
  final GameController game;
  final AppServices services;

  @override
  State<TableScreen> createState() => _TableScreenState();
}

class _TableScreenState extends State<TableScreen> with WidgetsBindingObserver {
  StreamSubscription<TableEvent>? _sub;
  AnnounceEvent? _banner;
  var _bannerId = 0;
  String? _toast;
  Timer? _toastTimer;

  GameController get game => widget.game;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sub = game.events.listen((e) {
      switch (e) {
        case AnnounceEvent():
          setState(() {
            _banner = e;
            _bannerId++;
          });
        case ToastEvent():
          _toastTimer?.cancel();
          setState(() => _toast = e.message);
          _toastTimer = Timer(const Duration(milliseconds: 2600), () {
            if (mounted) setState(() => _toast = null);
          });
        case BagShakeEvent():
          break;
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Don't keep calling numbers to an empty room.
    if (state == AppLifecycleState.paused && game.stage == Stage.playing && !game.over) game.pauseIfRunning();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sub?.cancel();
    _toastTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.wood3,
      resizeToAvoidBottomInset: false,
      body: WoodBackground(
        child: ListenableBuilder(
          listenable: game,
          builder: (context, _) => Stack(
            children: [
              Column(
                children: [
                  _TopBar(game: game, services: widget.services),
                  Expanded(child: _Layout(game: game)),
                ],
              ),
              if (game.stage != Stage.playing) _Modal(game: game, services: widget.services),
              if (_banner != null) _Banner(key: ValueKey(_bannerId), event: _banner!),
              _Toast(message: _toast),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.game, required this.services});
  final GameController game;
  final AppServices services;

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 560;
    final gap = narrow ? 5.0 : 8.0;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2A170A), Color(0xFF1D0F05)],
        ),
        boxShadow: [BoxShadow(color: Color(0x80000000), blurRadius: 12, offset: Offset(0, 3))],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Housey',
                      style: TextStyle(
                        fontFamily: Fonts.display,
                        fontSize: narrow ? 23 : 28,
                        letterSpacing: 1,
                        color: Palette.brass,
                        shadows: const [
                          Shadow(color: Color(0xFF6B4A12), offset: Offset(0, 2)),
                          Shadow(color: Color(0x99000000), blurRadius: 8, offset: Offset(0, 4)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Visibility(
                visible: !game.settings.manual,
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                child: _RoundButton(
                  icon: game.paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                  tooltip: game.paused ? 'Resume calling' : 'Pause calling',
                  onTap: game.togglePause,
                ),
              ),
              SizedBox(width: gap),
              _RoundButton(
                icon: game.settings.sound ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                tooltip: game.settings.sound ? 'Sound off' : 'Sound on',
                onTap: game.toggleSound,
              ),
              SizedBox(width: gap),
              _RoundButton(
                icon: Icons.tune_rounded,
                tooltip: 'Caller speed and voice',
                onTap: () => showCallerSettings(
                  context,
                  settings: game.settings,
                  fx: game.fx,
                  speed: () => game.settings.speed,
                  onSpeed: game.setSpeed,
                ),
              ),
              SizedBox(width: gap),
              _RoundButton(icon: Icons.refresh_rounded, tooltip: 'New game', onTap: game.openSetup),
              SizedBox(width: gap),
              _RoundButton(
                icon: Icons.apps_rounded,
                tooltip: 'Number caller, my tickets, print tickets',
                onTap: () {
                  if (game.stage == Stage.playing) game.pauseIfRunning();
                  showToolsMenu(context, services);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.tooltip, required this.onTap});
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context).width < 560 ? 38.0 : 42.0;
    return Tooltip(
      message: tooltip,
      child: Material(
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        color: Colors.transparent,
        child: Ink(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(center: Alignment(-.3, -.4), colors: [Color(0xFF5B3A20), Color(0xFF2B180A)]),
            boxShadow: [BoxShadow(color: Color(0x80000000), blurRadius: 5, offset: Offset(0, 2))],
          ),
          child: InkWell(
            onTap: onTap,
            child: Icon(icon, color: Palette.cream, size: size * .5),
          ),
        ),
      ),
    );
  }
}

class _Layout extends StatelessWidget {
  const _Layout({required this.game});
  final GameController game;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 900;
    final bottom = MediaQuery.paddingOf(context).bottom;

    final tickets = [
      for (var i = 0; i < game.me.tickets.length; i++) ...[
        if (i > 0) const SizedBox(height: 22),
        Center(
          child: TicketCard(
            key: ValueKey(game.me.tickets[i]),
            game: game,
            index: i,
            tilt: PaperTicket.tiltFor(game.me.tickets[i].code),
          ),
        ),
      ],
      const SizedBox(height: 26),
      Center(child: ClaimButtons(game: game)),
      const SizedBox(height: 14),
      Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Text(
            'Tap a number on your ticket to dab it. When you complete a prize, press its button to claim before someone else does!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, height: 1.5, color: Palette.cream.withValues(alpha: .65)),
          ),
        ),
      ),
    ];
    final side = [
      CallersBoard(isCalled: game.onBoard, latest: game.currentCoin, initiallyOpen: wide),
      const SizedBox(height: 18),
      PlayersList(game: game),
    ];

    final caller = Padding(
      padding: EdgeInsets.fromLTRB(16, wide ? 18 : 10, 16, 0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1168),
          child: CallerMat(game: game, compact: !wide),
        ),
      ),
    );

    if (!wide) {
      return Column(
        children: [
          caller,
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(16, 18, 16, 40 + bottom),
              children: [...tickets, const SizedBox(height: 22), ...side],
            ),
          ),
        ],
      );
    }
    return Column(
      children: [
        caller,
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ListView(padding: EdgeInsets.fromLTRB(16, 22, 9, 40 + bottom), children: tickets),
                  ),
                  SizedBox(
                    width: 376,
                    child: ListView(padding: EdgeInsets.fromLTRB(9, 18, 16, 40 + bottom), children: side),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Modal extends StatelessWidget {
  const _Modal({required this.game, required this.services});
  final GameController game;
  final AppServices services;

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.viewInsetsOf(context).bottom;
    return Positioned.fill(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 3, sigmaY: 3),
        child: ColoredBox(
          color: const Color(0x990A0500),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + insets),
              child: Center(
                child: game.stage == Stage.setup
                    ? SetupCard(key: const ValueKey('setup'), game: game, services: services)
                    : ResultsCard(key: const ValueKey('results'), game: game),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The big rubber stamp that announces a claim or a bogey.
class _Banner extends StatefulWidget {
  const _Banner({super.key, required this.event});
  final AnnounceEvent event;

  @override
  State<_Banner> createState() => _BannerState();
}

class _BannerState extends State<_Banner> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.event;
    final color = e.bogey ? Palette.ticketRed : const Color(0xFF1D6B38);
    final width = MediaQuery.sizeOf(context).width;
    final size = (width * .07).clamp(24.0, 44.0);
    return Positioned.fill(
      child: IgnorePointer(
        child: Align(
          alignment: const Alignment(0, -.16),
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, child) {
              final t = _c.value;
              double scale, opacity;
              if (t < .12) {
                final f = t / .12;
                scale = 2.6 - 1.65 * f;
                opacity = f;
              } else if (t < .18) {
                scale = .95 + .05 * (t - .12) / .06;
                opacity = 1;
              } else {
                scale = 1;
                opacity = t < .85 ? 1 : 1 - (t - .85) / .15;
              }
              return Opacity(
                opacity: opacity.clamp(0, 1),
                child: Transform.rotate(
                  angle: -.14,
                  child: Transform.scale(scale: scale, child: child),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xEDFAF4E2),
                border: Border.all(color: color, width: 5),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [BoxShadow(color: Color(0x8C000000), blurRadius: 40, offset: Offset(0, 16))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    e.title,
                    style: TextStyle(fontFamily: Fonts.display, fontSize: size, height: 1.1, color: color),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    e.subtitle,
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: size * .42, color: Palette.ink),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Toast extends StatelessWidget {
  const _Toast({required this.message});
  final String? message;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Positioned(
      left: 16,
      right: 16,
      bottom: bottom + 20,
      child: IgnorePointer(
        child: AnimatedSlide(
          offset: message == null ? const Offset(0, 2) : Offset.zero,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF1D0F05),
                borderRadius: BorderRadius.circular(30),
                boxShadow: const [BoxShadow(color: Color(0x80000000), blurRadius: 20, offset: Offset(0, 8))],
              ),
              child: Text(
                message ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFFFF3D6), fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
