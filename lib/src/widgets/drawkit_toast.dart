import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../core/motion.dart';
import '../core/style.dart';
import '../core/surface.dart';
import '../engine/rough.dart';
import 'drawkit_text.dart' show DrawkitUnderline;

/// One seat in the toast queue. Unique per request so a release never
/// advances the queue twice for the same toast.
class _ToastTicket {}

/// At most one toast is up kit-wide; later requests wait for their turn
/// instead of stacking sibling overlay entries.
class _DrawkitToastQueue {
  static _ToastTicket? _current;
  static final List<(_ToastTicket, VoidCallback)> _waiting = [];

  static void present(_ToastTicket ticket, VoidCallback show) {
    if (_current == null) {
      _current = ticket;
      show();
    } else {
      _waiting.add((ticket, show));
    }
  }

  static void release(_ToastTicket ticket) {
    if (_current == ticket) {
      _current = null;
      if (_waiting.isNotEmpty) {
        final next = _waiting.removeAt(0);
        _current = next.$1;
        next.$2();
      }
      return;
    }
    _waiting.removeWhere((entry) => entry.$1 == ticket);
  }
}

/// Handle for a toast shown with [showDrawkitToast].
///
/// Call [close] to dismiss it early; closing an already-dismissed toast is a
/// no-op. Auto-dismiss also routes through here, so the overlay entry is
/// always removed exactly once.
class DrawkitToastHandle {
  DrawkitToastHandle._(this._entry, this._key, this._ticket, this._onDismissed);

  final OverlayEntry _entry;
  final GlobalKey<_DrawkitToastEntryState> _key;
  final _ToastTicket _ticket;
  final VoidCallback? _onDismissed;
  bool _removed = false;
  bool _inserted = false;

  /// False once the toast has been dismissed (early or by timeout).
  bool get isVisible => !_removed;

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

  void _insert(OverlayState overlay) {
    if (_removed || _inserted) return;
    _inserted = true;
    overlay.insert(_entry);
  }

  void _remove() {
    if (_removed) return;
    _removed = true;
    _onDismissed?.call();
    _DrawkitToastQueue.release(_ticket);
    if (_inserted) {
      _entry.remove();
      _entry.dispose();
    }
  }
}

