import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../game/controller.dart';
import 'look.dart';

/// The felt mat with the bag of coins, the coin just drawn and the caller's words.
class CallerMat extends StatelessWidget {
  const CallerMat({super.key, required this.game, required this.compact});
  final GameController game;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final coinSize = compact ? 76.0 : 112.0;
    final trayCoin = compact ? 28.0 : 40.0;
    final narrow = MediaQuery.sizeOf(context).width < 560;
    return Container(
      decoration: BoxDecoration(
        color: Palette.felt,
        gradient: const RadialGradient(
          center: Alignment(-.2, -.2),
          radius: 1.2,
          colors: [Color(0xFF2A7550), Palette.feltDark],
        ),
        borderRadius: BorderRadius.circular(compact ? 14 : 18),
        border: Border.all(color: const Color(0xFF3B2210), width: compact ? 4 : 6),
        boxShadow: tableShadow,
      ),
      child: CustomPaint(
        painter: const NoisePainter(color: Color(0x22000000), density: .05, seed: 5),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 22, vertical: compact ? 10 : 16),
          child: Row(
            children: [
              Bag(game: game, width: compact ? 62 : 104, height: compact ? 72 : 120),
              SizedBox(width: compact ? 10 : 22),
              SizedBox(
                width: coinSize,
                height: coinSize,
                child: game.currentCoin == null
                    ? _Placeholder(size: coinSize)
                    : _EmergingCoin(key: ValueKey(game.called.length), number: game.currentCoin!, size: coinSize),
              ),
              SizedBox(width: compact ? 10 : 22),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.callText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: Fonts.hand,
                        fontWeight: FontWeight.w700,
                        fontSize: compact ? 24 : 34,
                        height: 1.1,
                        color: const Color(0xFFFFF6E0),
                        shadows: const [Shadow(color: Color(0x80000000), blurRadius: 4, offset: Offset(0, 2))],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 2, bottom: 6),
                      child: Text(
                        game.callCount,
                        style: TextStyle(
                          fontSize: compact ? 12 : 13,
                          letterSpacing: .5,
                          color: Palette.cream.withValues(alpha: .7),
                        ),
                      ),
                    ),
                    _Tray(coins: game.tray.take(narrow ? 3 : 6).toList(), coinSize: trayCoin),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _DashedCircle(),
    child: Center(
      child: Text(
        '?',
        style: TextStyle(fontFamily: Fonts.display, fontSize: size * .36, color: Colors.white.withValues(alpha: .25)),
      ),
    ),
  );
}

class _DashedCircle extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = Colors.white.withValues(alpha: .25);
    final r = size.width / 2 - 1.5;
    const dashes = 28;
    for (var i = 0; i < dashes; i++) {
      final a = i / dashes * 2 * pi;
      canvas.drawArc(Rect.fromCircle(center: size.center(Offset.zero), radius: r), a, pi / dashes, false, paint);
    }
  }

  @override
  bool shouldRepaint(_DashedCircle old) => false;
}

/// The coin flips out of the bag and lands on the mat.
class _EmergingCoin extends StatefulWidget {
  const _EmergingCoin({super.key, required this.number, required this.size});
  final int number;
  final double size;

  @override
  State<_EmergingCoin> createState() => _EmergingCoinState();
}

class _EmergingCoinState extends State<_EmergingCoin> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 850))..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final from = widget.size * 1.15;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = Curves.easeOutBack.transform(_c.value);
        final dx = ui.lerpDouble(-from, 0, t)!;
        final dy = sin(_c.value * pi) * -widget.size * .1;
        final scale = ui.lerpDouble(.25, 1, t)!;
        final spin = (1 - Curves.easeOut.transform(_c.value)) * 3 * pi;
        final opacity = (_c.value / .3).clamp(0.0, 1.0);
        return Opacity(
          opacity: opacity,
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, .0016)
              ..translateByDouble(dx, dy, 0, 1)
              ..scaleByDouble(scale, scale, 1, 1)
              ..rotateY(spin)
              ..rotateZ((1 - t) * -.7),
            child: child,
          ),
        );
      },
      child: Coin(widget.number, size: widget.size),
    );
  }
}

