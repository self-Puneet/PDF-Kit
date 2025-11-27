import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' show Size, Rect; // <-- needed for Size and Rect

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:pdf_kit/service/path_service.dart';
import 'package:path/path.dart' as p;

/// Service for adding watermarks (text or image) to PDF files using Syncfusion
class WatermarkService {
  WatermarkService._();

  /// Add watermark to a PDF file
  ///
  /// Either [text] or [imagePath] must be provided (not both).
  /// Returns the path to the newly created watermarked PDF file.
  static Future<Either<String, String>> addWatermark({
    required String pdfPath,
    String? text,
    String? imagePath,
    bool isGridPattern = false,
    double opacity = 0.3,
    double fontSize = 48.0,
  }) async {
    debugPrint('🎨 [WatermarkService] Starting watermark process');
    debugPrint('   📄 PDF: $pdfPath');
    debugPrint('   📝 Text: $text');
    debugPrint('   🖼️ Image: $imagePath');

    try {
      // Validate inputs
      if (text == null && imagePath == null) {
        return const Left('Either text or image must be provided');
      }

      if (text != null && imagePath != null) {
        return const Left(
          'Cannot apply both text and image watermark simultaneously',
        );
      }

      // Normalize opacity to [0, 1] for setTransparency
      final double alpha = opacity < 0 ? 0 : (opacity > 1 ? 1 : opacity);

      // Load the PDF document
      final File pdfFile = File(pdfPath);
      if (!await pdfFile.exists()) {
        return const Left('PDF file not found');
      }

      final Uint8List pdfBytes = await pdfFile.readAsBytes();
      final PdfDocument document = PdfDocument(inputBytes: pdfBytes);

      debugPrint('   📖 Loaded PDF with ${document.pages.count} pages');

      // Apply watermark to each page
      for (int i = 0; i < document.pages.count; i++) {
        final PdfPage page = document.pages[i];
        final PdfGraphics graphics = page.graphics;

        if (text != null) {
          _applyTextWatermark(
            graphics: graphics,
            page: page,
            text: text,
            opacity: alpha,
            fontSize: fontSize,
            isGridPattern: isGridPattern,
          );
        } else if (imagePath != null) {
          await _applyImageWatermark(
            graphics: graphics,
            page: page,
            imagePath: imagePath,
            opacity: alpha,
            isGridPattern: isGridPattern,
          );
        }
      }

      // Save the watermarked PDF
      final outputPath = await _generateOutputPath(pdfPath);
      final List<int> bytes = await document.save();
      document.dispose();

      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(bytes);

      debugPrint('✅ [WatermarkService] Watermark applied successfully');
      debugPrint('   💾 Output: $outputPath');

      return Right(outputPath);
    } catch (e, stackTrace) {
      debugPrint('❌ [WatermarkService] Error: $e');
      debugPrint('   Stack trace: $stackTrace');
      return Left('Failed to add watermark: ${e.toString()}');
    }
  }

  /// Apply text watermark to a page
  static void _applyTextWatermark({
    required PdfGraphics graphics,
    required PdfPage page,
    required String text,
    required double opacity,
    required double fontSize,
    required bool isGridPattern,
  }) {
    debugPrint('   🔤 Applying text watermark: "$text" (grid: $isGridPattern)');

    // Create font
    final PdfFont font = PdfStandardFont(
      PdfFontFamily.helvetica,
      fontSize,
      style: PdfFontStyle.bold,
    );

    // Measure text size (returns dart:ui Size)
    final Size textSize = font.measureString(text);

    final double pageWidth = page.size.width;
    final double pageHeight = page.size.height;

    // Save graphics state
    final PdfGraphicsState state = graphics.save();

    // Set transparency
    graphics.setTransparency(opacity);

    if (isGridPattern) {
      // Draw watermark in a grid pattern
      final double spacingX = textSize.width * 1.5;
      final double spacingY = textSize.height * 3;

      // Rotate for diagonal effect
      graphics.translateTransform(pageWidth / 2, pageHeight / 2);
      graphics.rotateTransform(-45);
      graphics.translateTransform(-pageWidth / 2, -pageHeight / 2);

      // Calculate grid bounds
      final startX = -textSize.width;
      final startY = -textSize.height;
      final endX = pageWidth + textSize.width;
      final endY = pageHeight + textSize.height;

      for (double y = startY; y < endY; y += spacingY) {
        for (double x = startX; x < endX; x += spacingX) {
          graphics.drawString(
            text,
            font,
            brush: PdfSolidBrush(PdfColor(128, 128, 128)),
            bounds: Rect.fromLTWH(x, y, textSize.width, textSize.height),
          );
        }
      }
    } else {
      // Draw single centered watermark
      final double x = (pageWidth - textSize.width) / 2;
      final double y = (pageHeight - textSize.height) / 2;

      // Rotate and draw text diagonally around page center
      graphics.translateTransform(pageWidth / 2, pageHeight / 2);
      graphics.rotateTransform(-45);
      graphics.translateTransform(-pageWidth / 2, -pageHeight / 2);

      graphics.drawString(
        text,
        font,
        brush: PdfSolidBrush(PdfColor(128, 128, 128)),
        bounds: Rect.fromLTWH(x, y, textSize.width, textSize.height),
      );
    }

    // Restore graphics state
    graphics.restore(state);
  }

