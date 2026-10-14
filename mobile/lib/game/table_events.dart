import 'dart:async';

import 'package:flutter/foundation.dart';

/// One-off things for the screen to show: toasts, banners, the bag shaking.
sealed class TableEvent {}

class ToastEvent extends TableEvent {
  ToastEvent(this.message);
  final String message;
}

class AnnounceEvent extends TableEvent {
  AnnounceEvent(this.title, this.subtitle, {this.bogey = false});
  final String title, subtitle;
  final bool bogey;
}

class BagShakeEvent extends TableEvent {}

/// What the caller's mat shows. The game and the number caller both drive one.
abstract interface class CallerMatModel implements Listenable {
  Stream<TableEvent> get events;

  /// The coin on the mat, the last few before it (newest first), and what the caller said.
  int? get currentCoin;
  List<int> get tray;
  String get callText;
  String get callCount;

  /// How many numbers have come out; changes each draw so the coin animates in.
  int get drawCount;

  /// Whether the bag should wiggle to invite a tap.
  bool get invitesTap;
  void tapBag();
}

/// The event stream, shared by both controllers.
mixin TableEvents {
  final _events = StreamController<TableEvent>.broadcast();
  Stream<TableEvent> get events => _events.stream;

  void emit(TableEvent e) {
    if (!_events.isClosed) _events.add(e);
  }

  void toast(String message) => emit(ToastEvent(message));
  void closeEvents() => _events.close();
}
