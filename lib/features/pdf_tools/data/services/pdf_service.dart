import 'dart:io';
import 'dart:ui';
import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;
import 'package:sahifile/core/errors/app_error.dart';
import 'package:sahifile/core/models/result.dart';
import 'package:sahifile/core/utils/file_utils.dart';
import 'package:sahifile/features/pdf_tools/domain/models/images_to_pdf_params.dart';
import 'package:sahifile/features/pdf_tools/domain/models/pdf_page_reorganize_item.dart';
import 'package:sahifile/features/pdf_tools/domain/models/pdf_tool_result.dart';

class PdfService {
  /// Converts multiple ordered images into a single PDF document
  Future<Result<PdfToolResult>> createPdfFromImages(
    ImagesToPdfParams params,
  ) async {
    try {
      if (params.images.isEmpty) {
        return Failure(
          const AppError(
            code: AppErrorCode.pdfEmpty,
            title: 'No Images Selected',
            message: 'Please select at least one photo to convert to PDF.',
          ),
        );
      }

      final pdfDoc = pw.Document();
      int totalOriginalBytes = 0;

      for (final item in params.images) {
        final file = File(item.path);
        if (!await file.exists()) continue;

        final rawBytes = await file.readAsBytes();
        totalOriginalBytes += rawBytes.length;

        var decoded = img.decodeImage(rawBytes);
        if (decoded == null) continue;

        decoded = img.bakeOrientation(decoded);

        if (item.rotationDegrees != 0) {
          decoded = img.copyRotate(decoded, angle: item.rotationDegrees);
        }

        final jpgBytes = img.encodeJpg(decoded, quality: 88);
        final pdfImage = pw.MemoryImage(jpgBytes);

        PdfPageFormat pageFormat;
        switch (params.pageSize) {
          case PdfPageSize.a4:
            pageFormat = PdfPageFormat.a4;
            break;
          case PdfPageSize.letter:
            pageFormat = PdfPageFormat.letter;
            break;
          case PdfPageSize.fitToImage:
            pageFormat = PdfPageFormat(
              decoded.width.toDouble(),
              decoded.height.toDouble(),
              marginAll: 0,
            );
            break;
        }

        if (params.pageSize != PdfPageSize.fitToImage) {
          if (params.orientation == PdfOrientation.landscape ||
              (params.orientation == PdfOrientation.auto &&
                  decoded.width > decoded.height)) {
            pageFormat = pageFormat.landscape;
          } else if (params.orientation == PdfOrientation.portrait) {
            pageFormat = pageFormat.portrait;
          }
        }

        pdfDoc.addPage(
          pw.Page(
            pageFormat: pageFormat,
            margin: pw.EdgeInsets.all(params.marginPoints),
            build: (pw.Context context) {
              return pw.Center(
                child: pw.Image(
                  pdfImage,
                  fit: params.fillPage ? pw.BoxFit.cover : pw.BoxFit.contain,
                ),
              );
            },
          ),
        );
      }

      final savedBytes = await pdfDoc.save();
      final outputFile = await FileUtils.createOutputFile(
        params.outputBaseName,
        'pdf',
      );
      await outputFile.writeAsBytes(savedBytes, flush: true);

      // Automatically save to public Downloads / Documents by default
      try {
        await FileUtils.savePdfToDownloads(
          outputFile.path,
          outputFile.path.split('/').last,
        );
      } catch (_) {}

      final actualSize = await outputFile.length();

      final result = PdfToolResult(
        outputPath: outputFile.path,
        outputFileName: outputFile.path.split('/').last,
        pageCount: params.images.length,
        originalSizeBytes: totalOriginalBytes,
        actualSizeBytes: actualSize,
        operationLabel: 'Images to PDF',
      );

      return Success(result);
    } catch (e) {
      return Failure(AppError.unknown(e));
    }
  }

