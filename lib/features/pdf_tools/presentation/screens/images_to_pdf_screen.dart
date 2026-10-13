import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sahifile/app/providers.dart';
import 'package:sahifile/app/theme/app_colors.dart';
import 'package:sahifile/app/theme/app_spacing.dart';
import 'package:sahifile/app/theme/glass_surface.dart';
import 'package:sahifile/core/widgets/app_button.dart';
import 'package:sahifile/core/widgets/app_dialog.dart';
import 'package:sahifile/core/widgets/glass_app_bar.dart';
import 'package:sahifile/core/widgets/loading_overlay.dart';
import 'package:sahifile/features/pdf_tools/domain/models/images_to_pdf_params.dart';
import 'package:sahifile/features/pdf_tools/presentation/screens/pdf_result_screen.dart';

enum _PdfPageViewMode { grid, list }

class ImagesToPdfScreen extends ConsumerStatefulWidget {
  const ImagesToPdfScreen({super.key});

  @override
  ConsumerState<ImagesToPdfScreen> createState() => _ImagesToPdfScreenState();
}

class _ImagesToPdfScreenState extends ConsumerState<ImagesToPdfScreen> {
  final List<ImageItem> _images = [];
  _PdfPageViewMode _viewMode = _PdfPageViewMode.grid;

