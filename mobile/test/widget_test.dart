import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:housey/game/controller.dart';
import 'package:housey/app_services.dart';
import 'package:housey/services/settings.dart';
import 'package:housey/main.dart';
import 'package:housey/ui/caller_screen.dart';
import 'package:housey/ui/cards.dart';
import 'package:housey/ui/my_tickets_screen.dart';
import 'package:housey/ui/print_screen.dart';

void main() {
  testWidgets('deal tickets from the setup card, then play', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final services = AppServices.forTests(settings: Settings()..speed = 0);
    final game = GameController(settings: services.settings);
    await tester.pumpWidget(HouseyApp(game: game, services: services));
    expect(find.text("Let's play Housey"), findsOneWidget);

    // Only the setup card's buttons: a ticket behind the card can show the same numbers.
    Finder onCard(String text) => find.descendant(of: find.byType(SetupCard), matching: find.text(text));
    await tester.tap(onCard('+2'));
    await tester.tap(onCard('2'));
    await tester.pump();
    await tester.ensureVisible(find.text('Deal tickets'));
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

    await tester.ensureVisible(find.text('Full House'));
    await tester.pump();
    await tester.tap(find.text('Full House'));
    await tester.pump(const Duration(seconds: 3));
    expect(game.claimed['full'], isNull);

    game.dispose();
  });

  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  testWidgets('a narrow phone fits the top bar and setup card', (tester) async {
    tester.view.physicalSize = const Size(720, 1520);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final services = AppServices.forTests();
    final game = GameController(settings: services.settings);
    await tester.pumpWidget(HouseyApp(game: game, services: services));
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
    game.dispose();
  });

  testWidgets('the number caller calls, undoes and checks a ticket', (tester) async {
    phone(tester);
    final services = AppServices.forTests();
    await tester.pumpWidget(MaterialApp(home: CallerScreen(services: services)));
    expect(find.text('Press Start when everyone is ready'), findsOneWidget);

    await tester.tap(find.text('Next number'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('1 / 90 called'), findsOneWidget);
    expect(find.textContaining('Number '), findsWidgets);

    await tester.tap(find.text('↶ Undo'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('0 / 90 called'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Check'), 300, scrollable: find.byType(Scrollable).first);
    await tester.enterText(find.byType(TextField).first, 'hnzv-c92z');
    await tester.testTextInput.receiveAction(TextInputAction.go);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Nº HNZV-C92Z'), findsOneWidget);
    expect(find.text('0 of 15 numbers on this ticket have been called.'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'ABCD-EFGH');
    await tester.testTextInput.receiveAction(TextInputAction.go);
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining("doesn't look right"), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('my tickets opens a ticket by code and dabs it', (tester) async {
    phone(tester);
    final services = AppServices.forTests();
    await tester.pumpWidget(MaterialApp(home: MyTicketsScreen(services: services)));
    await tester.enterText(find.byType(TextField), 'HNZV-C92Z');
    await tester.tap(find.text('Open'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Nº HNZV-C92Z'), findsOneWidget);
    await tester.tap(find.text('22'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(services.myTickets.load().toString(), contains('22'));
  });

  testWidgets('print tickets applies a preset', (tester) async {
    phone(tester);
    final services = AppServices.forTests();
    await tester.pumpWidget(MaterialApp(home: PrintScreen(services: services)));
    expect(find.text('6 tickets on 1 A4 page.'), findsOneWidget);
    await tester.tap(find.text('Diwali / festival'));
    await tester.pump();
    expect(find.text('60 tickets on 5 A4 pages.'), findsOneWidget);
    expect(services.printOptions.load().toString(), contains('Diwali Tambola'));
  });
}
