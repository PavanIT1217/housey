import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game/controller.dart';
import 'game/fx.dart';
import 'game/settings.dart';
import 'ui/look.dart';
import 'ui/table_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Palette.wood3,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  final settings = await Settings.load();
  final fx = DeviceFx(soundOn: () => settings.sound, voiceOn: () => settings.voice);
  await fx.init();
  runApp(
    HouseyApp(
      game: GameController(settings: settings, fx: fx),
    ),
  );
}

class HouseyApp extends StatelessWidget {
  const HouseyApp({super.key, required this.game});
  final GameController game;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Housey',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: Fonts.slab,
        colorScheme: ColorScheme.fromSeed(seedColor: Palette.ticketRed, brightness: Brightness.dark),
        textSelectionTheme: const TextSelectionThemeData(cursorColor: Palette.ticketRed),
      ),
      home: TableScreen(game: game),
    );
  }
}
