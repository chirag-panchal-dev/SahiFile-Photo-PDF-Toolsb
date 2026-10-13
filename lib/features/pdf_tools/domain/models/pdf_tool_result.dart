class PdfToolResult {
  final String outputPath;
  final String outputFileName;
  final int pageCount;
  final int originalSizeBytes;
  final int actualSizeBytes;
  final String operationLabel;
  final String? note;

  const PdfToolResult({
    required this.outputPath,
    required this.outputFileName,
    required this.pageCount,
    this.originalSizeBytes = 0,
    required this.actualSizeBytes,
    required this.operationLabel,
    this.note,
  });

  bool get isSizeReduced =>
      originalSizeBytes > 0 && actualSizeBytes < originalSizeBytes;

  double get reductionPercentage {
    if (originalSizeBytes <= 0 || actualSizeBytes >= originalSizeBytes) {
      return 0;
    }
    return ((originalSizeBytes - actualSizeBytes) / originalSizeBytes) * 100;
  }
}
