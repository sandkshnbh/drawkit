import 'package:flutter/widgets.dart';

/// Keyboard vocabulary shared by the focusable controls.
///
/// These classes stay internal to the package (they are not exported from
/// `drawkit.dart`): each widget family wires the same activator → intent →
/// action maps, so the intents live here once instead of per file.

/// Moves a cursor/selection by [delta] steps (list rows, tabs…).
class DrawkitMoveIntent extends Intent {
  const DrawkitMoveIntent(this.delta);

  final int delta;
}

/// Steps a continuous value by [delta] increments of the widget's own step
/// size (sliders), never a raw pixel amount.
class DrawkitAdjustIntent extends Intent {
  const DrawkitAdjustIntent(this.delta);

  final double delta;
}

/// Jumps to the first ([end] false) or last ([end] true) stop.
class DrawkitEdgeIntent extends Intent {
  const DrawkitEdgeIntent(this.end);

  final bool end;
}

/// Pages a date picker by [months].
class DrawkitPageIntent extends Intent {
  const DrawkitPageIntent(this.months);

  final int months;
}

/// Swallows an activator without moving anything.
class DrawkitNoopIntent extends Intent {
  const DrawkitNoopIntent();
}

/// Closes an overlay (command palette Escape).
class DrawkitDismissIntent extends Intent {
  const DrawkitDismissIntent();
}
