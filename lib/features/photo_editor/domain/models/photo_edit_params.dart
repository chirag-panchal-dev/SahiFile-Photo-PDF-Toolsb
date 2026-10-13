import 'dart:ui';
import 'package:sahifile/features/presets/domain/models/preset_item.dart';

class PhotoEditParams {
  final String sourcePath;
  final int targetWidth;
  final int targetHeight;
  final Rect? cropRect;
  final int rotationDegrees;
  final OutputFormat format;
  final int? maxFileSizeBytes;
  final Color backgroundColor;
  final String outputBaseName;
  final bool isSignature;

  const PhotoEditParams({
    required this.sourcePath,
    required this.targetWidth,
    required this.targetHeight,
    this.cropRect,
    this.rotationDegrees = 0,
    this.format = OutputFormat.jpg,
    this.maxFileSizeBytes,
    this.backgroundColor = const Color(0xFFFFFFFF),
    required this.outputBaseName,
    this.isSignature = false,
  });

  PhotoEditParams copyWith({
    String? sourcePath,
    int? targetWidth,
    int? targetHeight,
    Rect? cropRect,
    int? rotationDegrees,
    OutputFormat? format,
    int? maxFileSizeBytes,
    Color? backgroundColor,
    String? outputBaseName,
    bool? isSignature,
  }) {
    return PhotoEditParams(
      sourcePath: sourcePath ?? this.sourcePath,
      targetWidth: targetWidth ?? this.targetWidth,
      targetHeight: targetHeight ?? this.targetHeight,
      cropRect: cropRect ?? this.cropRect,
      rotationDegrees: rotationDegrees ?? this.rotationDegrees,
      format: format ?? this.format,
      maxFileSizeBytes: maxFileSizeBytes ?? this.maxFileSizeBytes,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      outputBaseName: outputBaseName ?? this.outputBaseName,
      isSignature: isSignature ?? this.isSignature,
    );
  }
}
