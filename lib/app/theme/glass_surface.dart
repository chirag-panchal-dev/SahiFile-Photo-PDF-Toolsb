import 'dart:ui';
import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart';

class GlassSurface extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blur;
  final Color? customBgColor;
  final Color? customBorderColor;
  final VoidCallback? onTap;
  final bool showShadow;
  final Gradient? customGradient;

  const GlassSurface({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius = AppSpacing.radiusLg,
    this.blur = 12.0,
    this.customBgColor,
    this.customBorderColor,
    this.onTap,
    this.showShadow = true,
    this.customGradient,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor =
        customBgColor ??
        (isDark ? AppColors.darkGlassSurface : AppColors.lightGlassSurface);

    final borderColor =
        customBorderColor ??
        (isDark ? AppColors.darkGlassBorder : AppColors.lightGlassBorder);

    Widget content = Container(
      width: width,
      height: height,
      padding: padding ?? AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: customGradient == null ? bgColor : null,
        gradient: customGradient,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow:
            showShadow
                ? [
                  BoxShadow(
                    color:
                        isDark
                            ? Colors.black.withValues(alpha: 0.25)
                            : const Color(0xFF172033).withValues(alpha: 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ]
                : null,
      ),
      child: child,
    );

    if (blur > 0) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: content,
        ),
      );
    } else {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: content,
      );
    }

    if (margin != null) {
      content = Padding(padding: margin!, child: content);
    }

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: content,
        ),
      );
    }

    return content;
  }
}
