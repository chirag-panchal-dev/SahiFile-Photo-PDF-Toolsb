import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/providers.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/glass_surface.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/glass_app_bar.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../../../../core/widgets/status_badge.dart';
import 'pdf_result_screen.dart';

class PdfCompressScreen extends ConsumerStatefulWidget {
  final String pdfPath;

  const PdfCompressScreen({super.key, required this.pdfPath});

  @override
  ConsumerState<PdfCompressScreen> createState() => _PdfCompressScreenState();
}

class _PdfCompressScreenState extends ConsumerState<PdfCompressScreen> {
  late TextEditingController _nameController;
  int _originalSize = 0;
  String _fileName = '';

  @override
  void initState() {
    super.initState();
    final file = File(widget.pdfPath);
    _fileName = widget.pdfPath.split('/').last;
    _originalSize = file.existsSync() ? file.lengthSync() : 0;
    _nameController = TextEditingController(
      text: '${_fileName.replaceAll('.pdf', '')}_optimized',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _compressPdf() async {
    final baseName =
        _nameController.text.trim().isEmpty
            ? 'optimized_pdf'
            : _nameController.text.trim();

    final service = ref.read(pdfServiceProvider);

    final result = await LoadingOverlay.show(
      context: context,
      message: 'Optimizing PDF...',
      subMessage:
          'Applying highest level compression without losing vector text',
      asyncWork:
          () => service.optimizePdf(
            inputPath: widget.pdfPath,
            outputBaseName: baseName,
          ),
    );

    if (!mounted) return;

    result.when(
      onSuccess: (pdfResult) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => PdfResultScreen(result: pdfResult),
          ),
        );
      },
      onFailure: (error) {
        AppDialog.showAppError(context, error);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: const GlassAppBar(title: 'Optimize PDF Size'),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // PDF Details Card
              GlassSurface(
                borderRadius: AppSpacing.radiusLg,
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                      ),
                      child: const Icon(
                        Icons.picture_as_pdf_rounded,
                        color: AppColors.error,
                        size: 34,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _fileName,
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
                    const SizedBox(height: 6),
                    StatusBadge(
                      label:
                          'Current Size: ${Formatters.formatBytes(_originalSize)}',
                      type: StatusBadgeType.primary,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Optimization mode explanation
              GlassSurface(
                borderRadius: AppSpacing.radiusLg,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          size: 18,
                          color: AppColors.accentBlue,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Safe Document Compression',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color:
                                isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'SahiFile cleans metadata, flattens unused streams, and applies best on-device compression while retaining searchable text and document fonts.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color:
                            isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Output Filename',
                  suffixText: '.pdf',
                ),
              ),

              const SizedBox(height: 28),

              AppButton(
                label: 'Optimize PDF Now',
                icon: Icons.compress_rounded,
                onPressed: _compressPdf,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
