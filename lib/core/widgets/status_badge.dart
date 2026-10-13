import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';

enum StatusBadgeType { neutral, primary, success, warning, error, info }

class StatusBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final StatusBadgeType type;

  const StatusBadge({
    super.key,
    required this.label,
    this.icon,
    this.type = StatusBadgeType.neutral,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final (bgColor, textColor, borderColor) = switch (type) {
      StatusBadgeType.neutral => (
        isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF0F3F9),
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
        isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFE2E7F1),
      ),
      StatusBadgeType.primary => (
        (isDark ? AppColors.accentIndigoDark : AppColors.accentIndigo)
            .withValues(alpha: 0.12),
        isDark ? AppColors.accentIndigoDark : AppColors.accentIndigo,
        (isDark ? AppColors.accentIndigoDark : AppColors.accentIndigo)
            .withValues(alpha: 0.28),
      ),
      StatusBadgeType.success => (
        AppColors.successBg,
        AppColors.success,
        AppColors.success.withValues(alpha: 0.28),
      ),
      StatusBadgeType.warning => (
        AppColors.warningBg,
        AppColors.warning,
        AppColors.warning.withValues(alpha: 0.28),
      ),
      StatusBadgeType.error => (
        AppColors.errorBg,
        AppColors.error,
        AppColors.error.withValues(alpha: 0.28),
      ),
      StatusBadgeType.info => (
        AppColors.infoBg,
        AppColors.info,
        AppColors.info.withValues(alpha: 0.28),
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
