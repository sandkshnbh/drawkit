import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../core/style.dart';
import '../core/surface.dart';
import '../engine/rough.dart';
import 'drawkit_button.dart' show DrawkitTone;
import 'drawkit_text.dart' show DrawkitUnderline;

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

/// A single choice offered on a toast — typically Undo or Retry.
class DrawkitToastAction {
  const DrawkitToastAction({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;
}

/// Toast the sketch pill, slides and fades in above the bottom edge, lingers
/// for [duration], then lifts away.
///
/// Without an [action] taps pass straight through — a toast is informational;
/// give errors a real [DrawkitAlert] if the user must act. With an [action]
/// the pill becomes interactive: the action is keyboard-focusable, runs its
/// callback, and the toast closes itself right after (Undo semantics). The
/// default linger is longer when an action is present so there is time to
/// reach it.
///
/// The returned [DrawkitToastHandle] can close it early.
DrawkitToastHandle showDrawkitToast(
  BuildContext context, {
  required String message,
  DrawkitTone tone = DrawkitTone.accent,
  Duration? duration,
  DrawkitToastAction? action,
  bool animate = true,
  DrawkitStyle? style,
  int? seed,
}) {
  final overlay = Overlay.of(context);
  final linger =
      duration ?? Duration(milliseconds: action == null ? 2400 : 5000);
  final key = GlobalKey<_DrawkitToastEntryState>();
  late final DrawkitToastHandle handle;
  final entry = OverlayEntry(
    builder: (context) {
      final toast = _DrawkitToastEntry(
        key: key,
        message: message,
        tone: tone,
        duration: linger,
        action: action,
        animate: animate,
        style: style,
        seed: seed,
        onDismissed: () => handle._remove(),
      );
      return action == null ? IgnorePointer(child: toast) : toast;
    },
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
    this.action,
    this.style,
    this.seed,
    this.animate = true,
    super.key,
  });

  final String message;
  final DrawkitTone tone;
  final DrawkitToastAction? action;
  final DrawkitStyle? style;
  final int? seed;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final resolved = style ?? DrawkitTheme.of(context);
    final ink = switch (tone) {
      DrawkitTone.accent => resolved.ink ?? resolved.palette.pen,
      DrawkitTone.neutral => resolved.palette.neutral,
      DrawkitTone.danger => resolved.palette.error,
    };
    final body = Text(
      message,
      textAlign: action == null ? TextAlign.center : TextAlign.start,
    );
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
          child: action == null
              ? body
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(child: body),
                    const SizedBox(width: 16),
                    _DrawkitToastActionButton(
                      action: action!,
                      animate: animate,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// The underlined verb on the right of the pill: hover or keyboard focus
/// re-inks it in pen blue, Enter/Space activate, and the label carries the
/// button semantics.
class _DrawkitToastActionButton extends StatefulWidget {
  const _DrawkitToastActionButton({
    required this.action,
    required this.animate,
  });

  final DrawkitToastAction action;
  final bool animate;

  @override
  State<_DrawkitToastActionButton> createState() =>
      _DrawkitToastActionButtonState();
}

class _DrawkitToastActionButtonState extends State<_DrawkitToastActionButton> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final base = DefaultTextStyle.of(context).style;
    final active = _hovered || _focused;
    return Shortcuts(
      shortcuts: {
        const SingleActivator(LogicalKeyboardKey.enter): const ActivateIntent(),
        const SingleActivator(LogicalKeyboardKey.space): const ActivateIntent(),
      },
      child: FocusableActionDetector(
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (intent) {
              widget.action.onPressed();
              return null;
            },
          ),
        },
        mouseCursor: SystemMouseCursors.click,
        child: Semantics(
          container: true,
          button: true,
          label: widget.action.label,
          child: ExcludeSemantics(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.action.onPressed,
              child: MouseRegion(
                onEnter: (_) => setState(() => _hovered = true),
                onExit: (_) => setState(() => _hovered = false),
                child: DrawkitUnderline(
                  text: widget.action.label,
                  textStyle: base.copyWith(
                    color: active
                        ? DrawkitTheme.of(context).palette.pen
                        : DrawkitTheme.of(context).palette.ink,
                    fontWeight: FontWeight.w600,
                  ),
                  animate: widget.animate,
                ),
              ),
            ),
          ),
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
    required this.action,
    required this.animate,
    required this.style,
    required this.seed,
    required this.onDismissed,
    super.key,
  });

  final String message;
  final DrawkitTone tone;
  final Duration duration;
  final DrawkitToastAction? action;
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
              action: widget.action == null
                  ? null
                  : DrawkitToastAction(
                      label: widget.action!.label,
                      onPressed: () {
                        widget.action!.onPressed();
                        dismiss();
                      },
                    ),
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
