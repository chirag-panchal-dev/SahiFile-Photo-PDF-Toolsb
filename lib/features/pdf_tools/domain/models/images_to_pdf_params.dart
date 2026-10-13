enum PdfPageSize {
  a4,
  letter,
  fitToImage;

  String get label => switch (this) {
    PdfPageSize.a4 => 'A4 (Standard)',
    PdfPageSize.letter => 'US Letter',
    PdfPageSize.fitToImage => 'Fit to Photo Size',
  };
}

enum PdfOrientation {
  portrait,
  landscape,
  auto;

  String get label => switch (this) {
    PdfOrientation.portrait => 'Portrait',
    PdfOrientation.landscape => 'Landscape',
    PdfOrientation.auto => 'Match Photo Orientation',
  };
}

class ImageItem {
  final String path;
  final String name;
  final int rotationDegrees;

  const ImageItem({
    required this.path,
    required this.name,
    this.rotationDegrees = 0,
  });

  ImageItem copyWith({String? path, String? name, int? rotationDegrees}) {
    return ImageItem(
      path: path ?? this.path,
      name: name ?? this.name,
      rotationDegrees: rotationDegrees ?? this.rotationDegrees,
    );
  }
}

class ImagesToPdfParams {
  final List<ImageItem> images;
  final PdfPageSize pageSize;
  final PdfOrientation orientation;
  final double marginPoints;
  final bool fillPage;
  final String outputBaseName;

  const ImagesToPdfParams({
    required this.images,
    this.pageSize = PdfPageSize.a4,
    this.orientation = PdfOrientation.portrait,
    this.marginPoints = 16.0,
    this.fillPage = false,
    required this.outputBaseName,
  });
}
