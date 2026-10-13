import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:sahifile/core/errors/app_error.dart';
import 'package:sahifile/core/models/result.dart';
import 'package:sahifile/core/utils/file_utils.dart';
import 'package:sahifile/features/photo_editor/domain/models/photo_edit_params.dart';
import 'package:sahifile/features/photo_editor/domain/models/photo_process_result.dart';

class ImageProcessingService {
  /// Asynchronously processes an image in a background isolate
  Future<Result<PhotoProcessResult>> processImage(
    PhotoEditParams params,
  ) async {
    try {
      final sourceFile = File(params.sourcePath);
      if (!await sourceFile.exists()) {
        return Failure(AppError.fileNotFound(params.sourcePath));
      }

      final originalSizeBytes = await sourceFile.length();
      if (originalSizeBytes == 0) {
        return Failure(AppError.corruptFile('The source file is 0 bytes.'));
      }

      final rawBytes = await sourceFile.readAsBytes();

      final computeResult = await compute(_isolateProcessImage, {
        'bytes': rawBytes,
        'targetWidth': params.targetWidth,
        'targetHeight': params.targetHeight,
        'cropRectLeft': params.cropRect?.left,
        'cropRectTop': params.cropRect?.top,
        'cropRectWidth': params.cropRect?.width,
        'cropRectHeight': params.cropRect?.height,
        'rotation': params.rotationDegrees,
        'format': params.format.name,
        'maxFileSizeBytes': params.maxFileSizeBytes,
        'bgR': params.backgroundColor.r.toInt(),
        'bgG': params.backgroundColor.g.toInt(),
        'bgB': params.backgroundColor.b.toInt(),
        'isSignature': params.isSignature,
      });

      if (computeResult['error'] != null) {
        return Failure(AppError.corruptFile(computeResult['error'] as String));
      }

      final encodedBytes = computeResult['bytes'] as Uint8List;
      final finalQuality = computeResult['finalQuality'] as int;
      final targetSizeAchieved = computeResult['targetSizeAchieved'] as bool;
      final achievedWidth = computeResult['width'] as int;
      final achievedHeight = computeResult['height'] as int;
      final warning = computeResult['warning'] as String?;

      final extension = params.format.extension;
      final outputFile = await FileUtils.createOutputFile(
        params.outputBaseName,
        extension,
      );

      await outputFile.writeAsBytes(encodedBytes, flush: true);
      final actualSizeBytes = await outputFile.length();

      // Automatically save to Gallery / Library by default
      try {
        await FileUtils.saveImageToGallery(outputFile.path, album: 'SahiFile');
      } catch (_) {}

      final result = PhotoProcessResult(
        outputPath: outputFile.path,
        outputFileName: outputFile.path.split('/').last,
        originalSizeBytes: originalSizeBytes,
        actualSizeBytes: actualSizeBytes,
        actualWidth: achievedWidth,
        actualHeight: achievedHeight,
        format: params.format,
        finalQuality: finalQuality,
        targetSizeAchieved: targetSizeAchieved,
        warningMessage: warning,
      );

      return Success(result);
    } catch (e) {
      return Failure(AppError.unknown(e));
    }
  }

  static Future<Map<String, dynamic>?> inspectImage(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;
      final bytes = await file.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;

      final normalized = img.bakeOrientation(decoded);
      return {
        'width': normalized.width,
        'height': normalized.height,
        'sizeBytes': bytes.length,
        'format': file.path.split('.').last.toUpperCase(),
      };
    } catch (_) {
      return null;
    }
  }
}