  /// Merges multiple local PDF files into one clean document
  Future<Result<PdfToolResult>> mergePdfs({
    required List<String> pdfPaths,
    required String outputBaseName,
  }) async {
    try {
      if (pdfPaths.length < 2) {
        return Failure(
          const AppError(
            code: AppErrorCode.pdfMergeFailed,
            title: 'Need at Least 2 PDFs',
            message: 'Please choose at least two PDF files to merge together.',
            suggestion: 'Tap "Add PDF" to pick another document.',
          ),
        );
      }

      int totalOriginalBytes = 0;
      int totalPageCount = 0;
      final destinationDoc = sf.PdfDocument();

      for (final path in pdfPaths) {
        final file = File(path);
        if (!await file.exists()) {
          destinationDoc.dispose();
          return Failure(AppError.fileNotFound(path));
        }

        final fileBytes = await file.readAsBytes();
        totalOriginalBytes += fileBytes.length;

        try {
          final loadedDoc = sf.PdfDocument(inputBytes: fileBytes);
          totalPageCount += loadedDoc.pages.count;

          for (int i = 0; i < loadedDoc.pages.count; i++) {
            final template = loadedDoc.pages[i].createTemplate();
            final newPage = destinationDoc.pages.add();
            newPage.graphics.drawPdfTemplate(
              template,
              const Offset(0, 0),
              newPage.size,
            );
          }

          loadedDoc.dispose();
        } catch (e) {
          destinationDoc.dispose();
          final fileName = path.split('/').last;
          if (e.toString().toLowerCase().contains('password') ||
              e.toString().toLowerCase().contains('encrypt')) {
            return Failure(AppError.encryptedPdf(fileName));
          }
          return Failure(
            AppError.corruptFile(
              'Cannot read "$fileName". It might be damaged or password protected.',
            ),
          );
        }
      }

      final mergedBytes = destinationDoc.saveSync();
      destinationDoc.dispose();

      final outputFile = await FileUtils.createOutputFile(
        outputBaseName,
        'pdf',
      );
      await outputFile.writeAsBytes(mergedBytes, flush: true);

      // Automatically save to public Downloads / Documents by default
      try {
        await FileUtils.savePdfToDownloads(
          outputFile.path,
          outputFile.path.split('/').last,
        );
      } catch (_) {}

      final actualSize = await outputFile.length();

      final result = PdfToolResult(
        outputPath: outputFile.path,
        outputFileName: outputFile.path.split('/').last,
        pageCount: totalPageCount,
        originalSizeBytes: totalOriginalBytes,
        actualSizeBytes: actualSize,
        operationLabel: 'Merged PDF',
      );

      return Success(result);
    } catch (e) {
      return Failure(AppError.pdfMergeFailed(e.toString()));
    }
  }

  /// Optimizes PDF file size honestly on-device
  Future<Result<PdfToolResult>> optimizePdf({
    required String inputPath,
    required String outputBaseName,
  }) async {
    try {
      final file = File(inputPath);
      if (!await file.exists()) {
        return Failure(AppError.fileNotFound(inputPath));
      }

      final originalBytes = await file.readAsBytes();
      final originalSize = originalBytes.length;

      sf.PdfDocument doc;
      try {
        doc = sf.PdfDocument(inputBytes: originalBytes);
      } catch (e) {
        final fileName = inputPath.split('/').last;
        if (e.toString().toLowerCase().contains('password') ||
            e.toString().toLowerCase().contains('encrypt')) {
          return Failure(AppError.encryptedPdf(fileName));
        }
        return Failure(AppError.corruptFile('Unable to open "$fileName".'));
      }

      final pageCount = doc.pages.count;

      // Apply best compression
      doc.compressionLevel = sf.PdfCompressionLevel.best;

      final optimizedBytes = doc.saveSync();
      doc.dispose();

      final outputFile = await FileUtils.createOutputFile(
        outputBaseName,
        'pdf',
      );
      await outputFile.writeAsBytes(optimizedBytes, flush: true);

      // Automatically save to public Downloads / Documents by default
      try {
        await FileUtils.savePdfToDownloads(
          outputFile.path,
          outputFile.path.split('/').last,
        );
      } catch (_) {}

      final actualSize = await outputFile.length();

      String? note;
      if (actualSize >= originalSize) {
        note =
            'This PDF is already highly compressed. Further size reduction without downscaling embedded images is not possible.';
      }

      final result = PdfToolResult(
        outputPath: outputFile.path,
        outputFileName: outputFile.path.split('/').last,
        pageCount: pageCount,
        originalSizeBytes: originalSize,
        actualSizeBytes: actualSize,
        operationLabel: 'Optimized PDF',
        note: note,
      );

      return Success(result);
    } catch (e) {
      return Failure(AppError.unknown(e));
    }
  }

