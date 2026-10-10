import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:housey/game/controller.dart';
import 'package:housey/game/settings.dart';
import 'package:housey/main.dart';

void main() {
  testWidgets('deal tickets from the setup card, then play', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final game = GameController(settings: Settings()..speed = 0);
    await tester.pumpWidget(HouseyApp(game: game));
    expect(find.text("Let's play Housey"), findsOneWidget);

    await tester.tap(find.text('+2'));
    await tester.tap(find.text('2'));
    await tester.pump();
    await tester.tap(find.text('Deal tickets'));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text("Let's play Housey"), findsNothing);
    expect(game.players, hasLength(3));
    expect(game.me.tickets, hasLength(2));
    expect(find.text('Tap the bag to draw'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Draw a number from the bag'));
    await tester.pump(const Duration(seconds: 1));
    expect(game.called, hasLength(1));
    expect(find.text('1 / 90 called'), findsOneWidget);

    // Dab the first number on the first ticket.
    final n = game.me.tickets.first.numbers.first;
    await tester.tap(find.text('$n').first);
    await tester.pump(const Duration(milliseconds: 300));
    expect(game.me.tickets.first.dabs, contains(n));

    await tester.tap(find.text('Full House'));
    await tester.pump(const Duration(seconds: 3));
    expect(game.claimed['full'], isNull);

    game.dispose();
  });
}
