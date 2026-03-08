import 'package:flutter/material.dart';
import 'package:autocare_pro/presentation/widgets/common/realistic_container.dart';

class NeumorphicButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double borderRadius;
  final double padding;
  final Color? color;
  final double depth;

  const NeumorphicButton({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius = 16,
    this.padding = 16,
    this.color,
    this.depth = 10,
  });

  @override
  State<NeumorphicButton> createState() => _NeumorphicButtonState();
}

class _NeumorphicButtonState extends State<NeumorphicButton> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onTap,
      child: RealisticContainer(
        padding: EdgeInsets.all(widget.padding),
        borderRadius: widget.borderRadius,
        color: widget.color,
        state: _isPressed ? NeumorphicState.concave : NeumorphicState.convex,
        depth: widget.depth,
        child: widget.child,
      ),
    );
  }
}

class NeumorphicIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final Color? color;

  const NeumorphicIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.size = 24,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return NeumorphicButton(
      onTap: onTap,
      borderRadius: 12,
      padding: 10,
      child: Icon(icon, size: size, color: color),
    );
  }
}
