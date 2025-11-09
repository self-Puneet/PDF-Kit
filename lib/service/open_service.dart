// open_service.dart
import 'package:dartz/dartz.dart';
import 'package:open_filex/open_filex.dart';
import 'package:pdf_kit/service/fiel_access_guard.dart';
import 'dart:io';
import 'package:mime/mime.dart';

class OpenService {
  static bool _isImageOrPdf(String path) {
    final mime = lookupMimeType(path);
    if (mime == null) {
      final ext = path.split('.').last.toLowerCase();
      return const {
        'pdf',
        'jpg',
        'jpeg',
        'png',
        'gif',
        'webp',
        'bmp',
        'tif',
        'tiff',
        'heic',
        'heif',
        'svg',
      }.contains(ext);
    }
    return mime.startsWith('image/') || mime == 'application/pdf';
  }

  static Future<Either<Exception, bool>> open(String path) async {
    try {
      if (!_isImageOrPdf(path)) {
        return Left(Exception('Unsupported type (only images/PDF allowed)'));
      }
      final file = File(path);
      if (!await FileAccessGuard.canReadFile(file)) {
        return Left(Exception('Restricted or unreadable file'));
      }
      final res = await OpenFilex.open(path);
      return Right(res.type == ResultType.done);
    } catch (e) {
      return Left(Exception('Open failed: $e'));
    }
  }
}
