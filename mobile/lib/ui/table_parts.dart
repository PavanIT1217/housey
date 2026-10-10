import 'dart:math';

import 'package:flutter/material.dart';

import '../game/controller.dart';
import '../game/rules.dart';
import 'look.dart';

/// One of my paper tickets, slightly askew on the table.
class TicketCard extends StatelessWidget {
  const TicketCard({super.key, required this.game, required this.index, required this.tilt});
  final GameController game;
  final int index;
  final double tilt;

  @override
  Widget build(BuildContext context) {
    final ticket = game.me.tickets[index];
    final winner = game.winnerTicket == index;
    final width = MediaQuery.sizeOf(context).width;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 640),
      child: Transform.rotate(
        angle: tilt * pi / 180,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: EdgeInsets.fromLTRB(width < 560 ? 8 : 12, 10, width < 560 ? 8 : 12, width < 560 ? 10 : 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment(-.2, -1),
              end: Alignment(.2, 1),
              colors: [Color(0xFFFBF6E8), Palette.paper, Color(0xFFEFE4C7)],
            ),
            borderRadius: BorderRadius.circular(3),
            boxShadow: [
              if (winner) const BoxShadow(color: Palette.brass, spreadRadius: 3),
              if (winner) const BoxShadow(color: Color(0xCCE7C26B), blurRadius: 30),
              const BoxShadow(color: Color(0x73000000), blurRadius: 22, offset: Offset(0, 12)),
              const BoxShadow(color: Color(0x4D000000), blurRadius: 6, offset: Offset(0, 3)),
            ],
          ),
          child: CustomPaint(
            painter: const NoisePainter(seed: 11),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(2, 0, 2, 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      const Text(
                        'HOUSEY',
                        style: TextStyle(
                          fontFamily: Fonts.display,
                          color: Palette.ticketRed,
                          fontSize: 14,
                          letterSpacing: 3,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'TICKET ${index + 1} OF ${game.me.tickets.length}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 11, letterSpacing: 2, color: Palette.ink),
                        ),
                      ),
                      Text(
                        'Nº ${ticket.serial}',
                        style: const TextStyle(
                          fontFamily: Fonts.mono,
                          fontWeight: FontWeight.w700,
                          color: Palette.ticketRed,
                          fontSize: 13,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Palette.ink, width: 2),
                    color: Palette.ink,
                  ),
                  child: LayoutBuilder(
                    builder: (context, c) {
                      const gap = 1.5;
                      final cell = (c.maxWidth - gap * 8) / 9;
                      return Column(
                        children: [
                          for (var r = 0; r < 3; r++)
                            Padding(
                              padding: EdgeInsets.only(top: r == 0 ? 0 : gap),
                              child: Row(
                                children: [
                                  for (var col = 0; col < 9; col++) ...[
                                    if (col > 0) const SizedBox(width: gap),
                                    SizedBox(
                                      width: cell,
                                      height: cell * 1.05,
                                      child: _Cell(game: game, ticketIndex: index, number: ticket.grid[r][col]),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.game, required this.ticketIndex, required this.number});
  final GameController game;
  final int ticketIndex;
  final int number;

  @override
  Widget build(BuildContext context) {
    if (number == 0) {
      return const CustomPaint(
        painter: _HatchPainter(),
        child: ColoredBox(color: Color(0xFFECE1C4), child: SizedBox.expand()),
      );
    }
    final ticket = game.me.tickets[ticketIndex];
    final look = game.dabLooks[ticket]?[number];
    final wrong = game.wrong.contains('$ticketIndex:$number');
    final width = MediaQuery.sizeOf(context).width;
    return Semantics(
      button: true,
      label: 'Number $number${look != null ? ', dabbed' : ''}',
      child: Material(
        color: const Color(0xFFFAF4E2),
        child: InkWell(
          onTap: () => game.toggleDab(ticketIndex, number),
          highlightColor: const Color(0xFFFFF3CF),
          splashColor: Colors.transparent,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: Text(
                  '$number',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: (width * .046).clamp(16, 30),
                    color: Palette.ink,
                  ),
                ),
              ),
              if (look != null) InkDab(key: ValueKey('dab$number${wrong ? 'w' : ''}'), look: look, blink: wrong),
            ],
          ),
        ),
      ),
    );
  }
}

class _HatchPainter extends CustomPainter {
  const _HatchPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0x141E2A4A)
      ..strokeWidth = 2;
    canvas.clipRect(Offset.zero & size);
    for (var x = -size.height; x < size.width; x += 6) {
      canvas.drawLine(Offset(x, size.height), Offset(x + size.height, 0), p);
    }
  }

  @override
  bool shouldRepaint(_HatchPainter old) => false;
}

/// The five prize buttons.
class ClaimButtons extends StatelessWidget {
  const ClaimButtons({super.key, required this.game});
  final GameController game;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 640),
      child: LayoutBuilder(
        builder: (context, c) {
          // Five across when there's room, otherwise three over two.
          final perRow = c.maxWidth >= 520 ? 5 : 3;
          const gap = 10.0;
          final w = (c.maxWidth - gap * (perRow - 1)) / perRow;
          return Wrap(
            alignment: WrapAlignment.center,
            spacing: gap,
            runSpacing: gap + 4,
            children: [
              for (final p in prizes)
                SizedBox(
                  width: w,
                  child: _ClaimButton(prize: p, owner: game.claimed[p.key], onTap: () => game.claim(p.key)),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ClaimButton extends StatefulWidget {
  const _ClaimButton({required this.prize, required this.owner, required this.onTap});
  final Prize prize;
  final Player? owner;
  final VoidCallback onTap;

  @override
  State<_ClaimButton> createState() => _ClaimButtonState();
}

class _ClaimButtonState extends State<_ClaimButton> {
  var _down = false;

  @override
  Widget build(BuildContext context) {
    final owner = widget.owner;
    final taken = owner != null;
    final pressed = _down && !taken;
    return Semantics(
      button: true,
      enabled: !taken,
      label: 'Claim ${widget.prize.label}',
      child: GestureDetector(
        onTapDown: (_) => setState(() => _down = true),
        onTapUp: (_) => setState(() => _down = false),
        onTapCancel: () => setState(() => _down = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          transform: Matrix4.translationValues(0, pressed ? 3 : 0, 0),
          padding: const EdgeInsets.fromLTRB(6, 10, 6, 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: taken
                  ? const [Color(0xFFCBBF9F), Color(0xFFA99C7C)]
                  : const [Color(0xFFF2C95F), Color(0xFFD79B2C)],
            ),
            boxShadow: [
              BoxShadow(
                color: taken ? const Color(0xFF6E6450) : const Color(0xFF8B5A10),
                offset: Offset(0, taken ? 2 : (pressed ? 1 : 4)),
              ),
              BoxShadow(
                color: const Color(0x73000000),
                blurRadius: pressed ? 6 : 12,
                offset: Offset(0, pressed ? 3 : 7),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Column(
                children: [
                  Text(
                    widget.prize.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      height: 1.15,
                      color: taken ? const Color(0xFF4D4535) : const Color(0xFF3A1F00),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${widget.prize.points} pts',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      color: (taken ? const Color(0xFF4D4535) : const Color(0xFF3A1F00)).withValues(alpha: .75),
                    ),
                  ),
                ],
              ),
              if (owner != null)
                Positioned.fill(
                  child: _Stamp(text: owner.human ? 'Yours!' : owner.name, mine: owner.human),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stamp extends StatelessWidget {
  const _Stamp({required this.text, required this.mine});
  final String text;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final color = mine ? const Color(0xFF1D6B38) : const Color(0xE6B3261E);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.scale(scale: 2.2 - 1.2 * t, child: child),
      ),
      child: Transform.rotate(
        angle: -12 * pi / 180,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: color, width: 2),
            borderRadius: BorderRadius.circular(6),
            color: const Color(0x59FFF5E6),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                text.toUpperCase(),
                style: TextStyle(fontFamily: Fonts.display, fontSize: 12, letterSpacing: 1, color: color),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The printed caller's board with a red chip on each called number.
class CallersBoard extends StatefulWidget {
  const CallersBoard({super.key, required this.game, required this.initiallyOpen});
  final GameController game;
  final bool initiallyOpen;

  @override
  State<CallersBoard> createState() => _CallersBoardState();
}

class _CallersBoardState extends State<CallersBoard> {
  late var _open = widget.initiallyOpen;

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final latest = game.currentCoin;
    return Transform.rotate(
      angle: .4 * pi / 180,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF4E9CC), Color(0xFFE4D3A7)],
          ),
          borderRadius: BorderRadius.circular(6),
          boxShadow: tableShadow,
        ),
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
        child: Column(
          children: [
            InkWell(
              onTap: () => setState(() => _open = !_open),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        "CALLER'S BOARD",
                        style: TextStyle(
                          fontFamily: Fonts.display,
                          color: Palette.ticketRed,
                          letterSpacing: 2,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: _open ? 0 : -.25,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(Icons.arrow_drop_down, color: Palette.ticketRed),
                    ),
                  ],
                ),
              ),
            ),
            if (_open)
              GridView.count(
                crossAxisCount: 10,
                mainAxisSpacing: 3,
                crossAxisSpacing: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  for (var n = 1; n <= 90; n++) _BoardCell(n: n, called: game.onBoard(n), latest: n == latest),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _BoardCell extends StatelessWidget {
  const _BoardCell({required this.n, required this.called, required this.latest});
  final int n;
  final bool called, latest;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: .25),
            border: Border.all(color: Palette.ink.withValues(alpha: .35)),
          ),
        ),
        if (called) _Chip(key: ValueKey('chip$n'), latest: latest),
        Center(
          child: FittedBox(
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Text(
                '$n',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: called ? Colors.white : Palette.ink),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatefulWidget {
  const _Chip({super.key, required this.latest});
  final bool latest;

  @override
  State<_Chip> createState() => _ChipState();
}

class _ChipState extends State<_Chip> with TickerProviderStateMixin {
  late final _drop = AnimationController(vsync: this, duration: const Duration(milliseconds: 350))..forward();
  late final _glow = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));

  @override
  void initState() {
    super.initState();
    if (widget.latest) _glow.repeat();
  }

  @override
  void didUpdateWidget(_Chip old) {
    super.didUpdateWidget(old);
    if (widget.latest && !_glow.isAnimating) _glow.repeat();
    if (!widget.latest && _glow.isAnimating) {
      _glow.stop();
      _glow.value = 0;
    }
  }

  @override
  void dispose() {
    _drop.dispose();
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_drop, _glow]),
      builder: (context, _) {
        final t = Curves.elasticOut.transform(_drop.value);
        final glow = widget.latest ? sin(_glow.value * pi) : 0.0;
        return Opacity(
          opacity: _drop.value.clamp(0, 1),
          child: Transform.translate(
            offset: Offset(0, -14 * (1 - t)),
            child: Transform.scale(
              scale: 1 + .4 * (1 - t),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    center: Alignment(-.3, -.4),
                    colors: [Color(0xD9FF968C), Color(0xBFC81E1E), Color(0xD9780000)],
                    stops: [0, .55, 1],
                  ),
                  boxShadow: [
                    if (glow > 0) BoxShadow(color: Color.fromRGBO(255, 210, 90, .8 * glow), spreadRadius: 3),
                    const BoxShadow(color: Color(0x73000000), blurRadius: 3, offset: Offset(0, 2)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Everyone at the table, highest score first.
class PlayersList extends StatelessWidget {
  const PlayersList({super.key, required this.game});
  final GameController game;

  @override
  Widget build(BuildContext context) {
    if (game.stage == Stage.setup && game.called.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0x40000000), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'AT THE TABLE',
              style: TextStyle(
                fontSize: 13,
                letterSpacing: 2,
                fontWeight: FontWeight.w600,
                color: Palette.cream.withValues(alpha: .7),
              ),
            ),
          ),
          for (final p in game.ranked) _PlayerRow(player: p, claiming: game.claimingPlayer == p.id),
        ],
      ),
    );
  }
}

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({required this.player, required this.claiming});
  final Player player;
  final bool claiming;

  @override
  Widget build(BuildContext context) {
    final p = player;
    final sub = p.wins.isNotEmpty
        ? p.wins.map((k) => prizeByKey(k).label).join(', ')
        : '${p.tickets.length} ticket${p.tickets.length > 1 ? 's' : ''}';
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: claiming
            ? const Color(0x59E7C26B)
            : p.human
            ? const Color(0x1FE7C26B)
            : Colors.transparent,
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color(p.color),
              boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 4, offset: Offset(0, 2))],
            ),
            child: Text(
              p.name[0].toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.white),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.displayName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Palette.cream),
                ),
                Text(
                  sub,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: Palette.cream.withValues(alpha: .6)),
                ),
              ],
            ),
          ),
          Text(
            '${p.points}',
            style: const TextStyle(fontFamily: Fonts.display, color: Palette.brass),
          ),
        ],
      ),
    );
  }
}
