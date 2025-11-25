// lib/service/pdf_merge_service.dart
import 'dart:io';
import 'dart:ui';

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;

import 'package:pdf_kit/models/file_model.dart';
import 'package:pdf_kit/core/constants.dart';
import 'package:pdf_kit/service/pdf_compress_service.dart';

/// Size analysis result for merge operation
class _SizeAnalysis {
  final int totalInputSize;
  final int estimatedOutputSize;
  final int pdfTotalSize;
  final int imageTotalSize;

  _SizeAnalysis({
    required this.totalInputSize,
    required this.estimatedOutputSize,
    required this.pdfTotalSize,
    required this.imageTotalSize,
  });
}

/// Custom exception for PDF merge operations
class CustomException {
  final String message;
  final String code;

  const CustomException({required this.message, required this.code});

  @override
  String toString() => 'CustomException($code): $message';
}

/// Service for merging multiple PDF files using Syncfusion Flutter PDF
class PdfMergeService {
  PdfMergeService._();

  /// Merges multiple PDF files and/or images into a single PDF document.
  /// Images are compressed based on size requirements.
  ///
  /// [files] - List of PDF files and/or images to merge
  /// [outputFileName] - Name for the merged PDF file (without extension)
  /// [destinationPath] - Optional destination folder path. If null, uses app's documents directory
  ///
  /// **Size Management:**
  /// - Dynamically adjusts image compression if estimated size exceeds target
  /// - Target max size: [Constants.mergedPdfTargetSizeMB] MB (configurable)
  /// - Compression factor ranges from [Constants.minCompressionFactor] to [Constants.maxCompressionFactor]
  ///
  /// Supported image formats: jpg, jpeg, png, gif, webp, bmp
  ///
  /// Returns [FileInfo] of the merged PDF on success, or [CustomException] on failure
  static Future<Either<CustomException, FileInfo>> mergePdfs({
    required List<FileInfo> files,
    required String outputFileName,
    String? destinationPath,
  }) async {
    try {
      // Validate input
      if (files.isEmpty) {
        return Left(
          const CustomException(
            message: 'No files provided for merging',
            code: 'NO_FILES',
          ),
        );
      }

      if (files.length < 2) {
        return Left(
          const CustomException(
            message: 'At least 2 files are required for merging',
            code: 'INSUFFICIENT_FILES',
          ),
        );
      }

      // Validate all files exist and are PDFs or images
      for (final fileInfo in files) {
        final file = File(fileInfo.path);
        if (!await file.exists()) {
          return Left(
            CustomException(
              message: 'File not found: ${fileInfo.name}',
              code: 'FILE_NOT_FOUND',
            ),
          );
        }

        final isPdf = fileInfo.extension.toLowerCase() == 'pdf';
        final isImage = PdfCompressService.isImageFile(fileInfo);

        if (!isPdf && !isImage) {
          return Left(
            CustomException(
              message:
                  'Only PDF files and images can be merged: ${fileInfo.name}',
              code: 'INVALID_FILE_TYPE',
            ),
          );
        }
      }

      // Step 1: Analyze sizes and calculate compression factor
      final sizeAnalysis = _analyzeSizes(files);
      final compressionFactor = _calculateCompressionFactor(sizeAnalysis);

      debugPrint(
        '📊 [MergeService] Total input: ${_formatBytes(sizeAnalysis.totalInputSize)}',
      );
      debugPrint(
        '📊 [MergeService] Estimated output: ${_formatBytes(sizeAnalysis.estimatedOutputSize)}',
      );
      debugPrint(
        '📊 [MergeService] Target max: ${Constants.mergedPdfTargetSizeMB}MB',
      );
      debugPrint(
        '📊 [MergeService] Compression factor: ${(compressionFactor * 100).toStringAsFixed(1)}%',
      );

      // Determine destination directory
      final Directory targetDir = await _resolveDestination(destinationPath);

      // Create merged PDF document
      final sf.PdfDocument mergedDocument = sf.PdfDocument();

      // Remove default margins to avoid extra padding around content.
      mergedDocument.pageSettings.margins.all = 0;

      try {
        // Merge each PDF or image
        for (final fileInfo in files) {
          final file = File(fileInfo.path);
          final isPdf = fileInfo.extension.toLowerCase() == 'pdf';
          final isImage = PdfCompressService.isImageFile(fileInfo);

          if (isPdf) {
            // Handle PDF file - merge as-is without compression
            final bytes = await file.readAsBytes();
            final sf.PdfDocument sourceDocument = sf.PdfDocument(
              inputBytes: bytes,
            );

            try {
              // Import all pages from source document WITHOUT forcing orientation
              for (int i = 0; i < sourceDocument.pages.count; i++) {
                _importPdfPageAsIs(sourceDocument, i, mergedDocument);
              }
            } finally {
              sourceDocument.dispose();
            }
          } else if (isImage) {
            // Handle image file with dynamic quality adjustment
            final quality = _calculateImageQuality(compressionFactor);

            // Convert image to PDF with compression
            final Uint8List pdfBytes =
                await PdfCompressService.convertImageToPdf(
                  File(file.path),
                  shouldCompress: true,
                  quality: quality,
                );

            // Load the converted PDF and merge it
            final sf.PdfDocument sourceDocument = sf.PdfDocument(
              inputBytes: pdfBytes,
            );

            try {
              // Import pages from the image-PDF onto PORTRAIT pages, scaled to fit
              for (int i = 0; i < sourceDocument.pages.count; i++) {
                _importImagePagePortraitFit(sourceDocument, i, mergedDocument);
              }
            } finally {
              sourceDocument.dispose();
            }
          }
        }

        // Ensure output filename has .pdf extension
        String finalFileName = outputFileName.trim();
        if (!finalFileName.toLowerCase().endsWith('.pdf')) {
          finalFileName = '$finalFileName.pdf';
        }

        // Create output file path
        final outputPath = p.join(targetDir.path, finalFileName);
        final outputFile = File(outputPath);

        // Save merged document
        final bytes = await mergedDocument.save();
        await outputFile.writeAsBytes(bytes);

        // Get file stats
        final stats = await outputFile.stat();
        final actualSize = stats.size;
        final targetSize = Constants.mergedPdfTargetSizeMB * 1024 * 1024;

        debugPrint(
          '✅ [MergeService] Final PDF size: ${_formatBytes(actualSize)}',
        );
        if (actualSize > targetSize) {
          debugPrint(
            '⚠️ [MergeService] WARNING: Exceeded target size by ${_formatBytes(actualSize - targetSize)}',
          );
        }

        // Create FileInfo for merged PDF
        final mergedFileInfo = FileInfo(
          name: p.basename(outputPath),
          path: outputPath,
          extension: 'pdf',
          size: actualSize,
          lastModified: stats.modified,
          mimeType: 'application/pdf',
          parentDirectory: p.dirname(outputPath),
          isDirectory: false,
        );

        return Right(mergedFileInfo);
      } finally {
        mergedDocument.dispose();
      }
    } catch (e) {
      return Left(
        CustomException(
          message: 'Failed to merge PDFs: ${e.toString()}',
          code: 'MERGE_ERROR',
        ),
      );
    }
  }

