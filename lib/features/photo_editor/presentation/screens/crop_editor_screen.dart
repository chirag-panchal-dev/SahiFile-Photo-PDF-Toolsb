import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sahifile/app/providers.dart';
import 'package:sahifile/app/theme/app_colors.dart';
import 'package:sahifile/app/theme/app_spacing.dart';
import 'package:sahifile/core/models/result.dart';
import 'package:sahifile/core/widgets/app_button.dart';
import 'package:sahifile/core/widgets/app_dialog.dart';
import 'package:sahifile/core/widgets/glass_app_bar.dart';
import 'package:sahifile/core/widgets/loading_overlay.dart';
import 'package:sahifile/features/photo_editor/domain/models/photo_edit_params.dart';
import 'package:sahifile/features/photo_editor/domain/models/photo_process_result.dart';
import 'package:sahifile/features/photo_editor/presentation/screens/photo_result_screen.dart';

enum _CropHandle {
  none,
  center,
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
  top,
  bottom,
  left,
  right,
}

class CropEditorScreen extends ConsumerStatefulWidget {
  final PhotoEditParams params;
  final double targetAspectRatio;

  const CropEditorScreen({
    super.key,
    required this.params,
    required this.targetAspectRatio,
  });

  @override
  ConsumerState<CropEditorScreen> createState() => _CropEditorScreenState();
}

class _CropEditorScreenState extends ConsumerState<CropEditorScreen> {
  int _rotationDegrees = 0;
  double? _lockedAspectRatio; // null means freeform
  String _activePresetLabel = 'Custom';

  // Crop rect in normalized 0.0 -> 1.0 coordinates
  Rect _cropRect = const Rect.fromLTWH(0.08, 0.08, 0.84, 0.84);
  _CropHandle _activeHandle = _CropHandle.none;
  bool _showLivePreview = true;

  static const double _minSize = 0.15; // Minimum 15% of width/height
  static const double _handleHitRadius = 28.0;

  @override
  void initState() {
    super.initState();
    _rotationDegrees = widget.params.rotationDegrees;
    _lockedAspectRatio = widget.targetAspectRatio > 0 ? widget.targetAspectRatio : null;
    _activePresetLabel = _findPresetLabel(_lockedAspectRatio);
    _initializeCropRect();
  }

  String _findPresetLabel(double? ratio) {
    if (ratio == null) return 'Free';
    if ((ratio - 1.0).abs() < 0.01) return '1:1';
    if ((ratio - (3.0 / 4.0)).abs() < 0.02) return '3:4 Passport';
    if ((ratio - (3.0 / 5.0)).abs() < 0.02) return '3:5 Signature';
    if ((ratio - (4.0 / 3.0)).abs() < 0.02) return '4:3';
    if ((ratio - (16.0 / 9.0)).abs() < 0.02) return '16:9';
    return 'Fixed';
  }

  void _initializeCropRect() {
    final ratio = _lockedAspectRatio;
    if (ratio == null) {
      _cropRect = const Rect.fromLTWH(0.08, 0.08, 0.84, 0.84);
    } else if (ratio >= 1.0) {
      final width = 0.86;
      final height = (width / ratio).clamp(_minSize, 0.90);
      final top = (1.0 - height) / 2;
      final left = (1.0 - width) / 2;
      _cropRect = Rect.fromLTWH(left, top, width, height);
    } else {
      final height = 0.86;
      final width = (height * ratio).clamp(_minSize, 0.90);
      final top = (1.0 - height) / 2;
      final left = (1.0 - width) / 2;
      _cropRect = Rect.fromLTWH(left, top, width, height);
    }
  }

  void _setAspectRatio(double? ratio, String label) {
    setState(() {
      _lockedAspectRatio = ratio;
      _activePresetLabel = label;
      _initializeCropRect();
    });
  }

  void _rotate90() {
    setState(() {
      _rotationDegrees = (_rotationDegrees + 90) % 360;
    });
  }

  void _resetCrop() {
    setState(() {
      _rotationDegrees = 0;
      _initializeCropRect();
    });
  }

