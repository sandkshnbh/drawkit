import 'dart:async';

import 'package:flutter/widgets.dart';

import '../core/style.dart';
import '../core/surface.dart';
import '../engine/rough.dart';
import 'drawkit_button.dart' show DrawkitTone;

/// Handle for a toast shown with [showDrawkitToast].
///
/// Call [close] to dismiss it early; closing an already-dismissed toast is a
/// no-op. Auto-dismiss also routes through here, so the overlay entry is
/// always removed exactly once.
class DrawkitToastHandle {
  DrawkitToastHandle._(this._entry, this._key);

  final OverlayEntry _entry;
  final GlobalKey<_DrawkitToastEntryState> _key;
  bool _removed = false;

  /// Takes the toast down (playing the exit when motion is on).
  void close() {
    if (_removed) return;
    final state = _key.currentState;
    if (state == null) {
      _remove();
    } else {
      state.dismiss();
    }
  }

  void _remove() {
    if (_removed) return;
    _removed = true;
    _entry.remove();
    _entry.dispose();
  }
}

/// Toast the sketch pill, slides and fades in above the bottom edge, lingers
/// for [duration], then lifts away. Taps pass straight through — a toast is
/// informational; give errors a real [DrawkitAlert] if the user must act.
///
/// The returned [DrawkitToastHandle] can close it early.
DrawkitToastHandle showDrawkitToast(
  BuildContext context, {
  required String message,
  DrawkitTone tone = DrawkitTone.accent,
  Duration duration = const Duration(milliseconds: 2400),
  bool animate = true,
  DrawkitStyle? style,
  int? seed,
}) {
  final overlay = Overlay.of(context);
  final key = GlobalKey<_DrawkitToastEntryState>();
  late final DrawkitToastHandle handle;
  final entry = OverlayEntry(
    builder: (context) => IgnorePointer(
      child: _DrawkitToastEntry(
        key: key,
        message: message,
        tone: tone,
        duration: duration,
        animate: animate,
        style: style,
        seed: seed,
        onDismissed: () => handle._remove(),
      ),
    ),
  );
  handle = DrawkitToastHandle._(entry, key);
  overlay.insert(entry);
  return handle;
}

/// The visual pill, exposed for cases that host their own toast queue.
class DrawkitToast extends StatelessWidget {
  const DrawkitToast({
    required this.message,
    this.tone = DrawkitTone.accent,
    this.style,
    this.seed,
    this.animate = true,
    super.key,
  });

  final String message;
  final DrawkitTone tone;
  final DrawkitStyle? style;
  final int? seed;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final resolved = style ?? DrawkitTheme.of(context);
    final ink = switch (tone) {
      DrawkitTone.accent => resolved.ink ?? DrawkitPalette.pen,
      DrawkitTone.neutral => DrawkitPalette.neutral,
      DrawkitTone.danger => DrawkitPalette.error,
    };
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: DrawkitSurface(
        builder: (size, options) => [
          DrawkitLayer(
            roughRoundedRect(
              3,
              3,
              size.width - 6,
              size.height - 6,
              10,
              options,
            ),
            drawkitFillPaint(resolved.paperColor),
          ),
          DrawkitLayer(
            roughRoundedRect(
              3,
              3,
              size.width - 6,
              size.height - 6,
              10,
              options,
            ),
            drawkitStroke(resolved, color: ink),
          ),
        ],
        style: resolved,
        seed: seed,
        animate: animate,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Text(message, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}

class _DrawkitToastEntry extends StatefulWidget {
  const _DrawkitToastEntry({
    required this.message,
    required this.tone,
    required this.duration,
    required this.animate,
    required this.style,
    required this.seed,
    required this.onDismissed,
    super.key,
  });

  final String message;
  final DrawkitTone tone;
  final Duration duration;
  final bool animate;
  final DrawkitStyle? style;
  final int? seed;
  final VoidCallback onDismissed;

  @override
  State<_DrawkitToastEntry> createState() => _DrawkitToastEntryState();
}

class _DrawkitToastEntryState extends State<_DrawkitToastEntry>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  Timer? _timer;
  bool _started = false;
  bool _closing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final motion = widget.animate && !drawkitReduceMotion(context);
    if (motion) {
      _controller.forward();
    } else {
      _controller.value = 1;
    }
    _timer = Timer(widget.duration, dismiss);
  }

  /// Plays the exit (when the toast is still up) and removes the entry.
  void dismiss() {
    if (_closing) return;
    _closing = true;
    _timer?.cancel();
    if (!mounted || _controller.status == AnimationStatus.dismissed) {
      widget.onDismissed();
      return;
    }
    _controller.reverse().whenComplete(() {
      if (mounted) widget.onDismissed();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.bottomCenter,
    child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 28),
        child: FadeTransition(
          opacity: _controller,
          child: SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0, 0.6),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: _controller,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: DrawkitToast(
              message: widget.message,
              tone: widget.tone,
              style: widget.style,
              seed: widget.seed,
              animate: widget.animate,
            ),
          ),
        ),
      ),
    ),
  );
}