Map<String, dynamic> _isolateProcessImage(Map<String, dynamic> args) {
  try {
    final rawBytes = args['bytes'] as Uint8List;
    var decoded = img.decodeImage(rawBytes);
    if (decoded == null) {
      return {'error': 'Could not decode image format.'};
    }

    decoded = img.bakeOrientation(decoded);

    final rotation = args['rotation'] as int? ?? 0;
    if (rotation != 0) {
      decoded = img.copyRotate(decoded, angle: rotation);
    }

    final cropLeft = args['cropRectLeft'] as double?;
    final cropTop = args['cropRectTop'] as double?;
    final cropWidth = args['cropRectWidth'] as double?;
    final cropHeight = args['cropRectHeight'] as double?;

    if (cropLeft != null &&
        cropTop != null &&
        cropWidth != null &&
        cropHeight != null &&
        cropWidth > 0 &&
        cropHeight > 0) {
      final pixelX = (cropLeft * decoded.width).round().clamp(
        0,
        decoded.width - 1,
      );
      final pixelY = (cropTop * decoded.height).round().clamp(
        0,
        decoded.height - 1,
      );
      final pixelW = (cropWidth * decoded.width).round().clamp(
        1,
        decoded.width - pixelX,
      );
      final pixelH = (cropHeight * decoded.height).round().clamp(
        1,
        decoded.height - pixelY,
      );

      decoded = img.copyCrop(
        decoded,
        x: pixelX,
        y: pixelY,
        width: pixelW,
        height: pixelH,
      );
    }

    final targetW = (args['targetWidth'] as int).clamp(10, 8000);
    final targetH = (args['targetHeight'] as int).clamp(10, 8000);

    if (decoded.width != targetW || decoded.height != targetH) {
      decoded = img.copyResize(
        decoded,
        width: targetW,
        height: targetH,
        interpolation: img.Interpolation.linear,
      );
    }

    final formatStr = args['format'] as String;
    final isJpg = formatStr == 'jpg';

    if (isJpg || decoded.hasAlpha) {
      final bgR = (args['bgR'] as int? ?? 255).clamp(0, 255);
      final bgG = (args['bgG'] as int? ?? 255).clamp(0, 255);
      final bgB = (args['bgB'] as int? ?? 255).clamp(0, 255);

      final flattened = img.Image(
        width: decoded.width,
        height: decoded.height,
        numChannels: 3,
      );

      img.fill(flattened, color: img.ColorRgb8(bgR, bgG, bgB));
      img.compositeImage(flattened, decoded);
      decoded = flattened;
    }

    final maxBytes = args['maxFileSizeBytes'] as int?;
    int finalQuality = 90;
    bool targetSizeAchieved = true;
    String? warning;
    Uint8List finalBytes;

    if (isJpg) {
      if (maxBytes != null && maxBytes > 0) {
        int lowQuality = 15;
        int highQuality = 96;
        Uint8List? bestBytes;
        int bestQuality = lowQuality;

        while (lowQuality <= highQuality) {
          final midQuality = (lowQuality + highQuality) ~/ 2;
          final candidate = img.encodeJpg(decoded, quality: midQuality);

          if (candidate.length <= maxBytes) {
            bestBytes = candidate;
            bestQuality = midQuality;
            lowQuality = midQuality + 1;
          } else {
            highQuality = midQuality - 1;
          }
        }

        if (bestBytes != null) {
          finalBytes = bestBytes;
          finalQuality = bestQuality;
        } else {
          finalBytes = img.encodeJpg(decoded, quality: 15);
          finalQuality = 15;
          targetSizeAchieved = false;
          final kb = (finalBytes.length / 1024).round();
          final targetKb = (maxBytes / 1024).round();
          warning =
              'Could not reach under $targetKb KB at ${decoded.width}x${decoded.height} px (minimum reached: $kb KB). Try reducing dimensions.';
        }
      } else {
        finalQuality = 88;
        finalBytes = img.encodeJpg(decoded, quality: finalQuality);
      }
    } else {
      finalBytes = img.encodePng(decoded, level: 6);
      finalQuality = 100;
      if (maxBytes != null && finalBytes.length > maxBytes) {
        targetSizeAchieved = false;
        final kb = (finalBytes.length / 1024).round();
        final targetKb = (maxBytes / 1024).round();
        warning =
            'Lossless PNG is $kb KB, which exceeds target $targetKb KB. Consider JPG format for strict size limits.';
      }
    }

    return {
      'bytes': finalBytes,
      'finalQuality': finalQuality,
      'targetSizeAchieved': targetSizeAchieved,
      'width': decoded.width,
      'height': decoded.height,
      'warning': warning,
    };
  } catch (e) {
    return {'error': e.toString()};
  }
}
