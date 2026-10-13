import 'dart:io';
import 'package:file_saver/file_saver.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import '../constants/app_constants.dart';
import 'formatters.dart';

class FileUtils {
  FileUtils._();

  /// Gets the dedicated app workspace directory inside application documents
  static Future<Directory> getWorkspaceDirectory() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final workspaceDir = Directory(
      '${docsDir.path}/${AppConstants.appWorkspaceDir}',
    );
    if (!await workspaceDir.exists()) {
      await workspaceDir.create(recursive: true);
    }
    return workspaceDir;
  }

  /// Gets the temporary processing directory
  static Future<Directory> getTempDirectory() async {
    final cacheDir = await getTemporaryDirectory();
    final tempDir = Directory('${cacheDir.path}/formmate_cache');
    if (!await tempDir.exists()) {
      await tempDir.create(recursive: true);
    }
    return tempDir;
  }

  /// Safely creates a working copy of a source file in the app's temp workspace
  /// This guarantees the user's original input file is NEVER modified or overwritten.
  static Future<File> createWorkingCopy(File sourceFile, String prefix) async {
    final tempDir = await getTempDirectory();
    final ext = sourceFile.path.split('.').last;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final workingCopyPath = '${tempDir.path}/${prefix}_copy_$timestamp.$ext';
    return await sourceFile.copy(workingCopyPath);
  }

  /// Generates a new file in the app workspace for a successfully processed output
  static Future<File> createOutputFile(
    String baseName,
    String extension,
  ) async {
    final workspace = await getWorkspaceDirectory();
    final safeName = Formatters.formatSafeFileName(baseName, extension);
    var outputPath = '${workspace.path}/$safeName';
    var file = File(outputPath);

    // If file with same name exists, append counter
    var counter = 1;
    while (await file.exists()) {
      final nameWithoutExt =
          baseName.replaceAll(RegExp(r'[^\w\s\-]'), '').trim();
      final ext =
          extension.startsWith('.') ? extension.substring(1) : extension;
      outputPath = '${workspace.path}/${nameWithoutExt}_$counter.$ext';
      file = File(outputPath);
      counter++;
    }

    return file;
  }

  /// Measures exact file size in bytes
  static Future<int> getFileSizeBytes(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      return await file.length();
    }
    return 0;
  }

  /// Validates file exists and has non-zero bytes
  static Future<bool> isValidFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return false;
    final length = await file.length();
    return length > 0;
  }

  /// Safely deletes a file if it exists
  static Future<bool> safeDeleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
    } catch (_) {
      // Ignore if deletion failed
    }
    return false;
  }

  /// Calculates total size of cached files
  static Future<int> getCacheSize() async {
    try {
      final tempDir = await getTempDirectory();
      int total = 0;
      if (await tempDir.exists()) {
        await for (final entity in tempDir.list(recursive: true)) {
          if (entity is File) {
            total += await entity.length();
          }
        }
      }
      return total;
    } catch (_) {
      return 0;
    }
  }

  /// Clears temporary cache workspace
  static Future<void> clearCache() async {
    try {
      final tempDir = await getTempDirectory();
      if (await tempDir.exists()) {
        await for (final entity in tempDir.list(recursive: false)) {
          try {
            await entity.delete(recursive: true);
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  /// Saves an image directly to the phone's root Gallery / Camera Roll.
  /// Works across Android (MediaStore) and iOS (Photos Library).
  /// Saves directly to the root media library so it appears immediately in the main Gallery view.
  static Future<bool> saveImageToGallery(
    String filePath, {
    String? album,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return false;

      // 1. Save directly to root Gallery (shows immediately on main Photos/Gallery screen)
      try {
        final hasAccess = await Gal.hasAccess(toAlbum: false);
        if (!hasAccess) {
          await Gal.requestAccess(toAlbum: false);
        }
        if (album != null && album.isNotEmpty) {
          try {
            await Gal.putImage(filePath, album: album);
            return true;
          } catch (_) {}
        }
        await Gal.putImage(filePath);
        return true;
      } catch (_) {}

      // 2. Direct MediaStore save via FileSaver (Pictures root)
      try {
        final bytes = await file.readAsBytes();
        final fileName = filePathBasename(filePath);
        final saved = await FileSaver.instance.saveFile(
          name: fileName,
          bytes: bytes,
          mimeType: fileName.toLowerCase().endsWith('.png')
              ? MimeType.png
              : MimeType.jpeg,
        );
        if (saved.isNotEmpty) return true;
      } catch (_) {}

      // 3. Fallback on Android: copy directly to root Pictures & DCIM
      if (Platform.isAndroid) {
        final fileName = filePathBasename(filePath);
        try {
          final picDir = Directory('/storage/emulated/0/Pictures');
          if (await picDir.exists()) {
            await file.copy('${picDir.path}/$fileName');
            return true;
          }
        } catch (_) {}
        try {
          final dcimDir = Directory('/storage/emulated/0/DCIM');
          if (await dcimDir.exists()) {
            await file.copy('${dcimDir.path}/$fileName');
            return true;
          }
        } catch (_) {}
      }

      return false;
    } catch (_) {
      return false;
    }
  }

  /// Saves a PDF directly to the phone's public root Downloads & Documents directory.
  /// Uses MediaStore on Android (no subfolder, appears immediately in Downloads/Files app).
  static Future<String?> savePdfToDownloads(
    String filePath,
    String fileName, {
    String? folder,
  }) async {
    try {
      final source = File(filePath);
      if (!await source.exists()) return null;

      final cleanName = Formatters.formatSafeFileName(fileName, 'pdf');
      final bytes = await source.readAsBytes();

      // 1. Save directly to public Downloads root via FileSaver
      try {
        final savedPath = await FileSaver.instance.saveFile(
          name: cleanName,
          bytes: bytes,
          mimeType: MimeType.pdf,
        );
        if (savedPath.isNotEmpty) {
          return savedPath;
        }
      } catch (_) {}

      // 2. Fallback to direct copy into root Download or Documents directory
      Directory? targetDir;
      if (Platform.isAndroid) {
        final publicDownload = Directory('/storage/emulated/0/Download');
        final publicDocs = Directory('/storage/emulated/0/Documents');
        if (await publicDownload.exists()) {
          targetDir = publicDownload;
        } else if (await publicDocs.exists()) {
          targetDir = publicDocs;
        } else {
          targetDir = await getDownloadsDirectory();
        }
      } else {
        targetDir = await getDownloadsDirectory() ??
            await getApplicationDocumentsDirectory();
      }

      targetDir ??= await getApplicationDocumentsDirectory();

      var destination = File('${targetDir.path}/$cleanName');
      var counter = 1;
      while (await destination.exists()) {
        final baseName = fileName.replaceAll(
          RegExp(r'\.pdf$', caseSensitive: false),
          '',
        );
        destination = File('${targetDir.path}/${baseName}_$counter.pdf');
        counter++;
      }

      await source.copy(destination.path);
      return destination.path;
    } catch (_) {
      return null;
    }
  }

  static String filePathBasename(String path) {
    return path.split(Platform.pathSeparator).last;
  }
}

