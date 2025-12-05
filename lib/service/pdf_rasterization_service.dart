import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart' as pw;
import 'package:pdf/widgets.dart' as pw_widgets;
import 'package:pdfx/pdfx.dart' as pdfx;
import 'package:flutter_image_compress/flutter_image_compress.dart';

/// Simple failure model for this service.
/// Replace with your own `Failure` hierarchy if you already have one.
class PdfRasterizationFailure {
  final String message;
  final Object? error;
  final StackTrace? stackTrace;

  const PdfRasterizationFailure(this.message, {this.error, this.stackTrace});

  @override
  String toString() =>
      'PdfRasterizationFailure(message: $message, error: $error)';
}

/// Service responsible for:
/// - Rasterizing PDFs to images (via pdfx)
/// - Compressing each raster image
/// - Rebuilding a flattened PDF from those images
class PdfRasterizationService {
  PdfRasterizationService._();

  /// Main pipeline:
  /// - Rasterize all pages at ≈150–200 DPI
  /// - Compress each page image (WebP/JPEG, ~80% quality)
  /// - Rebuild a new flattened PDF and save it
  static Future<Either<PdfRasterizationFailure, File>> rasterizeAndCompressPdf({
    required File inputPdf,
  }) async {
    try {
      debugPrint(
        '🧩 [PdfRasterizationService] Starting pipeline for: ${inputPdf.path}',
      );

      // 1. Rasterize pages.
      final pagesBytes = await _rasterizePdf(inputPdf.path);

      // 2. Compress each page image.
      final processedPages = <Uint8List>[];
      for (final pageBytes in pagesBytes) {
        final compressed = await _compressImage(pageBytes);
        processedPages.add(compressed);
      }

      // 3. Rebuild flattened PDF.
      final pdfBytes = await _rebuildPdf(processedPages);

      // 4. Save output.
      final outputFile = await _saveOutputPdf(inputPdf, pdfBytes);

      debugPrint(
        '✅ [PdfRasterizationService] Pipeline done → ${outputFile.path}',
      );
      return right(outputFile);
    } catch (e, st) {
      return left(
        PdfRasterizationFailure(
          'Failed to rasterize and compress PDF',
          error: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Convenience helper:
  /// Rasterize the whole PDF and return page images (JPEG bytes).
  /// Can be reused by other services (e.g. custom compression, page previews).
  static Future<Either<PdfRasterizationFailure, List<Uint8List>>>
  rasterizePdfToImages({required File inputPdf}) async {
    try {
      final pages = await _rasterizePdf(inputPdf.path);
      return right(pages);
    } catch (e, st) {
      return left(
        PdfRasterizationFailure(
          'Failed to rasterize PDF to images',
          error: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// 1. Load & rasterize PDF using `pdfx`.
  ///
  /// Renders each page around 1240px width (≈150–200 DPI for A4/Letter).
  static Future<List<Uint8List>> _rasterizePdf(String pdfPath) async {
    final doc = await pdfx.PdfDocument.openFile(pdfPath); // [web:1][web:4]
    final List<Uint8List> pages = [];

    try {
      final pageCount = doc.pagesCount;
      debugPrint('📄 [Rasterize] Page count: $pageCount');

      // pdfx pages are 1-based.
      for (int i = 1; i <= pageCount; i++) {
        final page = await doc.getPage(i);

        const targetWidth = 1240;
        final targetHeight = (targetWidth * page.height / page.width).round();

        final pageImage = await page.render(
          width: targetWidth.toDouble(),
          height: targetHeight.toDouble(),
          format: pdfx.PdfPageImageFormat.jpeg,
          backgroundColor: '#FFFFFF',
          quality: 90,
        ); // PdfPageImage?[web:1][web:4]

        if (pageImage != null) {
          pages.add(pageImage.bytes); // Uint8List JPEG bytes.[web:1]
        }

        await page.close();
      }
    } finally {
      await doc.close();
    }

    return pages;
  }

  /// 2. Compress each page image using `flutter_image_compress`.
  ///
  /// - Resize width to ~1400px (within 1200–1500px target).
  /// - Compress to WebP at quality 80 on disk, then read bytes.
  static Future<Uint8List> _compressImage(Uint8List inputBytes) async {
    final decoded = img.decodeImage(inputBytes);
    if (decoded == null) {
      return inputBytes;
    }

    const targetWidth = 1400;
    final resized = img.copyResize(
      decoded,
      width: targetWidth,
      interpolation: img.Interpolation.average,
    );

    final tempDir = await getTemporaryDirectory();
    final tempInput = File(
      p.join(
        tempDir.path,
        'page_input_${DateTime.now().microsecondsSinceEpoch}.png',
      ),
    );
    final tempOutputPath = p.join(
      tempDir.path,
      'page_output_${DateTime.now().microsecondsSinceEpoch}.webp',
    );

    // Write intermediate PNG for the compressor.
    await tempInput.writeAsBytes(img.encodePng(resized));

    final compressed = await FlutterImageCompress.compressAndGetFile(
      tempInput.path,
      tempOutputPath,
      quality: 80,
      format: CompressFormat.webp,
    ); // Returns File?[web:6][web:18]

    // Remove temp input ASAP.
    await tempInput.delete().catchError((_) => tempInput);

    if (compressed == null) {
      // Fallback: JPEG in-memory if plugin fails.
      final fallback = img.encodeJpg(resized, quality: 80);
      return Uint8List.fromList(fallback);
    }

    final outBytes = await compressed.readAsBytes();
    // Delete temp output file.
    await File(
      compressed.path,
    ).delete().catchError((_) => File(compressed.path));
    return outBytes;
  }

  /// 3. Rebuild a new PDF from processed images.
  ///
  /// Each page is a single full-bleed raster image (flattened).
  static Future<Uint8List> _rebuildPdf(List<Uint8List> pages) async {
    final doc = pw_widgets.Document();

    for (final bytes in pages) {
      final mem = pw_widgets.MemoryImage(bytes);

      doc.addPage(
        pw_widgets.Page(
          pageFormat: pw.PdfPageFormat.a4,
          build: (_) => pw_widgets.Image(mem, fit: pw_widgets.BoxFit.cover),
        ),
      );
    }

    return doc.save();
  }

  /// 4. Save output PDF to a writable directory.
  static Future<File> _saveOutputPdf(File inputPdf, Uint8List bytes) async {
    final directory = await getApplicationDocumentsDirectory();
    final name = p.basenameWithoutExtension(inputPdf.path);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final outputPath = p.join(
      directory.path,
      '${name}_rasterized_$timestamp.pdf',
    );

    final outFile = File(outputPath);
    await outFile.writeAsBytes(bytes, flush: true);
    return outFile;
  }
}