  PdfPageSize _pageSize = PdfPageSize.a4;
  PdfOrientation _orientation = PdfOrientation.portrait;
  double _marginPoints = 16.0;
  bool _fillPage = false;
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: 'document');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_images.isEmpty) {
        _pickImages();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final picker = ImagePicker();
      final List<XFile> pickedList = await picker.pickMultiImage();
      if (pickedList.isNotEmpty) {
        setState(() {
          for (final item in pickedList) {
            _images.add(ImageItem(path: item.path, name: item.name));
          }
        });
      }
    } catch (e) {
      if (mounted) {
        AppDialog.showError(
          context,
          title: 'Photo Selection Failed',
          message: 'Could not access the selected photos.',
          suggestion: 'Please try picking images again.',
          technicalDetails: e.toString(),
        );
      }
    }
  }

  // --- Sequence Manipulation Methods ---

  void _movePage(int fromIndex, int toIndex) {
    if (toIndex < 0 || toIndex >= _images.length || fromIndex == toIndex) return;
    setState(() {
      final item = _images.removeAt(fromIndex);
      _images.insert(toIndex, item);
    });
  }

  void _moveToFirst(int index) {
    _movePage(index, 0);
  }

  void _moveToLast(int index) {
    _movePage(index, _images.length - 1);
  }

  void _reversePageOrder() {
    if (_images.length < 2) return;
    setState(() {
      final reversed = _images.reversed.toList();
      _images.clear();
      _images.addAll(reversed);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reversed all page sequences'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _sortByName() {
    setState(() {
      _images.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sorted pages alphabetically by filename'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _rotateAll() {
    setState(() {
      for (int i = 0; i < _images.length; i++) {
        final item = _images[i];
        _images[i] = item.copyWith(
          rotationDegrees: (item.rotationDegrees + 90) % 360,
        );
      }
    });
  }

  void _rotateImage(int index) {
    setState(() {
      final item = _images[index];
      _images[index] = item.copyWith(
        rotationDegrees: (item.rotationDegrees + 90) % 360,
      );
    });
  }

  void _duplicateImage(int index) {
    setState(() {
      final item = _images[index];
      _images.insert(index + 1, item.copyWith(name: '${item.name} (copy)'));
    });
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  void _clearAll() async {
    final confirmed = await AppDialog.showConfirmation(
      context,
      title: 'Clear All Pages?',
      message: 'This will remove all ${_images.length} selected pages from the PDF builder.',
      confirmText: 'Clear All',
      isDestructive: true,
    );
    if (confirmed) {
      setState(() {
        _images.clear();
      });
    }
  }

  void _previewImage(ImageItem item, int pageNum) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Stack(
            alignment: Alignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                child: Container(
                  color: Colors.black,
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.75,
                  ),
                  child: InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 4.0,
                    child: RotatedBox(
                      quarterTurns: item.rotationDegrees ~/ 90,
                      child: Image.file(File(item.path), fit: BoxFit.contain),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Page $pageNum • ${item.name}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _createPdf() async {
    if (_images.isEmpty) {
      AppDialog.showError(
        context,
        title: 'No Images Selected',
        message: 'Please add at least one photo to create a PDF.',
        suggestion: 'Tap "Add Photos" to select documents from your gallery.',
      );
      return;
    }

    final baseName =
        _nameController.text.trim().isEmpty
            ? 'document'
            : _nameController.text.trim();

    final params = ImagesToPdfParams(
      images: _images,
      pageSize: _pageSize,
      orientation: _orientation,
      marginPoints: _marginPoints,
      fillPage: _fillPage,
      outputBaseName: baseName,
    );

    final service = ref.read(pdfServiceProvider);

    final result = await LoadingOverlay.show(
      context: context,
      message: 'Creating PDF...',
      subMessage: 'Optimizing and sequencing ${_images.length} pages',
      asyncWork: () => service.createPdfFromImages(params),
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
        title: 'Images to PDF',
        actions: [
          IconButton(
            icon: Icon(
              _viewMode == _PdfPageViewMode.grid
                  ? Icons.view_list_rounded
                  : Icons.grid_view_rounded,
            ),
            tooltip: _viewMode == _PdfPageViewMode.grid ? 'List View' : 'Grid View',
            onPressed: () {
              setState(() {
                _viewMode = _viewMode == _PdfPageViewMode.grid
                    ? _PdfPageViewMode.list
                    : _PdfPageViewMode.grid;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_photo_alternate_rounded),
            tooltip: 'Add More Photos',
            onPressed: _pickImages,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Batch Sequence Toolbar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accentIndigo.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${_images.length} Pages',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accentIndigo,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Quick Reverse Order
                    if (_images.length > 1) ...[
                      _QuickSequenceButton(
                        icon: Icons.swap_vertical_circle_outlined,
                        label: 'Reverse Order',
                        onTap: _reversePageOrder,
                      ),
                      const SizedBox(width: 8),
                      _QuickSequenceButton(
                        icon: Icons.sort_by_alpha_rounded,
                        label: 'A-Z',
                        onTap: _sortByName,
                      ),
                      const SizedBox(width: 8),
                    ],

                    // Rotate All
                    if (_images.isNotEmpty) ...[
                      _QuickSequenceButton(
                        icon: Icons.rotate_right_rounded,
                        label: 'Rotate All',
                        onTap: _rotateAll,
                      ),
                      const SizedBox(width: 8),
                    ],

                    // Clear All
                    if (_images.isNotEmpty)
                      _QuickSequenceButton(
                        icon: Icons.delete_sweep_outlined,
                        label: 'Clear',
                        isDestructive: true,
                        onTap: _clearAll,
                      ),
                  ],
                ),
              ),
            ),

            // Page Sequence Display Area
            Expanded(
              child: _images.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.picture_as_pdf_outlined,
                            size: 56,
                            color: isDark ? Colors.white24 : Colors.black26,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No photos selected yet',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          AppButton(
                            label: 'Select Photos',
                            icon: Icons.add_photo_alternate_rounded,
                            onPressed: _pickImages,
                          ),
                        ],
                      ),
                    )
                  : _viewMode == _PdfPageViewMode.grid
                      ? _buildGridView(isDark)
                      : _buildListView(isDark),
            ),

            // Collapsible / Floating PDF Settings Surface
            GlassSurface(
              borderRadius: AppSpacing.radiusXl,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Row 1: Page Size & Orientation
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<PdfPageSize>(
                          value: _pageSize,
                          isDense: true,
                          decoration: const InputDecoration(
                            labelText: 'Page Size',
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                          ),
                          items: PdfPageSize.values.map((s) {
                            return DropdownMenuItem(
                              value: s,
                              child: Text(
                                s.label,
                                style: const TextStyle(fontSize: 12.5),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _pageSize = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<PdfOrientation>(
                          value: _orientation,
                          isDense: true,
                          decoration: const InputDecoration(
                            labelText: 'Orientation',
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                          ),
                          items: PdfOrientation.values.map((o) {
                            return DropdownMenuItem(
                              value: o,
                              child: Text(
                                o.label,
                                style: const TextStyle(fontSize: 12.5),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _orientation = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Row 2: Margins & Fill Page Toggle
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<double>(
                          value: _marginPoints,
                          isDense: true,
                          decoration: const InputDecoration(
                            labelText: 'Margins',
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(value: 0.0, child: Text('0 pt (Borderless)', style: TextStyle(fontSize: 12.5))),
                            DropdownMenuItem(value: 10.0, child: Text('10 pt', style: TextStyle(fontSize: 12.5))),
                            DropdownMenuItem(value: 16.0, child: Text('16 pt', style: TextStyle(fontSize: 12.5))),
                            DropdownMenuItem(value: 24.0, child: Text('24 pt', style: TextStyle(fontSize: 12.5))),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _marginPoints = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      InkWell(
                        onTap: () => setState(() => _fillPage = !_fillPage),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox(
                                value: _fillPage,
                                activeColor: AppColors.accentIndigo,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                                onChanged: (val) => setState(() => _fillPage = val ?? false),
                              ),
                              const SizedBox(width: 4),
                              const Text('Fill Page', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'PDF Filename',
                      hintText: 'document',
                      suffixText: '.pdf',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    label: 'Create PDF (${_images.length} Pages)',
                    icon: Icons.picture_as_pdf_rounded,
                    width: double.infinity,
                    onPressed: _images.isNotEmpty ? _createPdf : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Grid View (Ideal for sequencing 10, 20, 50+ pages) ---

  Widget _buildGridView(bool isDark) {
    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.82,
      ),
      itemCount: _images.length,
      itemBuilder: (context, index) {
        final item = _images[index];
        final isFirst = index == 0;
        final isLast = index == _images.length - 1;

        return GlassSurface(
          borderRadius: AppSpacing.radiusMd,
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Row: Page Number & Options Menu
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.accentIndigo,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Page ${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded, size: 18),
                    padding: EdgeInsets.zero,
                    itemBuilder: (context) => [
                      if (!isFirst)
                        const PopupMenuItem(
                          value: 'move_first',
                          child: Text('Move to First (Page 1)'),
                        ),
                      if (!isLast)
                        const PopupMenuItem(
                          value: 'move_last',
                          child: Text('Move to Last'),
                        ),
                      const PopupMenuItem(
                        value: 'duplicate',
                        child: Text('Duplicate Page'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Remove Page', style: TextStyle(color: AppColors.error)),
                      ),
                    ],
                    onSelected: (val) {
                      switch (val) {
                        case 'move_first':
                          _moveToFirst(index);
                          break;
                        case 'move_last':
                          _moveToLast(index);
                          break;
                        case 'duplicate':
                          _duplicateImage(index);
                          break;
                        case 'delete':
                          _removeImage(index);
                          break;
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Image Thumbnail (Tap to preview full screen)
              Expanded(
                child: GestureDetector(
                  onTap: () => _previewImage(item, index + 1),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      color: isDark ? Colors.black38 : const Color(0xFFE2E8F0),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          RotatedBox(
                            quarterTurns: item.rotationDegrees ~/ 90,
                            child: Image.file(
                              File(item.path),
                              fit: BoxFit.cover,
                            ),
                          ),
                          if (item.rotationDegrees > 0)
                            Positioned(
                              bottom: 4,
                              left: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.black87,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${item.rotationDegrees}°',
                                  style: const TextStyle(color: Colors.white, fontSize: 10),
                                ),
                              ),
                            ),
                          const Positioned(
                            bottom: 4,
                            right: 4,
                            child: CircleAvatar(
                              radius: 11,
                              backgroundColor: Colors.black54,
                              child: Icon(Icons.zoom_in_rounded, size: 14, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),

              // Bottom Sequence Controls: Move Left, Rotate, Move Right
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_rounded, size: 15),
                    tooltip: 'Move Earlier',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: isFirst ? null : () => _movePage(index, index - 1),
                  ),
                  IconButton(
                    icon: const Icon(Icons.rotate_90_degrees_cw_rounded, size: 16),
                    tooltip: 'Rotate 90°',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _rotateImage(index),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios_rounded, size: 15),
                    tooltip: 'Move Later',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: isLast ? null : () => _movePage(index, index + 1),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.error),
                    tooltip: 'Remove',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _removeImage(index),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // --- List View with Reorderable List ---

  Widget _buildListView(bool isDark) {
    return ReorderableListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      itemCount: _images.length,
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (oldIndex < newIndex) newIndex -= 1;
          final item = _images.removeAt(oldIndex);
          _images.insert(newIndex, item);
        });
      },
      itemBuilder: (context, index) {
        final item = _images[index];
        final isFirst = index == 0;
        final isLast = index == _images.length - 1;

        return Padding(
          key: ValueKey('${item.path}_$index'),
          padding: const EdgeInsets.only(bottom: 8),
          child: GlassSurface(
            borderRadius: AppSpacing.radiusMd,
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 13,
                  backgroundColor: AppColors.accentIndigo,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => _previewImage(item, index + 1),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: RotatedBox(
                        quarterTurns: item.rotationDegrees ~/ 90,
                        child: Image.file(File(item.path), fit: BoxFit.cover),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Page ${index + 1}${item.rotationDegrees > 0 ? " • Rotated ${item.rotationDegrees}°" : ""}',
                        style: const TextStyle(fontSize: 11, color: AppColors.accentIndigo),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_upward_rounded, size: 18),
                  tooltip: 'Move Up',
                  onPressed: isFirst ? null : () => _movePage(index, index - 1),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_downward_rounded, size: 18),
                  tooltip: 'Move Down',
                  onPressed: isLast ? null : () => _movePage(index, index + 1),
                ),
                IconButton(
                  icon: const Icon(Icons.rotate_90_degrees_cw_rounded, size: 18),
                  tooltip: 'Rotate',
                  onPressed: () => _rotateImage(index),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.error),
                  tooltip: 'Remove',
                  onPressed: () => _removeImage(index),
                ),
                const Icon(Icons.drag_indicator_rounded, color: Colors.grey, size: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _QuickSequenceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _QuickSequenceButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isDestructive ? AppColors.error.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isDestructive ? AppColors.error : AppColors.accentIndigo,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: isDestructive ? AppColors.error : AppColors.accentIndigo,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
