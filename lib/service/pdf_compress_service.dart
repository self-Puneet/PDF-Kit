// lib/service/pdf_compress_service.dart
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:pdf_kit/models/file_model.dart';
import 'package:pdf_kit/service/pdf_merge_service.dart' show CustomException;
import 'package:pdf_kit/service/pdf_rasterization_service.dart';

/// Compress a PDF by rasterizing it, compressing page images,
/// and rebuilding a flattened PDF (via PdfRasterizationService).
class PdfCompressService {
  PdfCompressService._();

  /// Compress the provided [fileInfo] which must be a PDF.
  ///
  /// - Uses PdfRasterizationService.rasterizeAndCompressPdf under the hood.
  /// - [level] parameter is ignored since rasterization uses fixed quality (80%)
  /// - Writes the final file into [destinationPath] if provided, otherwise
  ///   falls back to the original parent directory or temp directory.
  /// - Returns a new [FileInfo] describing the compressed PDF.
  static Future<Either<CustomException, FileInfo>> compressFile({
    required FileInfo fileInfo,
    int level = 1, // Ignored, kept for compatibility
    String? destinationPath,
  }) async {
    try {
      // 1. Validate input type.
      final isPdf = fileInfo.extension.toLowerCase() == 'pdf';
      if (!isPdf) {
        return left(
          CustomException(
            message: 'Unsupported file type. Only PDF is allowed.',
            code: 'UNSUPPORTED_TYPE',
          ),
        );
      }

      final inputFile = File(fileInfo.path);
      if (!await inputFile.exists()) {
        return left(
          CustomException(
            message: 'Input file does not exist.',
            code: 'FILE_NOT_FOUND',
          ),
        );
      }

      // 2. Resolve destination directory.
      final Directory targetDir = await _resolveDestination(
        destinationPath: destinationPath,
        fallbackOriginalParent: fileInfo.parentDirectory,
      );

      // 3. Run rasterization + compression pipeline.
      final rasterResult =
          await PdfRasterizationService.rasterizeAndCompressPdf(
            inputPdf: inputFile,
          );

      // 4. Map rasterization result into CustomException / FileInfo.
      return await rasterResult.fold(
        (failure) async {
          return left(
            CustomException(
              message: failure.message,
              code: 'RASTERIZATION_FAILED',
            ),
          );
        },
        (rasterizedFile) async {
          // Decide final filename in targetDir.
          final originalBase = p.basenameWithoutExtension(fileInfo.name);
          final baseName = '${originalBase}_compressed';

          final newName = _uniqueFileName(
            baseDir: targetDir.path,
            baseName: baseName,
          );
          final finalPath = p.join(targetDir.path, newName);

          // If rasterizer already saved to the desired path, reuse it;
          // otherwise copy then optionally delete the temp one.
          File finalFile;
          if (rasterizedFile.path == finalPath) {
            finalFile = rasterizedFile;
          } else {
            finalFile = await rasterizedFile.copy(finalPath);
            // Best-effort cleanup.
            if (rasterizedFile.path != inputFile.path) {
              await rasterizedFile.delete().catchError((_) => rasterizedFile);
            }
          }

          final stats = await finalFile.stat();

          final resultInfo = FileInfo(
            name: p.basename(finalFile.path),
            path: finalFile.path,
            extension: 'pdf',
            size: stats.size,
            lastModified: stats.modified,
            mimeType: 'application/pdf',
            parentDirectory: p.dirname(finalFile.path),
          );

          return right(resultInfo);
        },
      );
    } catch (e) {
      return left(
        CustomException(
          message: 'PDF compression failed: ${e.toString()}',
          code: 'COMPRESSION_ERROR',
        ),
      );
    }
  }

  /// Resolve destination directory:
  /// - [destinationPath] if valid
  /// - else original file parent
  /// - else app temp directory. [web:46][web:55]
  static Future<Directory> _resolveDestination({
    String? destinationPath,
    String? fallbackOriginalParent,
  }) async {
    if (destinationPath != null && destinationPath.isNotEmpty) {
      final dir = Directory(destinationPath);
      if (await dir.exists()) return dir;
    }

    if (fallbackOriginalParent != null && fallbackOriginalParent.isNotEmpty) {
      final dir = Directory(fallbackOriginalParent);
      if (await dir.exists()) return dir;
    }

    return getTemporaryDirectory();
  }

  /// Generate a unique PDF filename in [baseDir] with base name [baseName].
  static String _uniqueFileName({
    required String baseDir,
    required String baseName,
  }) {
    var candidate = '$baseName.pdf';
    var idx = 1;
    while (File(p.join(baseDir, candidate)).existsSync()) {
      candidate = '${baseName}_$idx.pdf';
      idx++;
    }
    return candidate;
  }
}
