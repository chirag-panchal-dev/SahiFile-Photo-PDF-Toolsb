import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sahifile/app/providers.dart';
import 'package:sahifile/app/theme/app_colors.dart';
import 'package:sahifile/app/theme/app_spacing.dart';
import 'package:sahifile/app/theme/glass_surface.dart';
import 'package:sahifile/core/widgets/app_dialog.dart';
import 'package:sahifile/features/pdf_tools/presentation/screens/images_to_pdf_screen.dart';
import 'package:sahifile/features/pdf_tools/presentation/screens/pdf_compress_screen.dart';
import 'package:sahifile/features/pdf_tools/presentation/screens/pdf_merge_screen.dart';
import 'package:sahifile/features/pdf_tools/presentation/screens/pdf_organize_screen.dart';
import 'package:sahifile/features/photo_editor/presentation/screens/photo_setup_screen.dart';
import 'package:sahifile/features/presets/presentation/screens/presets_screen.dart';

class ToolsScreen extends ConsumerWidget {
  const ToolsScreen({super.key});

  Future<void> _pickImage(
    BuildContext context, {
    bool isSignature = false,
    bool isCompressOnly = false,
  }) async {
    try {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;

      if (!context.mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder:
              (context) => PhotoSetupScreen(
                imagePath: picked.path,
                isSignature: isSignature,
                isCompressOnly: isCompressOnly,
              ),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        AppDialog.showError(
          context,
          title: 'Photo Selection Failed',
          message: 'Could not access the selected photo.',
          suggestion: 'Please try again or select another image.',
          technicalDetails: e.toString(),
        );
      }
    }
  }

  Future<void> _pickPdfForCompression(BuildContext context) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result == null || result.files.isEmpty) return;
      final path = result.files.first.path;
      if (path == null) return;

      if (!context.mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PdfCompressScreen(pdfPath: path),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        AppDialog.showError(
          context,
          title: 'Document Selection Failed',
          message: 'Could not access the selected PDF.',
          suggestion: 'Please try selecting the PDF document again.',
          technicalDetails: e.toString(),
        );
      }
    }
  }

  Future<void> _pickPdfForOrganizing(BuildContext context) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result == null || result.files.isEmpty) return;
      final path = result.files.first.path;
      if (path == null) return;

      if (!context.mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PdfOrganizeScreen(pdfPath: path),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        AppDialog.showError(
          context,
          title: 'Document Selection Failed',
          message: 'Could not access the selected PDF.',
          suggestion: 'Please try selecting the PDF document again.',
          technicalDetails: e.toString(),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          children: [
            Text(
              strings.navTools,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color:
                    isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Select a tool to prepare your documents for online uploads.',
              style: TextStyle(
                fontSize: 13.5,
                color:
                    isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 24),

            _SectionHeader(title: 'Photo & Image Tools'),
            const SizedBox(height: 12),
            _ToolCard(
              title: strings.toolPhotoSignature,
              description: strings.toolPhotoSignatureDesc,
              icon: Icons.crop_rotate_rounded,
              iconColor: AppColors.accentIndigo,
              onTap: () => _pickImage(context),
            ),
            const SizedBox(height: 12),
            _ToolCard(
              title: 'Signature Preparer',
              description:
                  'Exact aspect ratio, transparent PNG or white background, under 20 KB limit.',
              icon: Icons.draw_rounded,
              iconColor: AppColors.accentBlue,
              onTap: () => _pickImage(context, isSignature: true),
            ),
            const SizedBox(height: 12),
            _ToolCard(
              title: strings.toolCompressImage,
              description: strings.toolCompressImageDesc,
              icon: Icons.compress_rounded,
              iconColor: const Color(0xFF06B6D4),
              onTap: () => _pickImage(context, isCompressOnly: true),
            ),

            const SizedBox(height: 28),

            _SectionHeader(title: 'PDF Tools'),
            const SizedBox(height: 12),
            _ToolCard(
              title: strings.toolImagesToPdf,
              description: strings.toolImagesToPdfDesc,
              icon: Icons.picture_as_pdf_rounded,
              iconColor: AppColors.success,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ImagesToPdfScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _ToolCard(
              title: strings.toolMergePdf,
              description: strings.toolMergePdfDesc,
              icon: Icons.call_merge_rounded,
              iconColor: const Color(0xFF8B5CF6),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const PdfMergeScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _ToolCard(
              title: strings.toolPdfCompress,
              description: strings.toolPdfCompressDesc,
              icon: Icons.inventory_2_outlined,
              iconColor: const Color(0xFFEC4899),
              onTap: () => _pickPdfForCompression(context),
            ),
            const SizedBox(height: 12),
            _ToolCard(
              title: strings.toolOrganizePdf,
              description: strings.toolOrganizePdfDesc,
              icon: Icons.auto_awesome_motion_rounded,
              iconColor: const Color(0xFFF59E0B),
              onTap: () => _pickPdfForOrganizing(context),
            ),

            const SizedBox(height: 28),

            _SectionHeader(title: 'Templates & Presets'),
            const SizedBox(height: 12),
            _ToolCard(
              title: strings.toolPresets,
              description: strings.toolPresetsDesc,
              icon: Icons.bookmark_added_rounded,
              iconColor: AppColors.warning,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const PresetsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _ToolCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassSurface(
      borderRadius: AppSpacing.radiusLg,
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: iconColor.withValues(alpha: 0.24),
                width: 1,
              ),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color:
                        isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.35,
                    color:
                        isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.chevron_right_rounded,
            color:
                isDark
                    ? AppColors.darkTextSecondary.withValues(alpha: 0.6)
                    : AppColors.lightTextSecondary.withValues(alpha: 0.6),
            size: 22,
          ),
        ],
      ),
    );
  }
}
