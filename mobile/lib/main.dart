import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_services.dart';
import 'game/controller.dart';
import 'services/fx.dart';
import 'services/settings.dart';
import 'services/storage.dart';
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
  final store = await PrefsStore.open();
  final settings = Settings.load(store);
  final fx = DeviceFx(settings);
  await fx.init();
  final services = AppServices(store: store, settings: settings, fx: fx);
  runApp(
    HouseyApp(
      services: services,
      game: GameController(settings: settings, fx: fx, saveSlot: services.savedGame),
    ),
  );
}

class HouseyApp extends StatelessWidget {
  const HouseyApp({super.key, required this.game, required this.services});
  final GameController game;
  final AppServices services;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Housey',
      debugShowCheckedModeBanner: false,
      theme: houseyTheme(),
      home: TableScreen(game: game, services: services),
    );
  }
}
