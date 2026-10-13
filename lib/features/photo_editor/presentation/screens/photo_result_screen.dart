import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../app/providers.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/glass_surface.dart';
import '../../../../core/utils/file_utils.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/glass_app_bar.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../history/domain/models/history_item.dart';
import '../../domain/models/photo_edit_params.dart';
import '../../domain/models/photo_process_result.dart';
import 'photo_setup_screen.dart';

class PhotoResultScreen extends ConsumerStatefulWidget {
  final PhotoProcessResult result;
  final PhotoEditParams sourceParams;

  const PhotoResultScreen({
    super.key,
    required this.result,
    required this.sourceParams,
  });

  @override
  ConsumerState<PhotoResultScreen> createState() => _PhotoResultScreenState();
}

class _PhotoResultScreenState extends ConsumerState<PhotoResultScreen> {
  bool _historySaved = false;

  @override
  void initState() {
    super.initState();
    _saveToHistory();
  }

  void _saveToHistory() {
    if (_historySaved) return;
    _historySaved = true;

    final historyItem = HistoryItem(
      id: 'hist_${DateTime.now().millisecondsSinceEpoch}',
      operation:
          widget.sourceParams.isSignature
              ? HistoryOperation.signature
              : HistoryOperation.photo,
      sourceName: widget.sourceParams.sourcePath.split('/').last,
      outputName: widget.result.outputFileName,
      filePath: widget.result.outputPath,
      fileSizeBytes: widget.result.actualSizeBytes,
      dimensionsOrPages: Formatters.formatDimensions(
        widget.result.actualWidth,
        widget.result.actualHeight,
      ),
      timestamp: DateTime.now(),
    );

    ref.read(historyControllerProvider.notifier).addHistory(historyItem);
  }

  void _shareFile() {
    final file = File(widget.result.outputPath);
    if (file.existsSync()) {
      Share.shareXFiles(
        [XFile(file.path)],
        text: 'Prepared with SahiFile: ${widget.result.outputFileName}',
      );
    } else {
      AppDialog.showError(
        context,
        title: 'File Not Available',
        message: 'The generated photo could not be found.',
      );
    }
  }

  bool _isSaving = false;

  Future<void> _saveToGallery() async {
    setState(() => _isSaving = true);
    final success = await FileUtils.saveImageToGallery(
      widget.result.outputPath,
    );
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      AppDialog.showSuccess(
        context,
        title: 'Saved to Gallery! 📸',
        message:
            'Photo successfully saved directly to your phone\'s main Gallery / Photos!\n\nYou can access it immediately at the top of your Gallery or Files app.',
        buttonText: 'Awesome',
      );
    } else {
      AppDialog.showError(
        context,
        title: 'Save to Gallery Failed',
        message: 'Could not write to the device media library.',
        suggestion: 'Please verify media/storage permissions in device Settings.',
      );
    }
  }

  void _showFullscreenPreview() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.85),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        widget.result.outputFileName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: Container(
                  color: Colors.black,
                  child: InteractiveViewer(
                    maxScale: 4.5,
                    child: Center(
                      child: Image.file(
                        File(widget.result.outputPath),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.85),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${widget.result.actualWidth} × ${widget.result.actualHeight} px  •  Pinch to Zoom',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: GlassAppBar(
        title: 'Ready to Upload',
        showBackButton: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Done',
            onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            // Preview Card
            GlassSurface(
              borderRadius: AppSpacing.radiusLg,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _showFullscreenPreview,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          child: Container(
                            height: 240,
                            width: double.infinity,
                            color: isDark ? Colors.black26 : const Color(0xFFF1F5F9),
                            child: Image.file(
                              File(widget.result.outputPath),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.zoom_in_rounded, size: 13, color: Colors.white),
                                SizedBox(width: 4),
                                Text(
                                  'Tap to Zoom',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      StatusBadge(
                        label:
                            widget.result.targetSizeAchieved
                                ? 'Target Size Met'
                                : 'Approximate Size',
                        type:
                            widget.result.targetSizeAchieved
                                ? StatusBadgeType.success
                                : StatusBadgeType.warning,
                        icon:
                            widget.result.targetSizeAchieved
                                ? Icons.check_circle_rounded
                                : Icons.info_outline_rounded,
                      ),
                      const SizedBox(width: 8),
                      StatusBadge(
                        label: widget.result.format.label,
                        type: StatusBadgeType.neutral,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Warning note if target size could not be hit
            if (widget.result.warningMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.warningBg,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.warning,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.result.warningMessage!,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                          color:
                              isDark
                                  ? AppColors.darkTextPrimary
                                  : const Color(0xFF92400E),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Comparison Metrics Card
            GlassSurface(
              borderRadius: AppSpacing.radiusLg,
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  _MetricRow(
                    label: 'Final File Size',
                    value: Formatters.formatBytes(
                      widget.result.actualSizeBytes,
                    ),
                    subValue:
                        'Original: ${Formatters.formatBytes(widget.result.originalSizeBytes)}',
                    isHighlight: true,
                  ),
                  const Divider(height: 20),
                  _MetricRow(
                    label: 'Final Dimensions',
                    value: Formatters.formatDimensions(
                      widget.result.actualWidth,
                      widget.result.actualHeight,
                    ),
                    subValue:
                        'Quality: ${widget.result.finalQuality}% encoding',
                  ),
                  const Divider(height: 20),
                  _MetricRow(
                    label: 'File Name',
                    value: widget.result.outputFileName,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Main Action Buttons
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: _isSaving ? 'Saving to Gallery...' : 'Save to Gallery',
                    icon: Icons.download_rounded,
                    isLoading: _isSaving,
                    onPressed: _isSaving ? null : _saveToGallery,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton.secondary(
                    label: 'Share Photo',
                    icon: Icons.share_rounded,
                    onPressed: _shareFile,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder:
                              (context) => PhotoSetupScreen(
                                imagePath: widget.sourceParams.sourcePath,
                                isSignature: widget.sourceParams.isSignature,
                              ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit_rounded, size: 17),
                    label: const Text('Edit Again'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).popUntil((r) => r.isFirst);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isDark
                              ? AppColors.accentIndigoDark
                              : AppColors.accentIndigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                      ),
                    ),
                    child: const Text(
                      'Done',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;
  final String? subValue;
  final bool isHighlight;

  const _MetricRow({
    required this.label,
    required this.value,
    this.subValue,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            color:
                isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color:
                      isHighlight
                          ? (isDark
                              ? AppColors.accentIndigoDark
                              : AppColors.accentIndigo)
                          : (isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary),
                ),
              ),
              if (subValue != null) ...[
                const SizedBox(height: 2),
                Text(
                  subValue!,
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 11.5,
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
      ],
    );
  }
}
