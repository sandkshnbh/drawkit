import 'package:flutter/widgets.dart';

import '../core/style.dart';
import '../core/surface.dart';
import '../engine/rough.dart';
import 'drawkit_button.dart';

const double _inset = 3;

/// A whole-number stepper: sketched minus and plus around a framed value.
///
/// The buttons disable themselves at [min] and [max] (and when [onChanged]
/// is null the whole control is inert); every press reports `value ± step`
/// already clamped.
class DrawkitStepper extends StatelessWidget {
  const DrawkitStepper({
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 100,
    this.step = 1,
    this.semanticLabel,
    this.style,
    this.seed,
    this.animate = true,
    super.key,
  });

  final int value;

  /// Null disables the stepper.
  final ValueChanged<int>? onChanged;

  final int min;
  final int max;
  final int step;
  final String? semanticLabel;
  final DrawkitStyle? style;
  final int? seed;
  final bool animate;

  void _report(int next) => onChanged!(next.clamp(min, max).toInt());

  @override
  Widget build(BuildContext context) {
    final resolvedStyle = style ?? DrawkitTheme.of(context);
    final enabled = onChanged != null;
    final canDecrease = enabled && value > min;
    final canIncrease = enabled && value < max;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DrawkitIconButton(
          semanticLabel: 'decrease',
          size: 30,
          variant: DrawkitButtonVariant.outline,
          style: resolvedStyle,
          seed: seed,
          animate: animate,
          onPressed: canDecrease ? () => _report(value - step) : null,
          child: const Text('−', textAlign: TextAlign.center),
        ),
        const SizedBox(width: 6),
        Semantics(
          label: semanticLabel,
          value: '$value',
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 52),
            child: DrawkitSurface(
              builder: (size, options) => [
                DrawkitLayer(
                  roughRoundedRect(
                    _inset,
                    _inset,
                    size.width - 2 * _inset,
                    size.height - 2 * _inset,
                    6,
                    options,
                  ),
                  drawkitStroke(resolvedStyle),
                ),
              ],
              style: resolvedStyle,
              seed: seed,
              animate: animate,
              enabled: enabled,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Center(
                  widthFactor: 1,
                  child: Text('$value', textAlign: TextAlign.center),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        DrawkitIconButton(
          semanticLabel: 'increase',
          size: 30,
          variant: DrawkitButtonVariant.outline,
          style: resolvedStyle,
          seed: seed,
          animate: animate,
          onPressed: canIncrease ? () => _report(value + step) : null,
          child: const Text('+', textAlign: TextAlign.center),
        ),
      ],
    );
  }
}
