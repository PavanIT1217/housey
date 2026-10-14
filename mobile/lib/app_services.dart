import 'services/fx.dart';
import 'services/settings.dart';
import 'services/storage.dart';

/// What every screen shares: saved data, settings, and sound and voice.
class AppServices {
  AppServices({required this.store, required this.settings, required this.fx});

  /// Silent, in-memory services for tests.
  factory AppServices.forTests({Settings? settings}) {
    final store = MemoryStore();
    return AppServices(store: store, settings: settings ?? Settings(store), fx: Fx());
  }

  final KeyValueStore store;
  final Settings settings;
  final Fx fx;

  JsonRecord get savedGame => JsonRecord(store, StoreKeys.savedGame, 1);
  JsonRecord get callerSession => JsonRecord(store, StoreKeys.callerSession, 1);
  JsonRecord get myTickets => JsonRecord(store, StoreKeys.myTickets, 1);
  JsonRecord get printOptions => JsonRecord(store, StoreKeys.printOptions, 1);
}