  /// Resolves the destination directory for the merged PDF
  static Future<Directory> _resolveDestination(String? destinationPath) async {
    if (destinationPath != null && destinationPath.isNotEmpty) {
      final dir = Directory(destinationPath);
      if (await dir.exists()) {
        return dir;
      }
      // Create if doesn't exist
      await dir.create(recursive: true);
      return dir;
    }

    // Fallback to app's documents directory
    final appDocDir = await getApplicationDocumentsDirectory();
    final mergedDir = Directory(p.join(appDocDir.path, 'MergedPDFs'));
    if (!await mergedDir.exists()) {
      await mergedDir.create(recursive: true);
    }
    return mergedDir;
  }

  /// Analyzes input files and estimates output size
  static _SizeAnalysis _analyzeSizes(List<FileInfo> files) {
    int totalInputSize = 0;
    int pdfTotalSize = 0;
    int imageTotalSize = 0;

    for (final file in files) {
      totalInputSize += file.size;

      if (file.extension.toLowerCase() == 'pdf') {
        pdfTotalSize += file.size;
      } else if (PdfCompressService.isImageFile(file)) {
        imageTotalSize += file.size;
      }
    }

    // Estimate output size based on compression ratios from Constants
    final estimatedPdfSize = (pdfTotalSize * Constants.pdfCompressionRatio)
        .toInt();
    final estimatedImageSize =
        (imageTotalSize * Constants.imageCompressionRatio).toInt();
    final estimatedOutputSize = estimatedPdfSize + estimatedImageSize;

    return _SizeAnalysis(
      totalInputSize: totalInputSize,
      estimatedOutputSize: estimatedOutputSize,
      pdfTotalSize: pdfTotalSize,
      imageTotalSize: imageTotalSize,
    );
  }