class _Tray extends StatelessWidget {
  const _Tray({required this.coins, required this.coinSize});
  final List<int> coins;
  final double coinSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: coinSize + 12,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(color: const Color(0x38000000), borderRadius: BorderRadius.circular(30)),
      clipBehavior: Clip.hardEdge,
      child: Row(
        children: [
          for (var i = 0; i < coins.length; i++)
            Padding(
              key: ValueKey(coins[i]),
              padding: EdgeInsets.only(right: coinSize * .2),
              child: Opacity(
                opacity: i == 0 ? 1 : (i < 3 ? .9 : .7),
                child: _SlideIn(child: Coin(coins[i], size: coinSize)),
              ),
            ),
        ],
      ),
    );
  }
}

class _SlideIn extends StatelessWidget {
  const _SlideIn({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: const Duration(milliseconds: 450),
    curve: Curves.easeOut,
    builder: (context, t, child) => Opacity(
      opacity: t,
      child: Transform.translate(
        offset: Offset(-40 * (1 - t), 0),
        child: Transform.rotate(angle: -pi / 2 * (1 - t), child: child),
      ),
    ),
    child: child,
  );
}

/// The cloth bag of coins. It shakes on every draw and, when the player is
/// drawing, wiggles now and then to invite a tap.
class Bag extends StatefulWidget {
  const Bag({super.key, required this.game, required this.width, required this.height});
  final GameController game;
  final double width, height;

  @override
  State<Bag> createState() => _BagState();
}

class _BagState extends State<Bag> with TickerProviderStateMixin {
  late final _shake = AnimationController(vsync: this, duration: const Duration(milliseconds: 550));
  late final _invite = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400));
  StreamSubscription<TableEvent>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = widget.game.events.listen((e) {
      if (e is BagShakeEvent) _shake.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _shake.dispose();
    _invite.dispose();
    super.dispose();
  }

  static double _shakeAngle(double t) {
    // Keyframes: 0 → -9° → 8° → -6° → 4° → 0.
    const keys = [0.0, .15, .35, .55, .75, 1.0];
    const deg = [0.0, -9.0, 8.0, -6.0, 4.0, 0.0];
    for (var i = 1; i < keys.length; i++) {
      if (t <= keys[i]) {
        final f = Curves.easeInOut.transform((t - keys[i - 1]) / (keys[i] - keys[i - 1]));
        return ui.lerpDouble(deg[i - 1], deg[i], f)! * pi / 180;
      }
    }
    return 0;
  }

  static double _inviteAngle(double t) {
    if (t < .8) return 0;
    if (t < .86) return ui.lerpDouble(0, -4, (t - .8) / .06)! * pi / 180;
    if (t < .93) return ui.lerpDouble(-4, 4, (t - .86) / .07)! * pi / 180;
    return ui.lerpDouble(4, 0, (t - .93) / .07)! * pi / 180;
  }

  @override
  Widget build(BuildContext context) {
    final manual = widget.game.settings.manual && widget.game.stage == Stage.playing && !widget.game.over;
    if (manual && !_invite.isAnimating) {
      _invite.repeat();
    } else if (!manual && _invite.isAnimating) {
      _invite.stop();
      _invite.value = 0;
    }
    return Semantics(
      button: true,
      label: 'Draw a number from the bag',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.game.tapBag,
        child: AnimatedBuilder(
          animation: Listenable.merge([_shake, _invite]),
          builder: (context, child) {
            final angle = _shake.isAnimating ? _shakeAngle(_shake.value) : _inviteAngle(_invite.value);
            final lift = _shake.isAnimating ? -3 * sin(_shake.value * pi * 2).abs() : 0.0;
            return Transform.translate(
              offset: Offset(0, lift),
              child: Transform.rotate(angle: angle, alignment: const Alignment(0, .8), child: child),
            );
          },
          child: CustomPaint(
            size: Size(widget.width, widget.height),
            painter: _BagPainter(showTap: manual),
          ),
        ),
      ),
    );
  }
}

