import 'package:flutter/material.dart';
import 'package:autocare_pro/core/theme/app_theme.dart';

enum NeumorphicStyle { raised, pressed }

class NeumorphicContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double borderRadius;
  final NeumorphicStyle style;
  final bool useThemeBackground;
  final Color? color;

  const NeumorphicContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.all(0),
    this.borderRadius = 16,
    this.style = NeumorphicStyle.raised,
    this.useThemeBackground = true,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final baseColor = color ?? (useThemeBackground
        ? (isDark ? AppTheme.nmBaseDark : AppTheme.nmBaseLight)
        : Theme.of(context).colorScheme.surface);

    final lightShadow = isDark ? AppTheme.nmLightShadowDark : AppTheme.nmLightShadowLight;
    final darkShadow = isDark ? AppTheme.nmDarkShadowDark : AppTheme.nmDarkShadowLight;

    return Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: style == NeumorphicStyle.raised
            ? [
                BoxShadow(
                  color: lightShadow,
                  offset: const Offset(-5, -5),
                  blurRadius: 10,
                ),
                BoxShadow(
                  color: darkShadow,
                  offset: const Offset(5, 5),
                  blurRadius: 10,
                ),
              ]
            : null, // Pressed style usually uses inner shadows (hard in vanilla Flutter without external packages, so we'll simulate with slightly darker color)
        border: style == NeumorphicStyle.pressed
            ? Border.all(color: darkShadow.withOpacity(0.5), width: 1)
            : null,
      ),
      child: child,
    );
  }
}
