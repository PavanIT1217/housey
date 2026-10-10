import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../game/controller.dart';

/// Colours and type from the web version's stylesheet.
abstract final class Palette {
  static const wood1 = Color(0xFF6B4224);
  static const wood2 = Color(0xFF4A2B16);
  static const wood3 = Color(0xFF2E1A0C);
  static const felt = Color(0xFF1F5A3C);
  static const feltDark = Color(0xFF123826);
  static const paper = Color(0xFFF6EFDC);
  static const ink = Color(0xFF1E2A4A);
  static const ticketRed = Color(0xFFB3261E);
  static const brass = Color(0xFFE7C26B);
  static const coinLight = Color(0xFFE3BD84);
  static const coinMid = Color(0xFFC48D4D);
  static const coinDark = Color(0xFF8A5A2B);
  static const burnt = Color(0xFF4B240B);
  static const cream = Color(0xFFF3E6CC);
  static const dab = Color(0xFFD61C70);
}

abstract final class Fonts {
  static const slab = 'RobotoSlab';
  static const display = 'AlfaSlabOne';
  static const hand = 'Caveat';
  static const mono = 'CourierPrime';
}

const tableShadow = [
  BoxShadow(color: Color(0x73000000), blurRadius: 24, offset: Offset(0, 10)),
  BoxShadow(color: Color(0x59000000), blurRadius: 4, offset: Offset(0, 2)),
];

/// The wooden table top behind everything.
class WoodBackground extends StatelessWidget {
  const WoodBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Palette.wood2, Palette.wood1, Color(0xFF5A361C), Palette.wood1, Palette.wood2],
          stops: [0, .3, .55, .75, 1],
        ),
      ),
      child: CustomPaint(painter: const _GrainPainter(), child: child),
    );
  }
}

class _GrainPainter extends CustomPainter {
  const _GrainPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(3);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    // Long, wavy grain lines running across the boards.
    for (var y = 0.0; y < size.height; y += 3 + rng.nextDouble() * 6) {
      paint
        ..color = Color.fromRGBO(30, 14, 4, .08 + rng.nextDouble() * .16)
        ..strokeWidth = .6 + rng.nextDouble() * 1.6;
      final path = Path()..moveTo(0, y);
      final amp = rng.nextDouble() * 4, freq = .002 + rng.nextDouble() * .006, phase = rng.nextDouble() * 6;
      for (var x = 0.0; x <= size.width; x += 12) {
        path.lineTo(x, y + sin(x * freq + phase) * amp);
      }
      canvas.drawPath(path, paint);
    }
    final glow = Paint()
      ..shader = ui.Gradient.radial(Offset(size.width / 2, size.height * .3), size.longestSide * .6, [
        const Color(0x2EFFD296),
        const Color(0x00FFD296),
      ]);
    canvas.drawRect(Offset.zero & size, glow);
  }

  @override
  bool shouldRepaint(_GrainPainter old) => false;
}

/// Fine speckle that makes paper and felt look less flat.
class NoisePainter extends CustomPainter {
  const NoisePainter({this.color = const Color(0x29594D38), this.density = .02, this.seed = 1});
  final Color color;
  final double density;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(seed);
    final count = (size.width * size.height * density).clamp(0, 6000).toInt();
    final points = List.generate(count, (_) => Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height));
    canvas.drawPoints(
      ui.PointMode.points,
      points,
      Paint()
        ..color = color
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(NoisePainter old) => old.color != color || old.density != density;
}

/// A turned wooden number coin.
class Coin extends StatelessWidget {
  const Coin(this.number, {super.key, required this.size});
  final int number;
  final double size;

