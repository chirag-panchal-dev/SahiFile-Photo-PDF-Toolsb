import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';

enum AppButtonVariant { primary, secondary, outline, text }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final AppButtonVariant variant;
  final double? width;
  final double height;
  final bool isDestructive;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.variant = AppButtonVariant.primary,
    this.width,
    this.height = 50.0,
    this.isDestructive = false,
  });

  const AppButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.width,
    this.height = 50.0,
    this.isDestructive = false,
  }) : variant = AppButtonVariant.secondary;

  const AppButton.outline({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.width,
    this.height = 50.0,
    this.isDestructive = false,
  }) : variant = AppButtonVariant.outline;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEnabled = onPressed != null && !isLoading;

    Widget childContent = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(width: 10),
        ] else if (icon != null) ...[
          Icon(icon, size: 20),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ],
    );

    Widget button;

    switch (variant) {
      case AppButtonVariant.primary:
        button = Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            gradient:
                isEnabled
                    ? (isDestructive
                        ? const LinearGradient(
                          colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                        )
                        : AppColors.primaryGradient)
                    : null,
            color:
                isEnabled ? null : (isDark ? Colors.white10 : Colors.black12),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            boxShadow:
                isEnabled
                    ? [
                      BoxShadow(
                        color: (isDestructive
                                ? AppColors.error
                                : AppColors.accentIndigo)
                            .withValues(alpha: 0.28),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                    : null,
          ),
          child: ElevatedButton(
            onPressed: isEnabled ? onPressed : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white60,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20),
            ),
            child: childContent,
          ),
        );
        break;

      case AppButtonVariant.secondary:
        button = SizedBox(
          width: width,
          height: height,
          child: ElevatedButton(
            onPressed: isEnabled ? onPressed : null,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : const Color(0xFFECEFF8),
              foregroundColor:
                  isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20),
            ),
            child: childContent,
          ),
        );
        break;

      case AppButtonVariant.outline:
        button = SizedBox(
          width: width,
          height: height,
          child: OutlinedButton(
            onPressed: isEnabled ? onPressed : null,
            style: OutlinedButton.styleFrom(
              foregroundColor:
                  isDestructive
                      ? AppColors.error
                      : (isDark
                          ? AppColors.accentIndigoDark
                          : AppColors.accentIndigo),
              side: BorderSide(
                color:
                    isDestructive
                        ? AppColors.error
                        : (isDark
                            ? AppColors.darkGlassBorder
                            : AppColors.lightGlassBorder),
                width: 1.2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20),
            ),
            child: childContent,
          ),
        );
        break;

      case AppButtonVariant.text:
        button = SizedBox(
          width: width,
          height: height,
          child: TextButton(
            onPressed: isEnabled ? onPressed : null,
            style: TextButton.styleFrom(
              foregroundColor:
                  isDestructive
                      ? AppColors.error
                      : (isDark
                          ? AppColors.accentIndigoDark
                          : AppColors.accentIndigo),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: childContent,
          ),
        );
        break;
    }

    return button;
  }
}