  void _onPanStart(DragStartDetails details, Size canvasSize) {
    final local = details.localPosition;
    final rectPx = Rect.fromLTWH(
      _cropRect.left * canvasSize.width,
      _cropRect.top * canvasSize.height,
      _cropRect.width * canvasSize.width,
      _cropRect.height * canvasSize.height,
    );

    // Check corners first (highest priority)
    if ((local - rectPx.topLeft).distance <= _handleHitRadius) {
      _activeHandle = _CropHandle.topLeft;
    } else if ((local - rectPx.topRight).distance <= _handleHitRadius) {
      _activeHandle = _CropHandle.topRight;
    } else if ((local - rectPx.bottomLeft).distance <= _handleHitRadius) {
      _activeHandle = _CropHandle.bottomLeft;
    } else if ((local - rectPx.bottomRight).distance <= _handleHitRadius) {
      _activeHandle = _CropHandle.bottomRight;
    } else if (_lockedAspectRatio == null &&
        (local.dy - rectPx.top).abs() <= _handleHitRadius &&
        local.dx >= rectPx.left &&
        local.dx <= rectPx.right) {
      _activeHandle = _CropHandle.top;
    } else if (_lockedAspectRatio == null &&
        (local.dy - rectPx.bottom).abs() <= _handleHitRadius &&
        local.dx >= rectPx.left &&
        local.dx <= rectPx.right) {
      _activeHandle = _CropHandle.bottom;
    } else if (_lockedAspectRatio == null &&
        (local.dx - rectPx.left).abs() <= _handleHitRadius &&
        local.dy >= rectPx.top &&
        local.dy <= rectPx.bottom) {
      _activeHandle = _CropHandle.left;
    } else if (_lockedAspectRatio == null &&
        (local.dx - rectPx.right).abs() <= _handleHitRadius &&
        local.dy >= rectPx.top &&
        local.dy <= rectPx.bottom) {
      _activeHandle = _CropHandle.right;
    } else if (rectPx.contains(local)) {
      _activeHandle = _CropHandle.center;
    } else {
      _activeHandle = _CropHandle.none;
    }
    setState(() {});
  }