  /// Apply image watermark to a page
  static Future<void> _applyImageWatermark({
    required PdfGraphics graphics,
    required PdfPage page,
    required String imagePath,
    required double opacity,
    required bool isGridPattern,
  }) async {
    debugPrint(
      '   🖼️ Applying image watermark: $imagePath (grid: $isGridPattern)',
    );

    final File imageFile = File(imagePath);
    if (!await imageFile.exists()) {
      debugPrint('   ⚠️ Image file not found, skipping');
      return;
    }

    try {
      // Load image
      final Uint8List imageBytes = await imageFile.readAsBytes();
      final PdfBitmap image = PdfBitmap(imageBytes);

      final double pageWidth = page.size.width;
      final double pageHeight = page.size.height;

      // Scale image to fit page while maintaining aspect ratio
      final double maxWidth = pageWidth * (isGridPattern ? 0.2 : 0.4);
      final double maxHeight = pageHeight * (isGridPattern ? 0.2 : 0.4);

      double imageWidth = image.width.toDouble();
      double imageHeight = image.height.toDouble();

      final double widthRatio = maxWidth / imageWidth;
      final double heightRatio = maxHeight / imageHeight;
      final double ratio = widthRatio < heightRatio ? widthRatio : heightRatio;

      imageWidth *= ratio;
      imageHeight *= ratio;

      // Save graphics state
      final PdfGraphicsState state = graphics.save();

      // Set transparency
      graphics.setTransparency(opacity);

      if (isGridPattern) {
        // Draw watermark in a grid pattern
        final double spacingX = imageWidth * 1.8;
        final double spacingY = imageHeight * 3;

        // Rotate for diagonal effect
        graphics.translateTransform(pageWidth / 2, pageHeight / 2);
        graphics.rotateTransform(-45);
        graphics.translateTransform(-pageWidth / 2, -pageHeight / 2);

        // Calculate grid bounds
        final startX = -imageWidth;
        final startY = -imageHeight;
        final endX = pageWidth + imageWidth;
        final endY = pageHeight + imageHeight;

        for (double y = startY; y < endY; y += spacingY) {
          for (double x = startX; x < endX; x += spacingX) {
            graphics.drawImage(
              image,
              Rect.fromLTWH(x, y, imageWidth, imageHeight),
            );
          }
        }
      } else {
        // Draw single centered watermark
        final double x = (pageWidth - imageWidth) / 2;
        final double y = (pageHeight - imageHeight) / 2;

        // Rotate for diagonal watermark
        graphics.translateTransform(pageWidth / 2, pageHeight / 2);
        graphics.rotateTransform(-45);
        graphics.translateTransform(-pageWidth / 2, -pageHeight / 2);

        graphics.drawImage(image, Rect.fromLTWH(x, y, imageWidth, imageHeight));
      }

      // Restore graphics state
      graphics.restore(state);
    } catch (e) {
      debugPrint('   ⚠️ Error loading image: $e');
    }
  }

  /// Generate output path for the watermarked PDF
  static Future<String> _generateOutputPath(String originalPath) async {
    final result = await PathService.downloads();

    return result.fold(
      (error) {
        // Fallback: save in same directory as original
        final dir = p.dirname(originalPath);
        final name = p.basenameWithoutExtension(originalPath);
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        return p.join(dir, '${name}_watermark_$timestamp.pdf');
      },
      (downloadsDir) {
        final name = p.basenameWithoutExtension(originalPath);
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        return p.join(downloadsDir.path, '${name}_watermark_$timestamp.pdf');
      },
    );
  }
}