  /// Reorganizes, reorders, rotates, deletes, or duplicates pages in a PDF document
  Future<Result<PdfToolResult>> reorganizePdf({
    required List<PdfPageReorganizeItem> orderedPages,
    required String outputBaseName,
  }) async {
    try {
      if (orderedPages.isEmpty) {
        return Failure(
          const AppError(
            code: AppErrorCode.pdfEmpty,
            title: 'No Pages Remaining',
            message: 'All pages were removed. Please keep at least one page in the document.',
            suggestion: 'Restore at least one page to save the PDF.',
          ),
        );
      }

      final Map<String, sf.PdfDocument> loadedSources = {};
      int totalOriginalBytes = 0;

      try {
        for (final item in orderedPages) {
          if (!loadedSources.containsKey(item.sourcePdfPath)) {
            final file = File(item.sourcePdfPath);
            if (!await file.exists()) {
              for (final doc in loadedSources.values) {
                doc.dispose();
              }
              return Failure(AppError.fileNotFound(item.sourcePdfPath));
            }
            final bytes = await file.readAsBytes();
            totalOriginalBytes += bytes.length;
            loadedSources[item.sourcePdfPath] = sf.PdfDocument(inputBytes: bytes);
          }
        }

        final destinationDoc = sf.PdfDocument();

        for (final item in orderedPages) {
          final srcDoc = loadedSources[item.sourcePdfPath]!;
          if (item.originalPageIndex < 0 ||
              item.originalPageIndex >= srcDoc.pages.count) {
            continue;
          }

          final srcPage = srcDoc.pages[item.originalPageIndex];
          final template = srcPage.createTemplate();

          sf.PdfPageRotateAngle rotateAngle = sf.PdfPageRotateAngle.rotateAngle0;
          final normRot = (item.rotationDegrees % 360 + 360) % 360;
          if (normRot == 90) {
            rotateAngle = sf.PdfPageRotateAngle.rotateAngle90;
          } else if (normRot == 180) {
            rotateAngle = sf.PdfPageRotateAngle.rotateAngle180;
          } else if (normRot == 270) {
            rotateAngle = sf.PdfPageRotateAngle.rotateAngle270;
          }

          destinationDoc.pageSettings.rotate = rotateAngle;
          final newPage = destinationDoc.pages.add();
          newPage.graphics.drawPdfTemplate(
            template,
            const Offset(0, 0),
            srcPage.size,
          );
        }

        final outputBytes = destinationDoc.saveSync();
        destinationDoc.dispose();

        for (final doc in loadedSources.values) {
          doc.dispose();
        }

        final outputFile = await FileUtils.createOutputFile(
          outputBaseName,
          'pdf',
        );
        await outputFile.writeAsBytes(outputBytes, flush: true);

        // Automatically save to public Downloads / Documents by default
        try {
          await FileUtils.savePdfToDownloads(
            outputFile.path,
            outputFile.path.split('/').last,
          );
        } catch (_) {}

        final actualSize = await outputFile.length();

        final result = PdfToolResult(
          outputPath: outputFile.path,
          outputFileName: outputFile.path.split('/').last,
          pageCount: orderedPages.length,
          originalSizeBytes: totalOriginalBytes,
          actualSizeBytes: actualSize,
          operationLabel: 'Organized PDF',
        );

        return Success(result);
      } catch (innerError) {
        for (final doc in loadedSources.values) {
          try {
            doc.dispose();
          } catch (_) {}
        }
        return Failure(AppError.unknown(innerError));
      }
    } catch (e) {
      return Failure(AppError.unknown(e));
    }
  }
}
