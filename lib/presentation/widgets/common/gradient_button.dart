import 'package:flutter/material.dart';
import 'package:autocare_pro/core/theme/app_theme.dart';

class GradientButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Gradient? gradient;
  final double borderRadius;
  final double? width;
  final double height;
  final bool isLoading;
  final double elevation;

  const GradientButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.gradient,
    this.borderRadius = 16,
    this.width,
    this.height = 56,
    this.isLoading = false,
    this.elevation = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: onPressed != null ? (gradient ?? AppGradients.primary) : null,
        borderRadius: BorderRadius.circular(borderRadius),
        color: onPressed == null ? Colors.grey.withValues(alpha: 0.3) : null,
        boxShadow: onPressed != null && elevation > 0
            ? [
                BoxShadow(
                  color: (gradient?.colors.first ?? AppTheme.primaryColor)
                      .withValues(alpha: 0.3),
                  offset: const Offset(0, 4),
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : DefaultTextStyle.merge(
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    child: child,
                  ),
          ),
        ),
      ),
    );
  }
}
