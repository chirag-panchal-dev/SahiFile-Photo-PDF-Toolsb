import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/glass_surface.dart';
import '../errors/app_error.dart';

enum AppDialogType { error, warning, success, confirmation, info }

class AppDialog extends StatelessWidget {
  final AppDialogType type;
  final String title;
  final String message;
  final String? suggestion;
  final String? technicalDetails;
  final String primaryButtonText;
  final VoidCallback? onPrimaryPressed;
  final String? secondaryButtonText;
  final VoidCallback? onSecondaryPressed;
  final bool isDestructive;

  const AppDialog({
    super.key,
    required this.type,
    required this.title,
    required this.message,
    this.suggestion,
    this.technicalDetails,
    this.primaryButtonText = 'OK',
    this.onPrimaryPressed,
    this.secondaryButtonText,
    this.onSecondaryPressed,
    this.isDestructive = false,
  });

  static Future<bool?> showError(
    BuildContext context, {
    required String title,
    required String message,
    String? suggestion,
    String? technicalDetails,
    String buttonText = 'Understood',
    VoidCallback? onRetry,
  }) {
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss Error Dialog',
      pageBuilder: (ctx, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim1, anim2, child) {
        final curved = CurvedAnimation(
          parent: anim1,
          curve: Curves.easeOutBack,
        );
        return ScaleTransition(
          scale: Tween<double>(begin: 0.88, end: 1.0).animate(curved),
          child: FadeTransition(
            opacity: anim1,
            child: AppDialog(
              type: AppDialogType.error,
              title: title,
              message: message,
              suggestion: suggestion,
              technicalDetails: technicalDetails,
              primaryButtonText: onRetry != null ? 'Retry' : buttonText,
              onPrimaryPressed: () {
                Navigator.of(ctx).pop(true);
                onRetry?.call();
              },
              secondaryButtonText: onRetry != null ? 'Cancel' : null,
              onSecondaryPressed: () => Navigator.of(ctx).pop(false),
            ),
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 240),
    );
  }

  static Future<bool?> showAppError(
    BuildContext context,
    AppError error, {
    VoidCallback? onRetry,
  }) {
    return showError(
      context,
      title: error.title,
      message: error.message,
      suggestion: error.suggestion,
      technicalDetails: error.technicalDetails?.toString(),
      onRetry: onRetry,
    );
  }

  static Future<bool?> showSuccess(
    BuildContext context, {
    required String title,
    required String message,
    String buttonText = 'Great',
    VoidCallback? onDone,
  }) {
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss Success Dialog',
      pageBuilder: (ctx, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim1, anim2, child) {
        final curved = CurvedAnimation(
          parent: anim1,
          curve: Curves.easeOutBack,
        );
        return ScaleTransition(
          scale: Tween<double>(begin: 0.88, end: 1.0).animate(curved),
          child: FadeTransition(
            opacity: anim1,
            child: AppDialog(
              type: AppDialogType.success,
              title: title,
              message: message,
              primaryButtonText: buttonText,
              onPrimaryPressed: () {
                Navigator.of(ctx).pop(true);
                onDone?.call();
              },
            ),
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 240),
    );
  }

  static Future<bool> showConfirmation(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool isDestructive = false,
  }) async {
    final result = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss Confirmation Dialog',
      pageBuilder: (ctx, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim1, anim2, child) {
        final curved = CurvedAnimation(
          parent: anim1,
          curve: Curves.easeOutBack,
        );
        return ScaleTransition(
          scale: Tween<double>(begin: 0.88, end: 1.0).animate(curved),
          child: FadeTransition(
            opacity: anim1,
            child: AppDialog(
              type: AppDialogType.confirmation,
              title: title,
              message: message,
              primaryButtonText: confirmText,
              onPrimaryPressed: () => Navigator.of(ctx).pop(true),
              secondaryButtonText: cancelText,
              onSecondaryPressed: () => Navigator.of(ctx).pop(false),
              isDestructive: isDestructive,
            ),
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 240),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final (iconData, iconColor, iconBgColor) = switch (type) {
      AppDialogType.error => (
        Icons.error_outline_rounded,
        AppColors.error,
        AppColors.errorBg,
      ),
      AppDialogType.warning => (
        Icons.warning_amber_rounded,
        AppColors.warning,
        AppColors.warningBg,
      ),
      AppDialogType.success => (
        Icons.check_circle_outline_rounded,
        AppColors.success,
        AppColors.successBg,
      ),
      AppDialogType.confirmation => (
        isDestructive
            ? Icons.delete_outline_rounded
            : Icons.help_outline_rounded,
        isDestructive ? AppColors.error : AppColors.accentIndigo,
        isDestructive
            ? AppColors.errorBg
            : AppColors.accentIndigo.withValues(alpha: 0.12),
      ),
      AppDialogType.info => (
        Icons.info_outline_rounded,
        AppColors.info,
        AppColors.infoBg,
      ),
    };

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Material(
            color: Colors.transparent,
            child: GlassSurface(
              borderRadius: AppSpacing.radiusXl,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Icon Header
                  Center(
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: iconBgColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: iconColor.withValues(alpha: 0.28),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(iconData, color: iconColor, size: 30),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Title
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color:
                          isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Message
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14.5,
                      height: 1.45,
                      color:
                          isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                    ),
                  ),

                  // Suggestion Callout if present
                  if (suggestion != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : const Color(0xFFF0F4FF),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusSm,
                        ),
                        border: Border.all(
                          color:
                              isDark
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : const Color(0xFFD6E3FF),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.lightbulb_outline_rounded,
                            size: 18,
                            color: AppColors.accentBlue,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              suggestion!,
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.35,
                                fontWeight: FontWeight.w500,
                                color:
                                    isDark
                                        ? AppColors.darkTextPrimary
                                        : const Color(0xFF2C3E66),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Technical details accordion if available
                  if (technicalDetails != null &&
                      technicalDetails!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Details: $technicalDetails',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color:
                            isDark
                                ? AppColors.darkTextSecondary.withValues(
                                  alpha: 0.7,
                                )
                                : AppColors.lightTextSecondary.withValues(
                                  alpha: 0.7,
                                ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 22),

                  // Action Buttons
                  Row(
                    children: [
                      if (secondaryButtonText != null) ...[
                        Expanded(
                          child: OutlinedButton(
                            onPressed:
                                onSecondaryPressed ??
                                () => Navigator.of(context).pop(false),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusMd,
                                ),
                              ),
                              side: BorderSide(
                                color:
                                    isDark
                                        ? AppColors.darkDivider
                                        : AppColors.lightDivider,
                              ),
                            ),
                            child: Text(
                              secondaryButtonText!,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                color:
                                    isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.lightTextPrimary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: ElevatedButton(
                          onPressed:
                              onPrimaryPressed ??
                              () => Navigator.of(context).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isDestructive
                                    ? AppColors.error
                                    : (isDark
                                        ? AppColors.accentIndigoDark
                                        : AppColors.accentIndigo),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusMd,
                              ),
                            ),
                          ),
                          child: Text(
                            primaryButtonText,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
