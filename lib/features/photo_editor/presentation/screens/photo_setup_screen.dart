import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../app/providers.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/glass_surface.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/glass_app_bar.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../presets/domain/models/preset_item.dart';
import '../../data/services/image_processing_service.dart';
import '../../domain/models/photo_edit_params.dart';
import 'crop_editor_screen.dart';

class PhotoSetupScreen extends ConsumerStatefulWidget {
  final String imagePath;
  final bool isSignature;
  final bool isCompressOnly;

  const PhotoSetupScreen({
    super.key,
    required this.imagePath,
    this.isSignature = false,
    this.isCompressOnly = false,
  });

  @override
  ConsumerState<PhotoSetupScreen> createState() => _PhotoSetupScreenState();
}

class _PhotoSetupScreenState extends ConsumerState<PhotoSetupScreen> {
  late String _currentPath;
  int _originalWidth = 0;
  int _originalHeight = 0;
  int _originalSizeBytes = 0;
  String _originalFormat = 'JPG';

  bool _isLoading = true;
  bool _isCustomMode = false;
  PresetItem? _selectedPreset;

  // Controllers
  late TextEditingController _widthController;
  late TextEditingController _heightController;
  late TextEditingController _maxKbController;

  bool _lockAspect = true;
  double _aspectRatio = 1.0;
  OutputFormat _selectedFormat = OutputFormat.jpg;
  Color _backgroundColor = Colors.white;

  final List<Color> _availableBgColors = [
    Colors.white,
    const Color(0xFFF8F9FA),
    const Color(0xFFE2E8F0),
    const Color(0xFFDCEAFE), // light blue passport standard
  ];

  @override
  void initState() {
    super.initState();
    _currentPath = widget.imagePath;
    _widthController = TextEditingController();
    _heightController = TextEditingController();
    _maxKbController = TextEditingController();

    _inspectImage();
  }

  @override
  void dispose() {
    _widthController.dispose();
    _heightController.dispose();
    _maxKbController.dispose();
    super.dispose();
  }

  Future<void> _inspectImage() async {
    setState(() => _isLoading = true);
    final info = await ImageProcessingService.inspectImage(_currentPath);
    if (info != null) {
      _originalWidth = info['width'] as int;
      _originalHeight = info['height'] as int;
      _originalSizeBytes = info['sizeBytes'] as int;
      _originalFormat = info['format'] as String;

      _aspectRatio =
          _originalHeight > 0 ? (_originalWidth / _originalHeight) : 1.0;

      // Select default preset
      final presets = ref.read(presetsControllerProvider);
      if (widget.isSignature) {
        _selectedPreset = presets.firstWhere(
          (p) => p.category == 'Signature',
          orElse: () => presets.first,
        );
      } else {
        _selectedPreset = presets.first;
      }

      if (_selectedPreset != null) {
        _applyPreset(_selectedPreset!);
      } else {
        _widthController.text = '$_originalWidth';
        _heightController.text = '$_originalHeight';
        _maxKbController.text = '100';
      }
    }
    setState(() => _isLoading = false);
  }

  void _applyPreset(PresetItem preset) {
    setState(() {
      _selectedPreset = preset;
      _widthController.text = '${preset.targetWidth}';
      _heightController.text = '${preset.targetHeight}';
      _maxKbController.text = '${preset.maxFileSizeBytes ~/ 1024}';
      _selectedFormat = preset.format;
      _aspectRatio = preset.aspectRatio;
    });
  }

  void _onWidthChanged(String val) {
    final w = int.tryParse(val);
    if (w != null && _lockAspect && _aspectRatio > 0) {
      final h = (w / _aspectRatio).round();
      _heightController.text = '$h';
    }
  }

  void _onHeightChanged(String val) {
    final h = int.tryParse(val);
    if (h != null && _lockAspect && _aspectRatio > 0) {
      final w = (h * _aspectRatio).round();
      _widthController.text = '$w';
    }
  }

