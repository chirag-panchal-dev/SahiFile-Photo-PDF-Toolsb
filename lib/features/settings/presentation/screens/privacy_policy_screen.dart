import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/glass_surface.dart';
import '../../../../core/widgets/glass_app_bar.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: const GlassAppBar(title: 'Privacy Policy'),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            GlassSurface(
              borderRadius: AppSpacing.radiusLg,
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.successBg,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusSm,
                          ),
                        ),
                        child: const Icon(
                          Icons.verified_user_rounded,
                          color: AppColors.success,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '100% Local Processing',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color:
                                    isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.lightTextPrimary,
                              ),
                            ),
                            const Text(
                              'Your documents never leave your phone',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _PolicySection(
                    title: '1. No Server Uploads',
                    content:
                        'SahiFile executes all image resizing, cropping, compression, and PDF generation directly on your Android device hardware. We do not operate any server that receives, stores, or processes your personal documents.',
                  ),
                  _PolicySection(
                    title: '2. Scoped File Access',
                    content:
                        'The app uses the Android System Photo Picker and Storage Access Framework. It only accesses files you explicitly pick. SahiFile never requests broad media access or MANAGE_EXTERNAL_STORAGE permission.',
                  ),
                  _PolicySection(
                    title: '3. Non-Destructive Editing',
                    content:
                        'Your original input photos and PDFs are never modified or overwritten. All operations create an independent working copy in the app sandbox.',
                  ),
                  _PolicySection(
                    title: '4. No Tracking or Analytics',
                    content:
                        'SahiFile does not track your location, contacts, device identifiers, or biometric information. No account or login is required.',
                  ),
                  _PolicySection(
                    title: '5. Contact & Support',
                    content:
                        'For questions or privacy concerns regarding SahiFile, contact support@sahifile.app.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  final String title;
  final String content;

  const _PolicySection({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color:
                  isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color:
                  isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
