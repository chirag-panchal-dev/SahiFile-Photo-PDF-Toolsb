import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/glass_surface.dart';

class LoadingOverlay extends StatelessWidget {
  final String message;
  final String? subMessage;
  final VoidCallback? onCancel;

  const LoadingOverlay({
    super.key,
    required this.message,
    this.subMessage,
    this.onCancel,
  });

  static Future<T> show<T>({
    required BuildContext context,
    required String message,
    String? subMessage,
    required Future<T> Function() asyncWork,
  }) async {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Processing',
      pageBuilder:
          (ctx, anim1, anim2) => PopScope(
            canPop: false,
            child: LoadingOverlay(message: message, subMessage: subMessage),
          ),
      transitionBuilder:
          (ctx, anim1, anim2, child) =>
              FadeTransition(opacity: anim1, child: child),
      transitionDuration: const Duration(milliseconds: 180),
    );

    try {
      final result = await asyncWork();
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      return result;
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 300),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Material(
            color: Colors.transparent,
            child: GlassSurface(
              borderRadius: AppSpacing.radiusLg,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 44,
                    height: 44,
                    child: CircularProgressIndicator(
                      strokeWidth: 3.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.accentIndigo,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color:
                          isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                    ),
                  ),
                  if (subMessage != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      subMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.5,
                        color:
                            isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
