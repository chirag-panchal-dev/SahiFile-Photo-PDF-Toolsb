import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sahifile/app/providers.dart';
import 'package:sahifile/app/theme/app_colors.dart';
import 'package:sahifile/app/theme/app_spacing.dart';
import 'package:sahifile/app/theme/glass_surface.dart';
import 'package:sahifile/core/utils/formatters.dart';
import 'package:sahifile/core/widgets/app_button.dart';
import 'package:sahifile/core/widgets/app_dialog.dart';
import 'package:sahifile/core/widgets/glass_app_bar.dart';
import 'package:sahifile/core/widgets/loading_overlay.dart';
import 'package:sahifile/core/widgets/status_badge.dart';
import 'package:sahifile/features/pdf_tools/presentation/screens/pdf_result_screen.dart';

class PdfMergeScreen extends ConsumerStatefulWidget {
  const PdfMergeScreen({super.key});

  @override
  ConsumerState<PdfMergeScreen> createState() => _PdfMergeScreenState();
}

class _PdfMergeScreenState extends ConsumerState<PdfMergeScreen> {
  final List<String> _pdfPaths = [];
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: 'merged_document');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pdfPaths.isEmpty) {
        _pickPdfs();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickPdfs() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          for (final f in result.files) {
            if (f.path != null && !_pdfPaths.contains(f.path)) {
              _pdfPaths.add(f.path!);
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        AppDialog.showError(
          context,
          title: 'Document Selection Failed',
          message: 'Could not access the selected PDF documents.',
          suggestion: 'Please try selecting your PDFs again.',
          technicalDetails: e.toString(),
        );
      }
    }
  }

  void _removePdf(int index) {
    setState(() => _pdfPaths.removeAt(index));
  }

  Future<void> _mergePdfs() async {
    if (_pdfPaths.length < 2) {
      AppDialog.showError(
        context,
        title: 'Need at Least 2 PDFs',
        message: 'Please choose at least two PDF files to merge together.',
        suggestion: 'Tap "Add PDF" to pick another document.',
      );
      return;
    }

    final baseName =
        _nameController.text.trim().isEmpty
            ? 'merged_document'
            : _nameController.text.trim();

    final service = ref.read(pdfServiceProvider);

    final result = await LoadingOverlay.show(
      context: context,
      message: 'Merging PDFs...',
      subMessage: 'Safely combining ${_pdfPaths.length} documents on-device',
      asyncWork:
          () =>
              service.mergePdfs(pdfPaths: _pdfPaths, outputBaseName: baseName),
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
      appBar: GlassAppBar(
        title: 'Merge PDFs',
        actions: [
          IconButton(
            icon: const Icon(Icons.note_add_rounded),
            tooltip: 'Add PDF',
            onPressed: _pickPdfs,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
              child: Row(
                children: [
                  const Icon(
                    Icons.call_merge_rounded,
                    size: 16,
                    color: AppColors.accentIndigo,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_pdfPaths.length} files selected. Long-press to reorder merge order.',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color:
                            isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child:
                  _pdfPaths.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.call_merge_rounded,
                              size: 52,
                              color: isDark ? Colors.white24 : Colors.black26,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'No PDF files selected',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            AppButton(
                              label: 'Select PDF Files',
                              icon: Icons.note_add_rounded,
                              onPressed: _pickPdfs,
                            ),
                          ],
                        ),
                      )
                      : ReorderableListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        itemCount: _pdfPaths.length,
                        onReorder: (oldIndex, newIndex) {
                          setState(() {
                            if (oldIndex < newIndex) newIndex -= 1;
                            final item = _pdfPaths.removeAt(oldIndex);
                            _pdfPaths.insert(newIndex, item);
                          });
                        },
                        itemBuilder: (context, index) {
                          final path = _pdfPaths[index];
                          final file = File(path);
                          final name = path.split('/').last;
                          final size =
                              file.existsSync() ? file.lengthSync() : 0;

                          return Padding(
                            key: ValueKey('${path}_$index'),
                            padding: const EdgeInsets.only(bottom: 10),
                            child: GlassSurface(
                              borderRadius: AppSpacing.radiusMd,
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 13,
                                    backgroundColor: const Color(0xFF8B5CF6),
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color:
                                                isDark
                                                    ? AppColors.darkTextPrimary
                                                    : AppColors
                                                        .lightTextPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 3),
                                        StatusBadge(
                                          label: Formatters.formatBytes(size),
                                          type: StatusBadgeType.primary,
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      size: 19,
                                      color: AppColors.error,
                                    ),
                                    tooltip: 'Remove',
                                    onPressed: () => _removePdf(index),
                                  ),
                                  const Icon(
                                    Icons.drag_indicator_rounded,
                                    color: Colors.grey,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
            ),
            GlassSurface(
              borderRadius: AppSpacing.radiusXl,
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Merged PDF Filename',
                      hintText: 'merged_document',
                      suffixText: '.pdf',
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  AppButton(
                    label: 'Merge ${_pdfPaths.length} PDFs',
                    icon: Icons.call_merge_rounded,
                    width: double.infinity,
                    onPressed: _pdfPaths.length >= 2 ? _mergePdfs : null,
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