  Future<void> _changePhoto() async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _currentPath = picked.path);
      await _inspectImage();
    }
  }

  void _proceedToCrop() {
    final w = int.tryParse(_widthController.text.trim()) ?? _originalWidth;
    final h = int.tryParse(_heightController.text.trim()) ?? _originalHeight;
    final maxKb = int.tryParse(_maxKbController.text.trim());

    if (w < 20 || h < 20) {
      AppDialog.showError(
        context,
        title: 'Invalid Dimensions',
        message: 'Width and height must be at least 20 pixels.',
        suggestion: 'Please enter valid pixel dimensions for your document.',
      );
      return;
    }

    final targetAspectRatio = (w / h);

    final params = PhotoEditParams(
      sourcePath: _currentPath,
      targetWidth: w,
      targetHeight: h,
      format: _selectedFormat,
      maxFileSizeBytes: maxKb != null ? maxKb * 1024 : null,
      backgroundColor: _backgroundColor,
      outputBaseName: widget.isSignature ? 'signature' : 'photo',
      isSignature: widget.isSignature,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => CropEditorScreen(
              params: params,
              targetAspectRatio: targetAspectRatio,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final presets = ref.watch(presetsControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final title =
        widget.isSignature
            ? 'Signature Setup'
            : widget.isCompressOnly
            ? 'Compress Image'
            : 'Photo Setup';

    return Scaffold(
      appBar: GlassAppBar(title: title),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SafeArea(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  children: [
                    // Image Preview Card
                    GlassSurface(
                      borderRadius: AppSpacing.radiusLg,
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMd,
                            ),
                            child: Container(
                              height: 200,
                              width: double.infinity,
                              color:
                                  isDark
                                      ? Colors.black26
                                      : const Color(0xFFF1F5F9),
                              child: Image.file(
                                File(_currentPath),
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      Formatters.formatDimensions(
                                        _originalWidth,
                                        _originalHeight,
                                      ),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color:
                                            isDark
                                                ? AppColors.darkTextPrimary
                                                : AppColors.lightTextPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: [
                                        StatusBadge(
                                          label: Formatters.formatBytes(
                                            _originalSizeBytes,
                                          ),
                                          type: StatusBadgeType.primary,
                                        ),
                                        StatusBadge(
                                          label: _originalFormat,
                                          type: StatusBadgeType.neutral,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                onPressed: _changePhoto,
                                icon: const Icon(
                                  Icons.swap_horiz_rounded,
                                  size: 17,
                                ),
                                label: Text(strings.pickAnotherImage),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusSm,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Segmented Tabs: Presets vs Custom
                    Row(
                      children: [
                        Expanded(
                          child: _SegmentTab(
                            label: strings.presetTab,
                            isSelected: !_isCustomMode,
                            onTap: () => setState(() => _isCustomMode = false),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _SegmentTab(
                            label: strings.customTab,
                            isSelected: _isCustomMode,
                            onTap: () => setState(() => _isCustomMode = true),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Presets Selection
                    if (!_isCustomMode) ...[
                      Text(
                        'Choose Form Requirement',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color:
                              isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            presets.map((preset) {
                              final isSelected =
                                  _selectedPreset?.id == preset.id;
                              return ChoiceChip(
                                label: Text(preset.name),
                                selected: isSelected,
                                onSelected: (selected) {
                                  if (selected) _applyPreset(preset);
                                },
                                labelStyle: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight:
                                      isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                  color:
                                      isSelected
                                          ? Colors.white
                                          : (isDark
                                              ? AppColors.darkTextPrimary
                                              : AppColors.lightTextPrimary),
                                ),
                                selectedColor: AppColors.accentIndigo,
                                backgroundColor:
                                    isDark
                                        ? Colors.white.withValues(alpha: 0.08)
                                        : Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusSm,
                                  ),
                                  side: BorderSide(
                                    color:
                                        isSelected
                                            ? AppColors.accentIndigo
                                            : (isDark
                                                ? AppColors.darkGlassBorder
                                                : AppColors.lightGlassBorder),
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                      const SizedBox(height: 18),
                    ],

                    // Dimensions Form
                    GlassSurface(
                      borderRadius: AppSpacing.radiusLg,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Target Dimensions & File Size',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color:
                                  isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Width & Height Fields
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _widthController,
                                  keyboardType: TextInputType.number,
                                  onChanged: _onWidthChanged,
                                  decoration: InputDecoration(
                                    labelText: strings.widthPx,
                                    prefixIcon: const Icon(
                                      Icons.swap_horiz_rounded,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _heightController,
                                  keyboardType: TextInputType.number,
                                  onChanged: _onHeightChanged,
                                  decoration: InputDecoration(
                                    labelText: strings.heightPx,
                                    prefixIcon: const Icon(
                                      Icons.swap_vert_rounded,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Aspect Lock Toggle
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _lockAspect
                                        ? Icons.lock_outline_rounded
                                        : Icons.lock_open_rounded,
                                    size: 18,
                                    color: AppColors.accentIndigo,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    strings.lockAspect,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w500,
                                      color:
                                          isDark
                                              ? AppColors.darkTextPrimary
                                              : AppColors.lightTextPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              Switch.adaptive(
                                value: _lockAspect,
                                onChanged: (val) {
                                  setState(() {
                                    _lockAspect = val;
                                    final w = int.tryParse(
                                      _widthController.text.trim(),
                                    );
                                    final h = int.tryParse(
                                      _heightController.text.trim(),
                                    );
                                    if (w != null && h != null && h > 0) {
                                      _aspectRatio = w / h;
                                    }
                                  });
                                },
                                activeColor: AppColors.accentIndigo,
                              ),
                            ],
                          ),
                          const Divider(height: 24),

                          // Target Max File Size in KB
                          TextField(
                            controller: _maxKbController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: strings.maxFileSizeKb,
                              hintText: 'e.g. 50 (leaves safe margin below)',
                              prefixIcon: const Icon(
                                Icons.speed_rounded,
                                size: 18,
                              ),
                              suffixText: 'KB',
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Format & Background Fill
                    GlassSurface(
                      borderRadius: AppSpacing.radiusLg,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Output Format & Color',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color:
                                  isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // JPG vs PNG Choice
                          Row(
                            children:
                                OutputFormat.values.map((fmt) {
                                  final isSel = _selectedFormat == fmt;
                                  return Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        right: fmt == OutputFormat.jpg ? 8 : 0,
                                        left: fmt == OutputFormat.png ? 8 : 0,
                                      ),
                                      child: InkWell(
                                        onTap:
                                            () => setState(
                                              () => _selectedFormat = fmt,
                                            ),
                                        borderRadius: BorderRadius.circular(
                                          AppSpacing.radiusMd,
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                isSel
                                                    ? AppColors.accentIndigo
                                                        .withValues(alpha: 0.15)
                                                    : (isDark
                                                        ? Colors.white10
                                                        : Colors.white),
                                            borderRadius: BorderRadius.circular(
                                              AppSpacing.radiusMd,
                                            ),
                                            border: Border.all(
                                              color:
                                                  isSel
                                                      ? AppColors.accentIndigo
                                                      : (isDark
                                                          ? AppColors
                                                              .darkGlassBorder
                                                          : AppColors
                                                              .lightGlassBorder),
                                              width: isSel ? 1.8 : 1.0,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              fmt.label,
                                              style: TextStyle(
                                                fontSize: 13.5,
                                                fontWeight:
                                                    isSel
                                                        ? FontWeight.w700
                                                        : FontWeight.w500,
                                                color:
                                                    isSel
                                                        ? AppColors.accentIndigo
                                                        : (isDark
                                                            ? AppColors
                                                                .darkTextPrimary
                                                            : AppColors
                                                                .lightTextPrimary),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                          ),

                          if (_selectedFormat == OutputFormat.jpg) ...[
                            const SizedBox(height: 14),
                            Text(
                              strings.backgroundFill,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color:
                                    isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children:
                                  _availableBgColors.map((color) {
                                    final isSelected =
                                        _backgroundColor.toARGB32() ==
                                        color.toARGB32();
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 12),
                                      child: InkWell(
                                        onTap:
                                            () => setState(
                                              () => _backgroundColor = color,
                                            ),
                                        borderRadius: BorderRadius.circular(20),
                                        child: Container(
                                          width: 34,
                                          height: 34,
                                          decoration: BoxDecoration(
                                            color: color,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color:
                                                  isSelected
                                                      ? AppColors.accentIndigo
                                                      : Colors.grey.shade400,
                                              width: isSelected ? 2.5 : 1,
                                            ),
                                          ),
                                          child:
                                              isSelected
                                                  ? const Icon(
                                                    Icons.check,
                                                    size: 18,
                                                    color:
                                                        AppColors.accentIndigo,
                                                  )
                                                  : null,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Continue to Crop CTA
                    AppButton(
                      label: 'Continue to Crop & Position',
                      icon: Icons.crop_rounded,
                      onPressed: _proceedToCrop,
                    ),
                  ],
                ),
              ),
    );
  }
}

class _SegmentTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SegmentTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? AppColors.accentIndigo
                  : (isDark ? Colors.white10 : Colors.white),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color:
                isSelected
                    ? AppColors.accentIndigo
                    : (isDark
                        ? AppColors.darkGlassBorder
                        : AppColors.lightGlassBorder),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color:
                  isSelected
                      ? Colors.white
                      : (isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary),
            ),
          ),
        ),
      ),
    );
  }
}