/// Paints the bag from the web version's SVG (viewBox 120 x 140).
class _BagPainter extends CustomPainter {
  _BagPainter({required this.showTap});
  final bool showTap;

  @override
  void paint(Canvas canvas, Size size) {
    final s = min(size.width / 120, size.height / 140);
    canvas.translate((size.width - 120 * s) / 2, (size.height - 140 * s) / 2);
    canvas.scale(s);

    final sack = Path()
      ..moveTo(38, 30)
      ..cubicTo(30, 40, 10, 62, 12, 96)
      ..cubicTo(14, 126, 38, 136, 60, 136)
      ..cubicTo(82, 136, 106, 126, 108, 96)
      ..cubicTo(110, 62, 90, 40, 82, 30)
      ..close();

    canvas.drawPath(
      sack.shift(const Offset(0, 8)),
      Paint()
        ..color = const Color(0x8C000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawPath(
      sack,
      Paint()
        ..shader = ui.Gradient.radial(
          const Offset(48, 63),
          84,
          [const Color(0xFFC9A46C), const Color(0xFF9C7543), const Color(0xFF5E4223)],
          [0, .65, 1],
        ),
    );
    // Weave.
    canvas.save();
    canvas.clipPath(sack);
    final weave = Paint()
      ..color = const Color(0x2E3D2A14)
      ..strokeWidth = 1;
    for (var x = 2.0; x < 120; x += 4) {
      canvas.drawLine(Offset(x, 0), Offset(x, 140), weave);
    }
    for (var y = 2.0; y < 140; y += 4) {
      canvas.drawLine(Offset(0, y), Offset(120, y), weave);
    }
    canvas.restore();

    Paint stroke(Color c, double w) => Paint()
      ..style = PaintingStyle.stroke
      ..color = c
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(
      Path()
        ..moveTo(36, 32)
        ..quadraticBezierTo(60, 40, 84, 32),
      stroke(const Color(0x804A3219), 2),
    );
    canvas.drawPath(
      Path()
        ..moveTo(44, 46)
        ..quadraticBezierTo(40, 80, 34, 118)
        ..moveTo(60, 44)
        ..quadraticBezierTo(61, 90, 60, 128)
        ..moveTo(76, 46)
        ..quadraticBezierTo(80, 80, 86, 118),
      stroke(const Color(0x383D2A14), 2),
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(60, 27), width: 50, height: 16),
      Paint()..color = const Color(0xFF6D4E2B),
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(60, 25), width: 42, height: 10),
      Paint()..color = const Color(0xFF2B1C0D),
    );
    canvas.drawPath(
      Path()
        ..moveTo(34, 30)
        ..quadraticBezierTo(60, 38, 86, 30),
      stroke(const Color(0xFFD8C9A3), 3.5),
    );
    canvas.drawPath(
      Path()
        ..moveTo(84, 31)
        ..quadraticBezierTo(94, 37, 90, 51)
        ..quadraticBezierTo(87, 59, 92, 65),
      stroke(const Color(0xFFD8C9A3), 3),
    );
    canvas.drawCircle(const Offset(92, 66), 3.5, Paint()..color = const Color(0xFFC4B38A));

    if (showTap) {
      final tp = TextPainter(
        text: const TextSpan(
          text: 'TAP',
          style: TextStyle(fontFamily: Fonts.display, fontSize: 13, letterSpacing: 2, color: Color(0x8C3D2A14)),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(60 - tp.width / 2, 98 - tp.height * .8));
    }
  }

  @override
  bool shouldRepaint(_BagPainter old) => old.showTap != showTap;
}
