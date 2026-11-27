import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';

/// Slides [child] sideways to reveal a rounded delete button on the END side.
///
/// "End" follows the ambient [Directionality]: the card slides left in LTR and
/// right in RTL, so the gesture always moves toward the side the button sits
/// on. The card never leaves the tree, so list state is untouched while the
/// button is shown; deletion is an explicit tap on the button.
class CartSwipeReveal extends StatefulWidget {
  const CartSwipeReveal({
    required this.child,
    required this.onDelete,
    required this.deleteLabel,
    super.key,
  });

  final Widget child;
  final VoidCallback onDelete;
  final String deleteLabel;

  @override
  State<CartSwipeReveal> createState() => _CartSwipeRevealState();
}

class _CartSwipeRevealState extends State<CartSwipeReveal>
    with SingleTickerProviderStateMixin {
  static const double _actionWidth = 64;
  static const double _gap = 10;
  static const double _reveal = _actionWidth + _gap;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// +1 when a positive horizontal delta opens the action (RTL), -1 in LTR.
  double _openSign(BuildContext context) =>
      Directionality.of(context) == TextDirection.rtl ? 1 : -1;

  void _animateTo(double value) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) {
      _controller.value = value;
    } else {
      _controller.animateTo(value, curve: Curves.easeOutCubic);
    }
  }

  void _close() => _animateTo(0);

  @override
  Widget build(BuildContext context) {
    final sign = _openSign(context);
    final colors = Theme.of(context).extension<AppSemanticColors>() ??
        AppSemanticColors.light;
    final error = Theme.of(context).colorScheme.error;
    final direction = Directionality.of(context);

    return Semantics(
      customSemanticsActions: <CustomSemanticsAction, VoidCallback>{
        CustomSemanticsAction(label: widget.deleteLabel): widget.onDelete,
      },
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragUpdate: (details) {
          final delta = details.primaryDelta ?? 0;
          _controller.value =
              (_controller.value + delta * sign / _reveal).clamp(0.0, 1.0);
        },
        onHorizontalDragEnd: (details) {
          final velocity = (details.primaryVelocity ?? 0) * sign;
          if (velocity > 350) {
            _animateTo(1);
          } else if (velocity < -350) {
            _animateTo(0);
          } else {
            _animateTo(_controller.value > .45 ? 1 : 0);
          }
        },
        child: Stack(
          children: <Widget>[
            Positioned.directional(
              textDirection: direction,
              end: 0,
              top: 0,
              bottom: 0,
              width: _actionWidth,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) => IgnorePointer(
                  ignoring: _controller.value < .5,
                  child: Opacity(opacity: _controller.value, child: child),
                ),
                child: Material(
                  color: colors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.xlargeRadius,
                    side: BorderSide(color: colors.border),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    key: const Key('cart_swipe_delete'),
                    onTap: () {
                      _close();
                      widget.onDelete();
                    },
                    child: Tooltip(
                      message: widget.deleteLabel,
                      child: Center(
                        child: Icon(
                          Icons.delete_outline_rounded,
                          color: error,
                          size: 26,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) => Transform.translate(
                offset: Offset(sign * _controller.value * _reveal, 0),
                child: child,
              ),
              child: widget.child,
            ),
          ],
        ),
      ),
    );
  }
}