/// A single choice offered on a toast — typically Undo or Retry.
class DrawkitToastAction {
  const DrawkitToastAction({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;
}

/// Toast the sketch pill, slides and fades in at [alignment], lingers for
/// [duration], then lifts away. One toast at a time: requests made while one
/// is up wait their turn.
///
/// Without an [action] taps pass straight through — a toast is informational;
/// give errors a real [DrawkitAlert] if the user must act. With an [action]
/// the pill becomes interactive: the action is keyboard-focusable, runs its
/// callback, and the toast closes itself right after (Undo semantics). The
/// default linger is longer when an action is present so there is time to
/// reach it, and hoisting the pointer or focusing the action pauses the
/// countdown until the pointer leaves again (WCAG 2.2.1).
///
/// The returned [DrawkitToastHandle] can close it early; [onDismissed] fires
/// exactly once whenever the toast leaves, however it left.
DrawkitToastHandle showDrawkitToast(
  BuildContext context, {
  required String message,
  DrawkitTone tone = DrawkitTone.accent,
  Duration? duration,
  DrawkitToastAction? action,
  bool animate = true,
  DrawkitStyle? style,
  int? seed,
  AlignmentGeometry alignment = Alignment.bottomCenter,
  EdgeInsetsGeometry? margin,
  double? width,
  bool showCloseIcon = false,
  String closeLabel = 'close',
  DismissDirection dismissDirection = DismissDirection.none,
  VoidCallback? onDismissed,
}) {
  final overlay = Overlay.of(context);
  final resolved = style ?? DrawkitTheme.of(context);
  final linger =
      duration ??
      (action == null ? DrawkitToast.plainLinger : DrawkitToast.actionLinger);
  final key = GlobalKey<_DrawkitToastEntryState>();
  final ticket = _ToastTicket();
  late final DrawkitToastHandle handle;
  final entry = OverlayEntry(
    builder: (context) {
      final toast = DrawkitTheme(
        data: resolved,
        child: DefaultTextStyle(
          style: drawkitRouteTextStyle(resolved),
          child: _DrawkitToastEntry(
            key: key,
            message: message,
            tone: tone,
            duration: linger,
            action: action,
            animate: animate,
            style: resolved,
            seed: seed,
            alignment: alignment,
            margin: margin,
            width: width,
            showCloseIcon: showCloseIcon,
            closeLabel: closeLabel,
            dismissDirection: dismissDirection,
            ticket: ticket,
            onDismissed: () => handle._remove(),
          ),
        ),
      );
      return action == null && !showCloseIcon && !_swipes(dismissDirection)
          ? IgnorePointer(child: toast)
          : toast;
    },
  );
  handle = DrawkitToastHandle._(entry, key, ticket, onDismissed);
  _DrawkitToastQueue.present(ticket, () => handle._insert(overlay));
  return handle;
}

bool _swipes(DismissDirection direction) => direction != DismissDirection.none;

/// The visual pill, exposed for cases that host their own toast queue.
class DrawkitToast extends StatelessWidget {
  const DrawkitToast({
    required this.message,
    this.tone = DrawkitTone.accent,
    this.action,
    this.style,
    this.seed,
    this.animate = true,
    this.width,
    this.showCloseIcon = false,
    this.closeLabel = 'close',
    this.onClose,
    super.key,
  });

  /// Default linger of a toast without an action.
  static const Duration plainLinger = Duration(milliseconds: 2400);

  /// Default linger when an action is present — long enough to reach it.
  static const Duration actionLinger = Duration(milliseconds: 5000);

  final String message;
  final DrawkitTone tone;
  final DrawkitToastAction? action;
  final DrawkitStyle? style;
  final int? seed;
  final bool animate;

  /// Fixed pill width; when null the pill hugs its content under 420px.
  final double? width;

  final bool showCloseIcon;
  final String closeLabel;

  /// Fired by the built-in close control; wire it to your queue's dismiss.
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final resolved = style ?? DrawkitTheme.of(context);
    final ink = switch (tone) {
      DrawkitTone.accent => resolved.ink ?? resolved.palette.pen,
      DrawkitTone.neutral => resolved.palette.neutral,
      DrawkitTone.danger => resolved.palette.error,
    };
    final body = Semantics(
      container: true,
      liveRegion: true,
      label: message,
      child: ExcludeSemantics(
        child: Text(
          message,
          textAlign: action == null ? TextAlign.center : TextAlign.start,
        ),
      ),
    );
    final tail = <Widget>[
      if (action != null)
        _DrawkitToastActionButton(
          action: action!,
          animate: animate,
          style: resolved,
        ),
      if (showCloseIcon)
        _DrawkitToastCloseButton(
          label: closeLabel,
          onPressed: onClose,
          style: resolved,
        ),
    ];
    final content = DrawkitSurface(
      builder: (size, options) => [
        DrawkitLayer(
          roughRoundedRect(3, 3, size.width - 6, size.height - 6, 10, options),
          drawkitFillPaint(resolved.paperColor),
        ),
        DrawkitLayer(
          roughRoundedRect(3, 3, size.width - 6, size.height - 6, 10, options),
          drawkitStroke(resolved, color: ink),
        ),
      ],
      style: resolved,
      seed: seed,
      animate: animate,
      child: DefaultTextStyle(
        style: DefaultTextStyle.of(context).style
            .copyWith(color: resolved.palette.ink),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: tail.isEmpty
              ? body
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(child: body),
                    const SizedBox(width: 16),
                    for (var i = 0; i < tail.length; i++) ...[
                      if (i > 0) const SizedBox(width: 10),
                      tail[i],
                    ],
                  ],
                ),
        ),
      ),
    );
    if (width != null) return SizedBox(width: width, child: content);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: content,
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
    required this.style,
  });

  final DrawkitToastAction action;
  final bool animate;
  final DrawkitStyle style;

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
          onTap: widget.action.onPressed,
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
                        ? widget.style.palette.pen
                        : widget.style.palette.ink,
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

/// A drawn ✕ at the end of the pill. Focusable and labeled with [label].
class _DrawkitToastCloseButton extends StatefulWidget {
  const _DrawkitToastCloseButton({
    required this.label,
    required this.onPressed,
    required this.style,
  });

