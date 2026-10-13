import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sahifile/app/providers.dart';
import 'package:sahifile/app/theme/app_colors.dart';
import 'package:sahifile/app/theme/app_spacing.dart';
import 'package:sahifile/app/theme/glass_surface.dart';
import 'package:sahifile/core/utils/file_utils.dart';
import 'package:sahifile/core/utils/formatters.dart';
import 'package:sahifile/core/widgets/app_button.dart';
import 'package:sahifile/core/widgets/app_dialog.dart';
import 'package:sahifile/core/widgets/glass_app_bar.dart';
import 'package:sahifile/core/widgets/status_badge.dart';
import 'package:sahifile/features/history/domain/models/history_item.dart';
import 'package:sahifile/features/pdf_tools/domain/models/pdf_tool_result.dart';

class PdfResultScreen extends ConsumerStatefulWidget {
  final PdfToolResult result;

  const PdfResultScreen({super.key, required this.result});

  @override
  ConsumerState<PdfResultScreen> createState() => _PdfResultScreenState();
}

class _PdfResultScreenState extends ConsumerState<PdfResultScreen> {
  bool _historySaved = false;
  Uint8List? _previewThumbnailBytes;
  bool _isLoadingThumbnail = true;

  @override
  void initState() {
    super.initState();
    _saveToHistory();
    _loadPdfThumbnail();
  }

  void _saveToHistory() {
    if (_historySaved) return;
    _historySaved = true;

    final historyItem = HistoryItem(
      id: 'pdf_hist_${DateTime.now().millisecondsSinceEpoch}',
      operation:
          widget.result.operationLabel.contains('Merge')
              ? HistoryOperation.pdfMerge
              : widget.result.operationLabel.contains('Optimize')
              ? HistoryOperation.pdfCompress
              : HistoryOperation.imagesToPdf,
      sourceName: widget.result.outputFileName,
      outputName: widget.result.outputFileName,
      filePath: widget.result.outputPath,
      fileSizeBytes: widget.result.actualSizeBytes,
      dimensionsOrPages: '${widget.result.pageCount} pages',
      timestamp: DateTime.now(),
    );

    ref.read(historyControllerProvider.notifier).addHistory(historyItem);
  }

  Future<void> _loadPdfThumbnail() async {
    try {
      final file = File(widget.result.outputPath);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        final stream = Printing.raster(bytes, pages: [0], dpi: 90);
        await for (final rasterPage in stream) {
          final png = await rasterPage.toPng();
          if (mounted) {
            setState(() {
              _previewThumbnailBytes = png;
              _isLoadingThumbnail = false;
            });
          }
          break;
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingThumbnail = false);
      }
    }
  }

  void _sharePdf() {
    final file = File(widget.result.outputPath);
    if (file.existsSync()) {
      Share.shareXFiles(
        [XFile(file.path)],
        text: 'Shared from SahiFile: ${widget.result.outputFileName}',
      );
    } else {
      AppDialog.showError(
        context,
        title: 'File Not Available',
        message: 'The generated PDF could not be found.',
      );
    }
  }

  bool _isSaving = false;

  Future<void> _saveToDownloads() async {
    setState(() => _isSaving = true);
    final savedPath = await FileUtils.savePdfToDownloads(
      widget.result.outputPath,
      widget.result.outputFileName,
    );
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (savedPath != null) {
      AppDialog.showSuccess(
        context,
        title: 'Saved to Downloads! 📄',
        message:
            'PDF saved directly to your phone\'s public Downloads & Documents directory:\n$savedPath\n\nIt is available immediately in your phone\'s Files and Downloads apps.',
        buttonText: 'Awesome',
      );
    } else {
      AppDialog.showError(
        context,
        title: 'Save Failed',
        message: 'Could not write PDF to the Downloads directory.',
        suggestion: 'Please verify storage access in device Settings.',
      );
    }
  }

  void _showFullscreenPreview() {
    if (_previewThumbnailBytes == null) return;

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
                      child: Image.memory(
                        _previewThumbnailBytes!,
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
                      'Page 1 of ${widget.result.pageCount}  •  Pinch to Zoom',
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
        title: 'PDF Ready',
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
          padding: const EdgeInsets.all(20),
          children: [
            // Interactive PDF Document Preview Card
            GlassSurface(
              borderRadius: AppSpacing.radiusLg,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _showFullscreenPreview,
                    child: Container(
                      height: 240,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF161C2C) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.black.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (_previewThumbnailBytes != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                              child: Image.memory(
                                _previewThumbnailBytes!,
                                fit: BoxFit.contain,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                            )
                          else if (_isLoadingThumbnail)
                            const CircularProgressIndicator()
                          else
                            const Icon(
                              Icons.picture_as_pdf_rounded,
                              size: 54,
                              color: AppColors.error,
                            ),
                          // Tap to view hint overlay
                          if (_previewThumbnailBytes != null)
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
                                      'Tap to Preview',
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
                  ),
                  const SizedBox(height: 14),
                  Text(
                    widget.result.outputFileName,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color:
                          isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      StatusBadge(
                        label: '${widget.result.pageCount} Pages',
                        type: StatusBadgeType.primary,
                      ),
                      StatusBadge(
                        label: Formatters.formatBytes(
                          widget.result.actualSizeBytes,
                        ),
                        type: StatusBadgeType.success,
                      ),
                      const StatusBadge(
                        label: 'Auto-Saved to Storage',
                        type: StatusBadgeType.neutral,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (widget.result.note != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.infoBg,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(
                    color: AppColors.info.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.info,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.result.note!,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                          color:
                              isDark
                                  ? AppColors.darkTextPrimary
                                  : const Color(0xFF1E3A8A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            GlassSurface(
              borderRadius: AppSpacing.radiusLg,
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  _MetricRow(
                    label: 'Operation',
                    value: widget.result.operationLabel,
                  ),
                  const Divider(height: 20),
                  _MetricRow(
                    label: 'Final PDF Size',
                    value: Formatters.formatBytes(
                      widget.result.actualSizeBytes,
                    ),
                    subValue:
                        widget.result.originalSizeBytes > 0
                            ? 'Original: ${Formatters.formatBytes(widget.result.originalSizeBytes)}'
                            : null,
                    isHighlight: true,
                  ),
                  const Divider(height: 20),
                  _MetricRow(
                    label: 'Page Count',
                    value: '${widget.result.pageCount} pages',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Primary Save Button (Full Width to guarantee no overflow)
            AppButton(
              label: _isSaving ? 'Saving to Downloads...' : 'Save to Downloads',
              icon: Icons.download_rounded,
              isLoading: _isSaving,
              onPressed: _isSaving ? null : _saveToDownloads,
            ),
            const SizedBox(height: 12),
            // Secondary Action Row (Share + Home)
            Row(
              children: [
                Expanded(
                  child: AppButton.secondary(
                    label: 'Share PDF',
                    icon: Icons.share_rounded,
                    onPressed: _sharePdf,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                    icon: const Icon(Icons.home_rounded, size: 18),
                    label: const Text(
                      'Home',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
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
