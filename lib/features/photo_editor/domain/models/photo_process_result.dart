import 'package:sahifile/features/presets/domain/models/preset_item.dart';

class PhotoProcessResult {
  final String outputPath;
  final String outputFileName;
  final int originalSizeBytes;
  final int actualSizeBytes;
  final int actualWidth;
  final int actualHeight;
  final OutputFormat format;
  final int finalQuality;
  final bool targetSizeAchieved;
  final String? warningMessage;

  const PhotoProcessResult({
    required this.outputPath,
    required this.outputFileName,
    required this.originalSizeBytes,
    required this.actualSizeBytes,
    required this.actualWidth,
    required this.actualHeight,
    required this.format,
    required this.finalQuality,
    required this.targetSizeAchieved,
    this.warningMessage,
  });

  double get compressionPercentage {
    if (originalSizeBytes <= 0) return 0;
    final diff = originalSizeBytes - actualSizeBytes;
    return (diff / originalSizeBytes) * 100;
  }
}