  final String label;
  final VoidCallback? onPressed;
  final DrawkitStyle style;

  @override
  State<_DrawkitToastCloseButton> createState() =>
      _DrawkitToastCloseButtonState();
}

class _DrawkitToastCloseButtonState extends State<_DrawkitToastCloseButton> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
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
              widget.onPressed?.call();
              return null;
            },
          ),
        },
        mouseCursor: SystemMouseCursors.click,
        child: Semantics(
          container: true,
          button: true,
          label: widget.label,
          onTap: widget.onPressed,
          child: ExcludeSemantics(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onPressed,
              child: MouseRegion(
                onEnter: (_) => setState(() => _hovered = true),
                onExit: (_) => setState(() => _hovered = false),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: DrawkitSurface(
                    builder: (size, options) => [
                      DrawkitLayer(
                        roughLine(
                          4,
                          4,
                          size.width - 4,
                          size.height - 4,
                          options,
                        ),
                        drawkitStroke(
                          widget.style,
                          color: active ? widget.style.palette.pen : null,
                          fallbackWidth: 1.5,
                        ),
                      ),
                      DrawkitLayer(
                        roughLine(
                          size.width - 4,
                          4,
                          4,
                          size.height - 4,
                          options,
                        ),
                        drawkitStroke(
                          widget.style,
                          color: active ? widget.style.palette.pen : null,
                          fallbackWidth: 1.5,
                        ),
                      ),
                    ],
                    style: widget.style,
                    animate: false,
                    size: const Size(18, 18),
                  ),
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
    required this.alignment,
    required this.margin,
    required this.width,
    required this.showCloseIcon,
    required this.closeLabel,
    required this.dismissDirection,
    required this.ticket,
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
  final AlignmentGeometry alignment;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final bool showCloseIcon;
  final String closeLabel;
  final DismissDirection dismissDirection;
  final _ToastTicket ticket;
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
  final Stopwatch _clock = Stopwatch();
  Duration _remaining = Duration.zero;
  bool _paused = false;
  bool _started = false;
  bool _closing = false;
  bool _motion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _motion = widget.animate && !drawkitReduceMotion(context);
    if (_motion) {
      _controller.forward();
    } else {
      _controller.value = 1;
    }
    _remaining = widget.duration;
    _startLinger();
  }

  void _startLinger() {
    _timer?.cancel();
    _clock
      ..reset()
      ..start();
    _timer = Timer(_remaining, dismiss);
  }

  void _pauseLinger() {
    if (_paused || _closing) return;
    _paused = true;
    _timer?.cancel();
    _clock.stop();
    _remaining -= _clock.elapsed;
    if (_remaining < Duration.zero) _remaining = Duration.zero;
  }

  void _resumeLinger() {
    if (!_paused || _closing) return;
    _paused = false;
    if (_remaining <= Duration.zero) {
      dismiss();
      return;
    }
    _startLinger();
  }

  /// Plays the exit (when the toast is still up) and removes the entry.
  void dismiss() {
    if (_closing) return;
    _closing = true;
    _timer?.cancel();
    if (!mounted ||
        !_motion ||
        _controller.status == AnimationStatus.dismissed) {
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
    _DrawkitToastQueue.release(widget.ticket);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget pill = DrawkitToast(
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
      width: widget.width,
      showCloseIcon: widget.showCloseIcon,
      closeLabel: widget.closeLabel,
      onClose: dismiss,
    );
    if (_swipes(widget.dismissDirection)) {
      pill = Dismissible(
        key: const ValueKey('drawkit-toast'),
        direction: widget.dismissDirection,
        onDismissed: (_) => dismiss(),
        child: pill,
      );
    }
    return Align(
      alignment: widget.alignment,
      child: SafeArea(
        child: Focus(
          canRequestFocus: false,
          onFocusChange: (hasFocus) =>
              hasFocus ? _pauseLinger() : _resumeLinger(),
          child: MouseRegion(
            onEnter: (_) => _pauseLinger(),
            onExit: (_) => _resumeLinger(),
            child: Padding(
              padding: widget.margin ?? const EdgeInsets.only(bottom: 28),
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
                  child: pill,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