  @override
  Widget build(BuildContext context) {
    final underline = number == 6 || number == 9 || number == 66 || number == 69;
    final small = size < 50;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [Palette.coinLight, Palette.coinMid, Palette.coinDark],
          stops: [0, .7, 1],
        ),
        border: Border.all(color: const Color(0xFF7A4D22), width: small ? 1 : 2),
        boxShadow: [
          if (!small) const BoxShadow(color: Color(0xFF5D3815), offset: Offset(0, 3)),
          BoxShadow(color: const Color(0x80000000), blurRadius: small ? 4 : 14, offset: Offset(0, small ? 2 : 8)),
        ],
      ),
      child: CustomPaint(
        painter: _CoinFacePainter(),
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Text(
                '$number',
                style: TextStyle(
                  fontFamily: Fonts.display,
                  fontSize: size * .46,
                  height: 1,
                  color: Palette.burnt,
                  shadows: const [
                    Shadow(color: Color(0x8CFFE6BE), offset: Offset(0, 1)),
                    Shadow(color: Color(0x991E0A00), offset: Offset(0, -1), blurRadius: 1),
                  ],
                ),
              ),
              if (underline)
                Positioned(
                  bottom: -size * .09,
                  child: Container(
                    width: size * .28,
                    height: max(1.5, size * .035),
                    decoration: BoxDecoration(color: Palette.burnt, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoinFacePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    // Turned groove near the rim.
    canvas.drawCircle(
      c,
      r * .61,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * .05
        ..color = const Color(0x5946230A),
    );
    // Highlight from the lamp above.
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = ui.Gradient.radial(Offset(size.width * .35, size.height * .3), r * 1.1, [
          const Color(0x8CFFF0D2),
          const Color(0x00FFF0D2),
        ]),
    );
    // A few grain streaks.
    final rng = Random(r.round());
    final grain = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .8;
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: c, radius: r)));
    for (var i = 0; i < 9; i++) {
      final y = rng.nextDouble() * size.height;
      grain.color = Color.fromRGBO(70, 35, 10, .08 + rng.nextDouble() * .1);
      canvas.drawLine(Offset(0, y), Offset(size.width, y + (rng.nextDouble() - .5) * r * .4), grain);
    }
    canvas.restore();
    // Shading at the bottom edge.
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = ui.Gradient.linear(Offset(0, size.height * .7), Offset(0, size.height), [
          const Color(0x003C1E05),
          const Color(0x733C1E05),
        ]),
    );
  }

  @override
  bool shouldRepaint(_CoinFacePainter old) => false;
}

/// A round, hand-stamped blob of dauber ink.
class InkDab extends StatelessWidget {
  const InkDab({super.key, required this.look, this.fresh = true, this.blink = false});
  final DabLook look;
  final bool fresh;
  final bool blink;

  @override
  Widget build(BuildContext context) {
    Widget dab = CustomPaint(painter: _DabPainter(look), size: Size.infinite);
    if (blink) dab = _Blink(child: dab);
    if (!fresh) return dab;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      builder: (context, t, child) => Opacity(
        opacity: (t / .6).clamp(0, 1),
        child: Transform.scale(scale: 1.5 - .5 * t, child: child),
      ),
      child: dab,
    );
  }
}

class _DabPainter extends CustomPainter {
  _DabPainter(this.look);
  final DabLook look;

  @override
  void paint(Canvas canvas, Size size) {
    final s = min(size.width, size.height);
    final c = size.center(Offset(look.dx * s, look.dy * s));
    final r = s * .44 * look.scale;
    final rng = Random(look.seed);
    // Wobbly outline so no two dabs look alike.
    final path = Path();
    const steps = 40;
    final phases = List.generate(3, (_) => rng.nextDouble() * 2 * pi);
    for (var i = 0; i <= steps; i++) {
      final a = look.rotation + i / steps * 2 * pi;
      final wobble = 1 + .05 * sin(a * 3 + phases[0]) + .035 * sin(a * 5 + phases[1]) + .025 * sin(a * 9 + phases[2]);
      final p = c + Offset(cos(a), sin(a)) * r * wobble;
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    canvas.drawPath(
      path,
      Paint()
        ..blendMode = BlendMode.multiply
        ..shader = ui.Gradient.radial(
          c,
          r * 1.05,
          [
            Palette.dab.withValues(alpha: .42),
            Palette.dab.withValues(alpha: .42),
            Palette.dab.withValues(alpha: .58),
            const Color(0xC7960A46),
          ],
          [0, .72, .88, 1],
        ),
    );
  }

  @override
  bool shouldRepaint(_DabPainter old) => old.look != look;
}

/// Flashes its child twice: used for a dab whose number hasn't been called.
class _Blink extends StatefulWidget {
  const _Blink({required this.child});
  final Widget child;

  @override
  State<_Blink> createState() => _BlinkState();
}

class _BlinkState extends State<_Blink> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
  var _runs = 0;

  @override
  void initState() {
    super.initState();
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed && ++_runs < 2) _c.forward(from: 0);
    });
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (context, child) => Opacity(opacity: 1 - .8 * sin(_c.value * pi), child: child),
    child: widget.child,
  );
}
