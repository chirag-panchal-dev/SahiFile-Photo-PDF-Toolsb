enum AppErrorCode {
  fileNotFound,
  unsupportedFormat,
  corruptFile,
  targetSizeImpossible,
  encryptedPdf,
  pdfMergeFailed,
  pdfEmpty,
  storageLow,
  cancelled,
  permissionDenied,
  operationTimeout,
  unknown,
}

class AppError {
  final AppErrorCode code;
  final String title;
  final String message;
  final String? suggestion;
  final dynamic technicalDetails;

  const AppError({
    required this.code,
    required this.title,
    required this.message,
    this.suggestion,
    this.technicalDetails,
  });

  factory AppError.fileNotFound([String? path]) => AppError(
    code: AppErrorCode.fileNotFound,
    title: 'File Not Found',
    message: 'The selected file could not be found or has been moved.',
    suggestion: 'Please pick the file again from your device storage.',
    technicalDetails: path,
  );

  factory AppError.unsupportedFormat([String? format]) => AppError(
    code: AppErrorCode.unsupportedFormat,
    title: 'Unsupported File Format',
    message:
        format != null
            ? 'The file format "$format" is not supported.'
            : 'The selected file format is not supported.',
    suggestion: 'Please select a supported image (JPG, PNG, WEBP) or PDF file.',
    technicalDetails: format,
  );

  factory AppError.corruptFile([String? details]) => AppError(
    code: AppErrorCode.corruptFile,
    title: 'Unable to Read File',
    message: 'The file appears to be damaged or corrupted.',
    suggestion:
        'Your original file was not altered. Try re-downloading or choosing a different copy.',
    technicalDetails: details,
  );

  factory AppError.targetSizeImpossible({
    required int requestedKb,
    required int achievedKb,
  }) => AppError(
    code: AppErrorCode.targetSizeImpossible,
    title: 'Target Size Too Small',
    message:
        'Could not compress the image below $requestedKb KB at the chosen dimensions (best reached: $achievedKb KB).',
    suggestion:
        'Try reducing the pixel dimensions (width/height) or increasing your target size limit.',
  );

  factory AppError.encryptedPdf([String? fileName]) => AppError(
    code: AppErrorCode.encryptedPdf,
    title: 'Password Protected PDF',
    message:
        fileName != null
            ? '"$fileName" is encrypted or password-protected.'
            : 'This PDF file is password protected.',
    suggestion:
        'Please unlock the PDF or remove the password before importing it into FormMate.',
  );

  factory AppError.pdfMergeFailed(String reason) => AppError(
    code: AppErrorCode.pdfMergeFailed,
    title: 'PDF Merge Failed',
    message: 'Unable to merge the selected PDF documents: $reason',
    suggestion:
        'Check that all selected PDFs are valid and not password protected, then try again.',
    technicalDetails: reason,
  );

  factory AppError.storageLow() => const AppError(
    code: AppErrorCode.storageLow,
    title: 'Low Storage Space',
    message: 'There is not enough storage space on your device.',
    suggestion:
        'Please free up some storage space on your phone and try again.',
  );

  factory AppError.cancelled() => const AppError(
    code: AppErrorCode.cancelled,
    title: 'Operation Cancelled',
    message: 'The operation was cancelled by the user.',
  );

  factory AppError.unknown(dynamic error) => AppError(
    code: AppErrorCode.unknown,
    title: 'Something Went Wrong',
    message: 'An unexpected error occurred while processing your request.',
    suggestion: 'Please try again. If the issue persists, try another file.',
    technicalDetails: error?.toString(),
  );

  @override
  String toString() =>
      'AppError(code: $code, title: $title, message: $message, suggestion: $suggestion)';
}
