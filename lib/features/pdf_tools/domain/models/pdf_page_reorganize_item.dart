import 'dart:typed_data';

/// Represents a single page within the PDF Organizer / Sequence tool.
class PdfPageReorganizeItem {
  final String id;
  final int originalPageIndex;
  final int initialPageNumber;
  final String sourcePdfPath;
  int rotationDegrees;
  Uint8List? thumbnailBytes;

  PdfPageReorganizeItem({
    required this.id,
    required this.originalPageIndex,
    required this.initialPageNumber,
    required this.sourcePdfPath,
    this.rotationDegrees = 0,
    this.thumbnailBytes,
  });

  PdfPageReorganizeItem copyWith({
    String? id,
    int? originalPageIndex,
    int? initialPageNumber,
    String? sourcePdfPath,
    int? rotationDegrees,
    Uint8List? thumbnailBytes,
  }) {
    return PdfPageReorganizeItem(
      id: id ?? this.id,
      originalPageIndex: originalPageIndex ?? this.originalPageIndex,
      initialPageNumber: initialPageNumber ?? this.initialPageNumber,
      sourcePdfPath: sourcePdfPath ?? this.sourcePdfPath,
      rotationDegrees: rotationDegrees ?? this.rotationDegrees,
      thumbnailBytes: thumbnailBytes ?? this.thumbnailBytes,
    );
  }
}
