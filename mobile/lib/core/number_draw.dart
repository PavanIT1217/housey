// The bag of 90 numbers: draws, undo, and a JSON form for saving.
// The game and the number caller both draw through this.

import 'dart:math';

import 'tickets.dart';

class NumberDraw {
  NumberDraw._(this._remaining, this._called);

  /// A full bag in a fair random order.
  factory NumberDraw.shuffled([Random? random]) =>
      NumberDraw._(List.generate(highestNumber, (i) => i + 1)..shuffle(random ?? Random.secure()), []);

  final List<int> _remaining;
  final List<int> _called;

  /// Rebuilds a saved draw, or returns null if the data isn't a valid bag.
  static NumberDraw? fromJson(Object? json) {
    if (json is! Map) return null;
    final remaining = json['remaining'], called = json['called'];
    if (remaining is! List || called is! List) return null;
    final all = [...remaining, ...called];
    final valid =
        all.length == highestNumber &&
        all.every((n) => n is int && n >= 1 && n <= highestNumber) &&
        all.toSet().length == highestNumber;
    return valid ? NumberDraw._(remaining.cast<int>().toList(), called.cast<int>().toList()) : null;
  }

  Map<String, Object> toJson() => {'remaining': List.of(_remaining), 'called': List.of(_called)};

  /// Numbers called so far, oldest first.
  List<int> get called => List.unmodifiable(_called);
  int get count => _called.length;
  int? get last => _called.isEmpty ? null : _called.last;
  bool get isFinished => _remaining.isEmpty;
  bool has(int n) => _called.contains(n);

  /// Takes the next number out of the bag, or null when it's empty.
  int? next() {
    if (_remaining.isEmpty) return null;
    final n = _remaining.removeLast();
    _called.add(n);
    return n;
  }

  /// Puts the last number back on top of the bag (it comes out next).
  int? undo() {
    if (_called.isEmpty) return null;
    final n = _called.removeLast();
    _remaining.add(n);
    return n;
  }
}
