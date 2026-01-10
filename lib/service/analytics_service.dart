import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  AnalyticsService._();

  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  static Map<String, Object> _sanitizeParams(Map<String, Object> parameters) {
    final sanitized = <String, Object>{};
    parameters.forEach((key, value) {
      // GA4 custom event params should be scalar values.
      if (value is String || value is num) {
        sanitized[key] = value;
        return;
      }
      if (value is bool) {
        sanitized[key] = value ? 1 : 0;
        return;
      }
      // Fallback: stringify lists/maps/other objects to avoid runtime errors.
      sanitized[key] = value.toString();
    });
    return sanitized;
  }

  static Future<void> _logEvent(
    String name,
    Map<String, Object> parameters,
  ) async {
    try {
      final sanitized = _sanitizeParams(parameters);
      debugPrint('📊 [Analytics] Logging $name: $sanitized');
      await _analytics.logEvent(name: name, parameters: sanitized);
    } catch (e) {
      debugPrint('⚠️ [Analytics] Failed to log event $name: $e');
    }
  }

  /// Log Merge PDF event
  /// pdf_page_number_list: List of page counts for each input file (0 for images)
  /// time_taken_for_merge: Duration in seconds
  static Future<void> logMergePdf({
    required List<int> pdfPageNumberList,
    required double timeTaken,
  }) async {
    await _logEvent('merge_pdf', {
      'pdf_page_number_list_str': pdfPageNumberList.toString(),
      'input_file_count': pdfPageNumberList.length,
      'time_taken_for_merge': timeTaken,
    });
  }

  /// Log Images to PDF event
  static Future<void> logImagesToPdf({
    required int numberOfImages,
    required double timeTaken,
  }) async {
    await _logEvent('images_to_pdf', {
      'number_of_images': numberOfImages,
      'time_taken_for_conversion': timeTaken,
    });
  }

  /// Log Split PDF event
  static Future<void> logSplitPdf({
    required List<int> outputPdfPageNumberList,
    required double timeTaken,
  }) async {
    await _logEvent('split_pdf', {
      'output_pdf_page_number_list_str': outputPdfPageNumberList.toString(),
      'time_taken_for_split': timeTaken,
    });
  }

  /// Log Protect PDF event
  static Future<void> logProtectPdf({
    required int totalPageNumber,
    required double timeTaken,
  }) async {
    await _logEvent('protect_pdf', {
      'total_page_number': totalPageNumber,
      'time_taken_for_protection': timeTaken,
    });
  }

  /// Log Unlock PDF event
  static Future<void> logUnlockPdf({
    required int totalPageNumber,
    required double timeTaken,
  }) async {
    await _logEvent('unlock_pdf', {
      'total_page_number': totalPageNumber,
      'time_taken_for_unlock': timeTaken,
    });
  }

  /// Log Compress PDF event
  static Future<void> logCompressPdf({
    required int totalPageNumber,
    required double timeTaken,
  }) async {
    await _logEvent('compress_pdf', {
      'total_page_number': totalPageNumber,
      'time_taken_for_compression': timeTaken,
    });
  }

  /// Log PDF to Image event
  static Future<void> logPdfToImage({
    required int totalImage,
    required double timeTaken,
  }) async {
    await _logEvent('pdf_to_image', {
      'total_image':
          totalImage, // "total_inage" in user request typo, corrected to total_image
      'time_taken_for_conversion': timeTaken,
    });
  }

  /// Log Reorder PDF event
  static Future<void> logReorderPdf({
    required int totalPagesRotated,
    required int totalPages,
    required int totalPagesRemoved,
    required int totalPagesSwapped,
    required double timeTaken,
  }) async {
    await _logEvent('reorder_pdf', {
      'total_number_of_pages_rotated': totalPagesRotated,
      'total_number_of_pages': totalPages,
      'total_number_of_pages_removed': totalPagesRemoved,
      'total_number_of_pages_swapped': totalPagesSwapped,
      'time_taken_for_reordering': timeTaken,
    });
  }
}
