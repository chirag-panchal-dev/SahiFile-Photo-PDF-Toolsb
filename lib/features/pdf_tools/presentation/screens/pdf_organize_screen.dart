import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:reorderable_grid/reorderable_grid.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;
import '../../../../app/providers.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/glass_surface.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/glass_app_bar.dart';
import '../../domain/models/pdf_page_reorganize_item.dart';
import 'pdf_result_screen.dart';

class PdfOrganizeScreen extends ConsumerStatefulWidget {
  final String pdfPath;

  const PdfOrganizeScreen({super.key, required this.pdfPath});

  @override
  ConsumerState<PdfOrganizeScreen> createState() => _PdfOrganizeScreenState();
}

class _PdfOrganizeScreenState extends ConsumerState<PdfOrganizeScreen> {
  final List<PdfPageReorganizeItem> _pages = [];
  List<PdfPageReorganizeItem> _originalPages = [];
  bool _isLoading = true;
  bool _isProcessing = false;
  String _statusMessage = 'Reading pages...';
  int _totalInitialPages = 0;
  String _fileName = '';

  @override
  void initState() {
    super.initState();
    _fileName = widget.pdfPath.split(Platform.pathSeparator).last;
    _loadPdfPages();
  }

  Future<void> _loadPdfPages() async {
    try {
      final file = File(widget.pdfPath);
      if (!await file.exists()) {
        if (mounted) {
          AppDialog.showError(
            context,
            title: 'File Not Found',
            message: 'Could not access the selected PDF document.',
          );
        }
        return;
      }

      final bytes = await file.readAsBytes();
      final doc = sf.PdfDocument(inputBytes: bytes);
      _totalInitialPages = doc.pages.count;
      doc.dispose();

      if (_totalInitialPages == 0) {
        if (mounted) {
          AppDialog.showError(
            context,
            title: 'Empty PDF',
            message: 'This document does not contain any readable pages.',
          );
        }
        return;
      }

      for (int i = 0; i < _totalInitialPages; i++) {
        _pages.add(
          PdfPageReorganizeItem(
            id: 'page_${i}_${DateTime.now().microsecondsSinceEpoch}',
            originalPageIndex: i,
            initialPageNumber: i + 1,
            sourcePdfPath: widget.pdfPath,
          ),
        );
      }
      _originalPages = _pages.map((p) => p.copyWith()).toList();

      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = 'Generating page previews...';
        });
      }

      // Progressively stream page thumbnails using native rasterizer
      _renderThumbnails(bytes);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppDialog.showError(
          context,
          title: 'Cannot Open PDF',
          message: 'Failed to read document pages. It may be corrupt or encrypted.',
          technicalDetails: e.toString(),
        );
      }
    }
  }

  Future<void> _renderThumbnails(Uint8List bytes) async {
    try {
      int pageIndex = 0;
      final stream = Printing.raster(bytes, dpi: 55);
      await for (final page in stream) {
        if (!mounted) break;
        final pngBytes = await page.toPng();
        final targetIndex = pageIndex++;

        if (mounted) {
          setState(() {
            for (final item in _pages) {
              if (item.sourcePdfPath == widget.pdfPath &&
                  item.originalPageIndex == targetIndex) {
                item.thumbnailBytes = pngBytes;
              }
            }
          });
        }
      }
    } catch (_) {
      // Fallback if background thumbnail generation encounters an unsupported page
    }
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      final item = _pages.removeAt(oldIndex);
      _pages.insert(newIndex, item);
    });
  }

  void _rotatePage(int index) {
    setState(() {
      _pages[index].rotationDegrees = (_pages[index].rotationDegrees + 90) % 360;
    });
  }

  void _rotateAllPages() {
    setState(() {
      for (final p in _pages) {
        p.rotationDegrees = (p.rotationDegrees + 90) % 360;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Rotated all pages by 90° clockwise'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _reverseSequence() {
    setState(() {
      final reversed = _pages.reversed.toList();
      _pages.clear();
      _pages.addAll(reversed);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Inverted page sequence'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _resetSequence() {
    setState(() {
      _pages.clear();
      _pages.addAll(_originalPages.map((p) => p.copyWith()).toList());
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reset to original sequence & orientation'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _duplicatePage(int index) {
    final original = _pages[index];
    final copy = original.copyWith(
      id: 'page_${original.originalPageIndex}_dup_${DateTime.now().microsecondsSinceEpoch}',
    );
    setState(() {
      _pages.insert(index + 1, copy);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Duplicated Page ${index + 1}'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _deletePage(int index) {
    final removed = _pages[index];
    setState(() {
      _pages.removeAt(index);
    });

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed Page ${index + 1} (Orig: ${removed.initialPageNumber})'),
        action: SnackBarAction(
          label: 'UNDO',
          textColor: AppColors.accentIndigo,
          onPressed: () {
            setState(() {
              _pages.insert(index, removed);
            });
          },
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _addMorePdfs() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result == null || result.files.isEmpty) return;
      final extraPath = result.files.first.path;
      if (extraPath == null) return;

      final file = File(extraPath);
      final bytes = await file.readAsBytes();
      final doc = sf.PdfDocument(inputBytes: bytes);
      final extraCount = doc.pages.count;
      doc.dispose();

      final newItems = <PdfPageReorganizeItem>[];
      for (int i = 0; i < extraCount; i++) {
        newItems.add(
          PdfPageReorganizeItem(
            id: 'extra_${i}_${DateTime.now().microsecondsSinceEpoch}',
            originalPageIndex: i,
            initialPageNumber: i + 1,
            sourcePdfPath: extraPath,
          ),
        );
      }

      setState(() {
        _pages.addAll(newItems);
      });

      // Stream rasterized thumbnails for newly added pages
      try {
        int pageIndex = 0;
        final stream = Printing.raster(bytes, dpi: 55);
        await for (final page in stream) {
          if (!mounted) break;
          final pngBytes = await page.toPng();
          final targetIndex = pageIndex++;
          if (mounted) {
            setState(() {
              for (final item in _pages) {
                if (item.sourcePdfPath == extraPath &&
                    item.originalPageIndex == targetIndex) {
                  item.thumbnailBytes = pngBytes;
                }
              }
            });
          }
        }
      } catch (_) {}
    } catch (e) {
      if (mounted) {
        AppDialog.showError(
          context,
          title: 'Could Not Add Document',
          message: 'Error importing pages from selected document.',
          technicalDetails: e.toString(),
        );
      }
    }
  }

  void _showPagePreview(PdfPageReorganizeItem item, int currentIndex) {
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
                  color: Colors.black.withValues(alpha: 0.8),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Page ${currentIndex + 1} (Orig: ${item.initialPageNumber})',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
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
                    maxScale: 4.0,
                    child: Center(
                      child: item.thumbnailBytes != null
                          ? RotatedBox(
                              quarterTurns: (item.rotationDegrees ~/ 90) % 4,
                              child: Image.memory(
                                item.thumbnailBytes!,
                                fit: BoxFit.contain,
                              ),
                            )
                          : const SizedBox(
                              height: 200,
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.8),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _rotatePage(currentIndex);
                      },
                      icon: const Icon(Icons.rotate_right_rounded, color: Colors.white),
                      label: const Text('Rotate 90°', style: TextStyle(color: Colors.white)),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _duplicatePage(currentIndex);
                      },
                      icon: const Icon(Icons.copy_rounded, color: Colors.white),
                      label: const Text('Duplicate', style: TextStyle(color: Colors.white)),
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

  Future<void> _saveOrganizedPdf() async {
    if (_pages.isEmpty) {
      AppDialog.showError(
        context,
        title: 'No Pages',
        message: 'Please keep at least one page in your document sequence.',
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final baseName = _fileName.replaceAll(
        RegExp(r'\.pdf$', caseSensitive: false),
        '',
      );
      final outputName = '${baseName}_organized';

      final resultEither = await ref.read(pdfServiceProvider).reorganizePdf(
            orderedPages: _pages,
            outputBaseName: outputName,
          );

      if (!mounted) return;
      setState(() => _isProcessing = false);

      resultEither.when(
        onSuccess: (result) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => PdfResultScreen(result: result),
            ),
          );
        },
        onFailure: (error) {
          AppDialog.showError(
            context,
            title: 'Organization Failed',
            message: error.message,
            suggestion: error.suggestion,
            technicalDetails: error.technicalDetails,
          );
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        AppDialog.showError(
          context,
          title: 'Unexpected Error',
          message: 'An error occurred while organizing the PDF.',
          technicalDetails: e.toString(),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: GlassAppBar(
        title: 'Organize PDF Pages',
        actions: [
          IconButton(
            icon: const Icon(Icons.rotate_right_rounded),
            tooltip: 'Rotate All 90°',
            onPressed: _pages.isEmpty ? null : _rotateAllPages,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            tooltip: 'More actions',
            onSelected: (value) {
              switch (value) {
                case 'rotate_all':
                  _rotateAllPages();
                  break;
                case 'reverse':
                  _reverseSequence();
                  break;
                case 'reset':
                  _resetSequence();
                  break;
                case 'add_pdf':
                  _addMorePdfs();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'rotate_all',
                child: Row(
                  children: [
                    Icon(Icons.rotate_right_rounded, size: 20),
                    SizedBox(width: 10),
                    Text('Rotate All 90°'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'reverse',
                child: Row(
                  children: [
                    Icon(Icons.swap_vert_rounded, size: 20),
                    SizedBox(width: 10),
                    Text('Reverse Sequence'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(Icons.restart_alt_rounded, size: 20),
                    SizedBox(width: 10),
                    Text('Reset to Original'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'add_pdf',
                child: Row(
                  children: [
                    Icon(Icons.post_add_rounded, size: 20),
                    SizedBox(width: 10),
                    Text('Insert Another PDF'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    _statusMessage,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Quick Action Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurface.withValues(alpha: 0.6)
                        : Colors.white.withValues(alpha: 0.6),
                    border: Border(
                      bottom: BorderSide(
                        color: isDark
                            ? AppColors.darkGlassBorder
                            : AppColors.lightGlassBorder,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Page count chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accentIndigo.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.pages_rounded,
                              size: 14,
                              color: AppColors.accentIndigo,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${_pages.length} Pages',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.accentIndigo,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Drag & drop to reorder sequence',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                        tooltip: 'Insert Another PDF',
                        onPressed: _addMorePdfs,
                      ),
                    ],
                  ),
                ),

                // Reorderable Grid of Pages
                Expanded(
                  child: _pages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.delete_sweep_rounded,
                                size: 54,
                                color: AppColors.accentIndigo,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'All pages deleted',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _resetSequence,
                                child: const Text('Reset Pages'),
                              ),
                            ],
                          ),
                        )
                      : ReorderableGridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.72,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                          ),
                          itemCount: _pages.length,
                          onReorder: _onReorder,
                          itemBuilder: (context, index) {
                            final item = _pages[index];
                            return _buildPageCard(
                              key: ValueKey(item.id),
                              item: item,
                              displayIndex: index,
                              isDark: isDark,
                            );
                          },
                        ),
                ),
              ],
            ),
      bottomSheet: _isLoading
          ? null
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurface.withValues(alpha: 0.95)
                    : Colors.white.withValues(alpha: 0.95),
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? AppColors.darkGlassBorder
                        : AppColors.lightGlassBorder,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sequence: ${_pages.length} Pages',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Saved directly to Downloads',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isProcessing ? null : _saveOrganizedPdf,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentIndigo,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                      ),
                      child: _isProcessing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.save_rounded, size: 18),
                                SizedBox(width: 6),
                                Text(
                                  'Save PDF',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPageCard({
    required Key key,
    required PdfPageReorganizeItem item,
    required int displayIndex,
    required bool isDark,
  }) {
    return GlassSurface(
      key: key,
      borderRadius: AppSpacing.radiusMd,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Card Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.03),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppSpacing.radiusMd),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentIndigo,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Text(
                    '#${displayIndex + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  'Orig: ${item.initialPageNumber}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                const Icon(
                  Icons.drag_indicator_rounded,
                  size: 16,
                  color: Colors.grey,
                ),
              ],
            ),
          ),

          // Card Thumbnail Body
          Expanded(
            child: GestureDetector(
              onTap: () => _showPagePreview(item, displayIndex),
              child: Container(
                margin: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E2330) : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.08),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  child: item.thumbnailBytes != null
                      ? RotatedBox(
                          quarterTurns: (item.rotationDegrees ~/ 90) % 4,
                          child: Image.memory(
                            item.thumbnailBytes!,
                            fit: BoxFit.contain,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        )
                      : Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.description_outlined,
                                size: 32,
                                color: AppColors.accentIndigo.withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Page ${displayIndex + 1}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ),
          ),

          // Card Bottom Action Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.03)
                  : Colors.black.withValues(alpha: 0.02),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(AppSpacing.radiusMd),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  icon: const Icon(Icons.rotate_right_rounded, size: 18),
                  tooltip: 'Rotate 90°',
                  onPressed: () => _rotatePage(displayIndex),
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  tooltip: 'Duplicate',
                  onPressed: () => _duplicatePage(displayIndex),
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: AppColors.error,
                  ),
                  tooltip: 'Remove',
                  onPressed: () => _deletePage(displayIndex),
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
