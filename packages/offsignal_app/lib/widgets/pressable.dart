import 'package:flutter/material.dart';

import '../core/theme/design_tokens.dart';
import '../core/theme/motion.dart';

class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    required this.onPressed,
    this.semanticLabel,
    this.pressedScale = 0.96,
    this.pressedOpacity = 0.82,
    this.minSize = AppSizes.minTapTarget,
    this.behavior = HitTestBehavior.opaque,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final String? semanticLabel;
  final double pressedScale;
  final double pressedOpacity;
  final double minSize;
  final HitTestBehavior behavior;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _isPressed = false;

  bool get _isEnabled => widget.onPressed != null;

  void _setPressed(bool value) {
    if (!_isEnabled || _isPressed == value) return;
    setState(() => _isPressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final pressed = _isPressed && _isEnabled;

    return Semantics(
      button: true,
      enabled: _isEnabled,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: widget.behavior,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: widget.onPressed,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: widget.minSize,
            minHeight: widget.minSize,
          ),
          child: AnimatedScale(
            scale: pressed ? widget.pressedScale : 1,
            duration: AppMotion.resolve(
              context,
              pressed ? AppMotion.pressDown : AppMotion.pressUp,
            ),
            curve: AppMotion.pressCurve,
            child: AnimatedOpacity(
              opacity: _isEnabled ? (pressed ? widget.pressedOpacity : 1) : 0.45,
              duration: AppMotion.resolve(context, AppMotion.pressUp),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