  /// Calculates compression factor based on size analysis
  /// Returns a value between [Constants.minCompressionFactor] and [Constants.maxCompressionFactor]
  static double _calculateCompressionFactor(_SizeAnalysis analysis) {
    final targetSize = Constants.mergedPdfTargetSizeMB * 1024 * 1024;

    // If estimated size is within target, no additional compression needed
    if (analysis.estimatedOutputSize <= targetSize) {
      return Constants.maxCompressionFactor; // 1.0 - no extra compression
    }

    // Calculate how much we need to compress
    final compressionFactor =
        (targetSize.toDouble() / analysis.estimatedOutputSize).clamp(
          Constants.minCompressionFactor,
          Constants.maxCompressionFactor,
        );

    return compressionFactor;
  }

  /// Calculates image quality based on compression factor
  /// Maps compression factor (0.3-1.0) to quality (20-95)
  static int _calculateImageQuality(double compressionFactor) {
    final quality = (Constants.baseImageQuality * compressionFactor)
        .toInt()
        .clamp(Constants.minImageQuality, Constants.baseImageQuality);

    debugPrint(
      '🎨 [MergeService] Image quality: $quality (factor: ${(compressionFactor * 100).toStringAsFixed(1)}%)',
    );
    return quality;
  }

  /// Imports a page from a *PDF* source document into the target document
  /// preserving the original page size, without forcing orientation/rotation.
  static void _importPdfPageAsIs(
    sf.PdfDocument sourceDoc,
    int sourcePageIndex,
    sf.PdfDocument targetDoc,
  ) {
    final srcPage = sourceDoc.pages[sourcePageIndex];
    final Size pageSize = srcPage.size;
    final double w = pageSize.width;
    final double h = pageSize.height;

    // Match the source page size and remove margins.
    targetDoc.pageSettings.size = Size(w, h);
    targetDoc.pageSettings.margins.all = 0;

    // Add destination page and draw template 1:1.
    final destPage = targetDoc.pages.add();
    final template = srcPage.createTemplate();

    destPage.graphics.drawPdfTemplate(template, const Offset(0, 0), Size(w, h));
  }

  /// Imports a page from an image-converted PDF into the target document
  /// using a PORTRAIT page and scaling the content so nothing is cropped.
  static void _importImagePagePortraitFit(
    sf.PdfDocument sourceDoc,
    int sourcePageIndex,
    sf.PdfDocument targetDoc,
  ) {
    final srcPage = sourceDoc.pages[sourcePageIndex];
    final Size srcSize = srcPage.size;
    final double srcW = srcSize.width;
    final double srcH = srcSize.height;

    // Force the next page to be portrait A4 with no margins.
    targetDoc.pageSettings.size = sf.PdfPageSize.a4;
    targetDoc.pageSettings.orientation = sf.PdfPageOrientation.portrait;
    targetDoc.pageSettings.margins.all = 0;

    final destPage = targetDoc.pages.add();
    final Size destSize = destPage.getClientSize();
    final double destW = destSize.width;
    final double destH = destSize.height;

    final template = srcPage.createTemplate();

    // Compute uniform scale so the entire source fits inside the portrait page.
    final double scale = [
      destW / srcW,
      destH / srcH,
    ].reduce((a, b) => a < b ? a : b);

    final double drawW = srcW * scale;
    final double drawH = srcH * scale;

    // Center the image content on the page.
    final double dx = (destW - drawW) / 2;
    final double dy = (destH - drawH) / 2;

    destPage.graphics.drawPdfTemplate(
      template,
      Offset(dx, dy),
      Size(drawW, drawH),
    );
  }

  /// Formats bytes to human-readable string
  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    }
    return '${(bytes / 1024 / 1024).toStringAsFixed(2)} MB';
  }
}
