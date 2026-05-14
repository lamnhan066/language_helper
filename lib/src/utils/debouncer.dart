import 'dart:async';
import 'dart:ui';

/// A simple debouncer class to prevent rapid consecutive calls to a function.
class Debouncer {
  /// Creates a [Debouncer] with the specified debounce duration
  /// in milliseconds.
  Debouncer({this.milliseconds = 100});

  /// The debounce duration in milliseconds.
  final int milliseconds;
  Timer? _timer;

  /// Runs the provided [action] after the debounce duration has passed.
  void run(VoidCallback action) {
    if (_timer != null) {
      _timer!.cancel();
    }
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }
}
