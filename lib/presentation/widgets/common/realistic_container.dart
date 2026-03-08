import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:autocare_pro/core/theme/app_theme.dart';

enum NeumorphicState { convex, concave, flat }

class RealisticContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double borderRadius;
  final Color? color;
  final bool showShadow;
  final bool showGlass;
  final double blur;
  final BoxBorder? border;
  final NeumorphicState state;
  final double depth;

  const RealisticContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.all(0),
    this.borderRadius = 24,
    this.color,
    this.showShadow = true,
    this.showGlass = false,
    this.blur = 10,
    this.border,
    this.state = NeumorphicState.convex,
    this.depth = 10,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final baseColor = color ?? (isDark ? AppTheme.nmBaseDark : AppTheme.nmBaseLight);
    final lightShadow = isDark ? AppTheme.nmLightShadowDark : AppTheme.nmLightShadowLight;
    final darkShadow = isDark ? AppTheme.nmDarkShadowDark : AppTheme.nmDarkShadowLight;

    List<BoxShadow>? shadows;
    if (showShadow && !showGlass) {
      if (state == NeumorphicState.convex) {
        shadows = [
          BoxShadow(
            color: lightShadow,
            offset: Offset(-depth/2, -depth/2),
            blurRadius: depth * 1.5,
          ),
          BoxShadow(
            color: darkShadow,
            offset: Offset(depth/2, depth/2),
            blurRadius: depth * 1.5,
          ),
        ];
      } else if (state == NeumorphicState.concave) {
        // Inner shadows are hard to do in BoxDecoration, 
        // using multiple subtle gradients/borders to simulate depth
        shadows = []; 
      }
    }

    Widget container = Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: border,
        boxShadow: shadows,
      ),
      child: state == NeumorphicState.concave 
        ? _buildConcaveEffect(baseColor, lightShadow, darkShadow)
        : child,
    );

    if (showGlass) {
      return Container(
        margin: margin,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: Container(
              width: width,
              height: height,
              padding: padding,
              decoration: BoxDecoration(
                color: baseColor.withValues(alpha: isDark ? 0.2 : 0.4),
                borderRadius: BorderRadius.circular(borderRadius),
                border: border ?? Border.all(
                  color: Colors.white.withValues(alpha: isDark ? 0.1 : 0.4),
                  width: 1.5,
                ),
              ),
              child: child,
            ),
          ),
        ),
      );
    }

    return Container(
      margin: margin,
      child: container,
    );
  }

  Widget _buildConcaveEffect(Color baseColor, Color lightShadow, Color darkShadow) {
    return Stack(
      children: [
        // Simulated inner shadows using gradients and offsets
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  darkShadow.withValues(alpha: 0.5),
                  baseColor,
                ],
                stops: const [0.0, 0.2],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              gradient: LinearGradient(
                begin: Alignment.bottomRight,
                end: Alignment.topLeft,
                colors: [
                  lightShadow.withValues(alpha: 0.5),
                  baseColor,
                ],
                stops: const [0.0, 0.2],
              ),
            ),
          ),
        ),
        Padding(
          padding: padding,
          child: child,
        ),
      ],
    );
  }
}