  void _onPanUpdate(DragUpdateDetails details, Size canvasSize) {
    if (_activeHandle == _CropHandle.none) return;

    final dxNorm = details.delta.dx / canvasSize.width;
    final dyNorm = details.delta.dy / canvasSize.height;

    double left = _cropRect.left;
    double top = _cropRect.top;
    double right = _cropRect.right;
    double bottom = _cropRect.bottom;

    if (_activeHandle == _CropHandle.center) {
      // Move entire crop box
      final width = _cropRect.width;
      final height = _cropRect.height;
      left = (left + dxNorm).clamp(0.0, 1.0 - width);
      top = (top + dyNorm).clamp(0.0, 1.0 - height);
      _cropRect = Rect.fromLTWH(left, top, width, height);
      setState(() {});
      return;
    }

    // Handle resizing
    final ratio = _lockedAspectRatio;

    if (ratio == null) {
      // Freeform resize
      switch (_activeHandle) {
        case _CropHandle.topLeft:
          left = math.min(left + dxNorm, right - _minSize).clamp(0.0, 1.0);
          top = math.min(top + dyNorm, bottom - _minSize).clamp(0.0, 1.0);
          break;
        case _CropHandle.topRight:
          right = math.max(right + dxNorm, left + _minSize).clamp(0.0, 1.0);
          top = math.min(top + dyNorm, bottom - _minSize).clamp(0.0, 1.0);
          break;
        case _CropHandle.bottomLeft:
          left = math.min(left + dxNorm, right - _minSize).clamp(0.0, 1.0);
          bottom = math.max(bottom + dyNorm, top + _minSize).clamp(0.0, 1.0);
          break;
        case _CropHandle.bottomRight:
          right = math.max(right + dxNorm, left + _minSize).clamp(0.0, 1.0);
          bottom = math.max(bottom + dyNorm, top + _minSize).clamp(0.0, 1.0);
          break;
        case _CropHandle.top:
          top = math.min(top + dyNorm, bottom - _minSize).clamp(0.0, 1.0);
          break;
        case _CropHandle.bottom:
          bottom = math.max(bottom + dyNorm, top + _minSize).clamp(0.0, 1.0);
          break;
        case _CropHandle.left:
          left = math.min(left + dxNorm, right - _minSize).clamp(0.0, 1.0);
          break;
        case _CropHandle.right:
          right = math.max(right + dxNorm, left + _minSize).clamp(0.0, 1.0);
          break;
        default:
          break;
      }
    } else {
      // Locked aspect ratio resize: preserve AR = width / height
      switch (_activeHandle) {
        case _CropHandle.bottomRight:
          var newW = math.max(right - left + dxNorm, _minSize);
          var newH = newW / ratio;
          if (left + newW > 1.0) {
            newW = 1.0 - left;
            newH = newW / ratio;
          }
          if (top + newH > 1.0) {
            newH = 1.0 - top;
            newW = newH * ratio;
          }
          right = left + newW;
          bottom = top + newH;
          break;

        case _CropHandle.topLeft:
          var newW = math.max(right - left - dxNorm, _minSize);
          var newH = newW / ratio;
          if (right - newW < 0.0) {
            newW = right;
            newH = newW / ratio;
          }
          if (bottom - newH < 0.0) {
            newH = bottom;
            newW = newH * ratio;
          }
          left = right - newW;
          top = bottom - newH;
          break;

        case _CropHandle.topRight:
          var newW = math.max(right - left + dxNorm, _minSize);
          var newH = newW / ratio;
          if (left + newW > 1.0) {
            newW = 1.0 - left;
            newH = newW / ratio;
          }
          if (bottom - newH < 0.0) {
            newH = bottom;
            newW = newH * ratio;
          }
          right = left + newW;
          top = bottom - newH;
          break;

        case _CropHandle.bottomLeft:
          var newW = math.max(right - left - dxNorm, _minSize);
          var newH = newW / ratio;
          if (right - newW < 0.0) {
            newW = right;
            newH = newW / ratio;
          }
          if (top + newH > 1.0) {
            newH = 1.0 - top;
            newW = newH * ratio;
          }
          left = right - newW;
          bottom = top + newH;
          break;

        default:
          break;
      }
    }

    // Final safety clamps
    left = left.clamp(0.0, 1.0 - _minSize);
    top = top.clamp(0.0, 1.0 - _minSize);
    right = right.clamp(left + _minSize, 1.0);
    bottom = bottom.clamp(top + _minSize, 1.0);

    _cropRect = Rect.fromLTRB(left, top, right, bottom);
    setState(() {});
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _activeHandle = _CropHandle.none;
    });
  }

  Future<void> _processImage() async {
    final updatedParams = widget.params.copyWith(
      rotationDegrees: _rotationDegrees,
      cropRect: _cropRect,
    );

    final service = ref.read(imageProcessingServiceProvider);

    final result = await LoadingOverlay.show<Result<PhotoProcessResult>>(
      context: context,
      message: 'Processing photo...',
      subMessage: 'Applying crop, high-quality resize & target KB compression',
      asyncWork: () => service.processImage(updatedParams),
    );

    if (!mounted) return;

    result.when(
      onSuccess: (processResult) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder:
                (context) => PhotoResultScreen(
                  result: processResult,
                  sourceParams: updatedParams,
                ),
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
        title: 'Crop & Frame',
        actions: [
          IconButton(
            icon: Icon(
              _showLivePreview
                  ? Icons.visibility_rounded
                  : Icons.visibility_off_rounded,
            ),
            tooltip: _showLivePreview ? 'Hide Live Preview' : 'Show Live Preview',
            onPressed: () => setState(() => _showLivePreview = !_showLivePreview),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Reset Frame',
            onPressed: _resetCrop,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Touch Instruction Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.pan_tool_alt_rounded,
                    size: 15,
                    color: AppColors.accentIndigo,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Drag corners to resize • Drag center to move frame',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color:
                          isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Aspect Ratio Selector Chips
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                physics: const BouncingScrollPhysics(),
                children: [
                  _AspectRatioChip(
                    label: 'Freeform',
                    icon: Icons.crop_free_rounded,
                    isSelected: _lockedAspectRatio == null,
                    onTap: () => _setAspectRatio(null, 'Free'),
                  ),
                  const SizedBox(width: 8),
                  _AspectRatioChip(
                    label: '1:1 Square',
                    icon: Icons.crop_square_rounded,
                    isSelected: _lockedAspectRatio != null &&
                        (_lockedAspectRatio! - 1.0).abs() < 0.01,
                    onTap: () => _setAspectRatio(1.0, '1:1'),
                  ),
                  const SizedBox(width: 8),
                  _AspectRatioChip(
                    label: '3:4 Passport',
                    icon: Icons.portrait_rounded,
                    isSelected: _lockedAspectRatio != null &&
                        (_lockedAspectRatio! - (3.0 / 4.0)).abs() < 0.02,
                    onTap: () => _setAspectRatio(3.0 / 4.0, '3:4 Passport'),
                  ),
                  const SizedBox(width: 8),
                  _AspectRatioChip(
                    label: '3:5 Signature',
                    icon: Icons.border_color_rounded,
                    isSelected: _lockedAspectRatio != null &&
                        (_lockedAspectRatio! - (3.0 / 5.0)).abs() < 0.02,
                    onTap: () => _setAspectRatio(3.0 / 5.0, '3:5 Signature'),
                  ),
                  const SizedBox(width: 8),
                  _AspectRatioChip(
                    label: '4:3 Standard',
                    icon: Icons.crop_5_4_rounded,
                    isSelected: _lockedAspectRatio != null &&
                        (_lockedAspectRatio! - (4.0 / 3.0)).abs() < 0.02,
                    onTap: () => _setAspectRatio(4.0 / 3.0, '4:3'),
                  ),
                  const SizedBox(width: 8),
                  _AspectRatioChip(
                    label: '16:9 Wide',
                    icon: Icons.crop_16_9_rounded,
                    isSelected: _lockedAspectRatio != null &&
                        (_lockedAspectRatio! - (16.0 / 9.0)).abs() < 0.02,
                    onTap: () => _setAspectRatio(16.0 / 9.0, '16:9'),
                  ),
                ],
              ),
            ),

            // Crop Canvas Area (Overflow-safe constrained square)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final side = math.min(constraints.maxWidth, constraints.maxHeight);
                    if (side <= 0) return const SizedBox.shrink();
                    final canvasSize = Size(side, side);

                    final rectPx = Rect.fromLTWH(
                      _cropRect.left * canvasSize.width,
                      _cropRect.top * canvasSize.height,
                      _cropRect.width * canvasSize.width,
                      _cropRect.height * canvasSize.height,
                    );

                    return Center(
                      child: SizedBox(
                        width: side,
                        height: side,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: side,
                              height: side,
                              decoration: BoxDecoration(
                                color: isDark ? Colors.black45 : const Color(0xFFE2E8F0),
                                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                                border: Border.all(
                                  color: isDark
                                      ? AppColors.darkGlassBorder
                                      : AppColors.lightGlassBorder,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                                child: GestureDetector(
                              onPanStart: (d) => _onPanStart(d, canvasSize),
                              onPanUpdate: (d) => _onPanUpdate(d, canvasSize),
                              onPanEnd: _onPanEnd,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  // The Source Photo
                                  RotatedBox(
                                    quarterTurns: _rotationDegrees ~/ 90,
                                    child: Image.file(
                                      File(widget.params.sourcePath),
                                      fit: BoxFit.contain,
                                    ),
                                  ),

                                  // Semi-transparent Shroud over outside area
                                  CustomPaint(
                                    size: canvasSize,
                                    painter: _CropShroudPainter(rectPx),
                                  ),

                                  // Crop Box Border & Grid
                                  Positioned(
                                    left: rectPx.left,
                                    top: rectPx.top,
                                    width: rectPx.width,
                                    height: rectPx.height,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2.0,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.35),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                      child: Stack(
                                        children: [
                                          // Rule of Thirds Grid Lines
                                          Column(
                                            children: [
                                              const Spacer(),
                                              Divider(
                                                color: Colors.white.withValues(alpha: 0.45),
                                                height: 1,
                                                thickness: 1,
                                              ),
                                              const Spacer(),
                                              Divider(
                                                color: Colors.white.withValues(alpha: 0.45),
                                                height: 1,
                                                thickness: 1,
                                              ),
                                              const Spacer(),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              const Spacer(),
                                              VerticalDivider(
                                                color: Colors.white.withValues(alpha: 0.45),
                                                width: 1,
                                                thickness: 1,
                                              ),
                                              const Spacer(),
                                              VerticalDivider(
                                                color: Colors.white.withValues(alpha: 0.45),
                                                width: 1,
                                                thickness: 1,
                                              ),
                                              const Spacer(),
                                            ],
                                          ),

                                          // Center Aspect Ratio Badge
                                          Center(
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 3,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.black54,
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                _activePresetLabel,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  // 4 Prominent Corner Drag Handles
                                  _buildCornerHandle(rectPx.topLeft, _CropHandle.topLeft),
                                  _buildCornerHandle(rectPx.topRight, _CropHandle.topRight),
                                  _buildCornerHandle(rectPx.bottomLeft, _CropHandle.bottomLeft),
                                  _buildCornerHandle(rectPx.bottomRight, _CropHandle.bottomRight),

                                  // Side Edge Drag Indicators (for freeform mode)
                                  if (_lockedAspectRatio == null) ...[
                                    _buildEdgeHandle(
                                      Offset(rectPx.left + rectPx.width / 2, rectPx.top),
                                      isHorizontal: true,
                                    ),
                                    _buildEdgeHandle(
                                      Offset(rectPx.left + rectPx.width / 2, rectPx.bottom),
                                      isHorizontal: true,
                                    ),
                                    _buildEdgeHandle(
                                      Offset(rectPx.left, rectPx.top + rectPx.height / 2),
                                      isHorizontal: false,
                                    ),
                                    _buildEdgeHandle(
                                      Offset(rectPx.right, rectPx.top + rectPx.height / 2),
                                      isHorizontal: false,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),

                            // Parallel Live Preview Floating PiP
                            if (_showLivePreview)
                              Positioned(
                                right: 10,
                                top: 10,
                                child: _buildLiveCropPreview(isDark),
                              )
                            else
                              Positioned(
                                right: 10,
                                top: 10,
                                child: InkWell(
                                  onTap: () => setState(() => _showLivePreview = true),
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xDE1A2238) : Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: AppColors.accentIndigo.withValues(alpha: 0.6),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.2),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.visibility_rounded,
                                          size: 13,
                                          color: AppColors.accentIndigo,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Preview',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.accentIndigo,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Controls Toolbar (Rotate, Reset)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton.icon(
                    onPressed: _rotate90,
                    icon: const Icon(
                      Icons.rotate_90_degrees_cw_rounded,
                      size: 18,
                    ),
                    label: Text('Rotate ($_rotationDegrees°)'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _resetCrop,
                    icon: const Icon(Icons.restore_rounded, size: 18),
                    label: const Text('Reset Frame'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Confirm & Prepare Action
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
              child: AppButton(
                label: 'Confirm & Prepare Photo',
                icon: Icons.check_circle_rounded,
                width: double.infinity,
                onPressed: _processImage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveCropPreview(bool isDark) {
    final cropAspect = (_cropRect.width / _cropRect.height).clamp(0.2, 5.0);
    const previewWidth = 92.0;
    final previewHeight = (previewWidth / cropAspect).clamp(50.0, 105.0);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xE6131A2C) : const Color(0xF2FFFFFF),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: AppColors.accentIndigo.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              const Text(
                'LIVE PREVIEW',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: AppColors.accentIndigo,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() => _showLivePreview = false),
                child: const Icon(
                  Icons.close_rounded,
                  size: 13,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Container(
              width: previewWidth,
              height: previewHeight,
              color: isDark ? Colors.black54 : const Color(0xFFF1F5F9),
              child: LayoutBuilder(
                builder: (context, box) {
                  final w = box.maxWidth;
                  final h = box.maxHeight;
                  final scaleX = 1.0 / _cropRect.width;
                  final scaleY = 1.0 / _cropRect.height;

                  return ClipRect(
                    child: Transform(
                      transform: Matrix4.identity()
                        ..scale(scaleX, scaleY, 1.0)
                        ..translate(-_cropRect.left * w, -_cropRect.top * h),
                      child: SizedBox(
                        width: w,
                        height: h,
                        child: RotatedBox(
                          quarterTurns: _rotationDegrees ~/ 90,
                          child: Image.file(
                            File(widget.params.sourcePath),
                            fit: BoxFit.fill,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: AppColors.accentIndigo.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${widget.params.targetWidth}×${widget.params.targetHeight} px',
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: AppColors.accentIndigo,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCornerHandle(Offset center, _CropHandle handle) {
    const handleVisualSize = 22.0;
    final isActive = _activeHandle == handle;

    return Positioned(
      left: center.dx - handleVisualSize / 2,
      top: center.dy - handleVisualSize / 2,
      child: IgnorePointer(
        child: Container(
          width: handleVisualSize,
          height: handleVisualSize,
          decoration: BoxDecoration(
            color: isActive ? AppColors.accentIndigo : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.accentIndigo,
              width: 3.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: isActive ? Colors.white : AppColors.accentIndigo,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEdgeHandle(Offset center, {required bool isHorizontal}) {
    return Positioned(
      left: isHorizontal ? center.dx - 14 : center.dx - 3,
      top: isHorizontal ? center.dy - 3 : center.dy - 14,
      child: IgnorePointer(
        child: Container(
          width: isHorizontal ? 28 : 6,
          height: isHorizontal ? 6 : 28,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AspectRatioChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _AspectRatioChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accentIndigo
              : (isDark ? Colors.white12 : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.accentIndigo
                : (isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected
                  ? Colors.white
                  : (isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : (isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CropShroudPainter extends CustomPainter {
  final Rect activeRect;

  _CropShroudPainter(this.activeRect);

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint =
        Paint()..color = Colors.black.withValues(alpha: 0.60);

    final path =
        Path()
          ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
          ..addRect(activeRect)
          ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, backgroundPaint);
  }

  @override
  bool shouldRepaint(covariant _CropShroudPainter oldDelegate) {
    return oldDelegate.activeRect != activeRect;
  }
}
