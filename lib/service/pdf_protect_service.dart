import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:ares_defence_labs_lock_smith_pdf/ares_defence_labs_lock_smith_pdf.dart';
import 'package:pdf_kit/core/exception/failures.dart';

class PdfProtectionService {
  PdfProtectionService._();

  /// Protects a PDF file with a password using Syncfusion Flutter PDF
  static Future<Either<Failure, String>> protectPdf({
    required String pdfPath,
    required String password,
  }) async {
    try {
      // Validate password
      if (password.isEmpty) {
        return const Left(InvalidPasswordFailure());
      }

      // Check if file exists
      final File pdfFile = File(pdfPath);
      if (!await pdfFile.exists()) {
        return const Left(FileNotFoundFailure());
      }
      // Use ares_defence_labs_lock_smith_pdf to protect the PDF.
      final String outputPath = _outputPathFor(pdfPath, '_protected');

      await AresDefenceLabsLocksmithPdf.protectPdf(
        inputPath: pdfPath,
        outputPath: outputPath,
        password: password,
      );

      // Replace original with protected output
      final File outFile = File(outputPath);
      if (!await outFile.exists()) {
        return const Left(
          PdfProtectionFailure('Failed to create protected PDF'),
        );
      }

      final List<int> bytes = await outFile.readAsBytes();
      await pdfFile.writeAsBytes(bytes);

      // Clean up temporary file
      try {
        await outFile.delete();
      } catch (_) {}

      return Right(pdfPath);
    } on FileSystemException catch (e) {
      return Left(FileReadWriteFailure('File error: ${e.message}'));
    } catch (e) {
      print('Error protecting PDF: $e');
      return Left(
        PdfProtectionFailure('Failed to protect PDF: ${e.toString()}'),
      );
    }
  }

  /// Checks if a PDF is password protected
  static Future<Either<Failure, bool>> isPdfProtected({
    required String pdfPath,
  }) async {
    try {
      final File pdfFile = File(pdfPath);
      if (!await pdfFile.exists()) {
        return const Left(FileNotFoundFailure());
      }
      // Use plugin API to check encryption status
      final bool isEncrypted = await AresDefenceLabsLocksmithPdf.isPdfEncrypted(
        inputPath: pdfPath,
      );

      return Right(isEncrypted);
    } catch (e) {
      return Left(PdfProtectionFailure('Failed to check PDF: ${e.toString()}'));
    }
  }

  /// Unlocks a password-protected PDF file using Syncfusion Flutter PDF
  static Future<Either<Failure, String>> unlockPdf({
    required String pdfPath,
    required String password,
  }) async {
    try {
      // Validate password
      if (password.isEmpty) {
        return const Left(InvalidPasswordFailure());
      }

      // Check if file exists
      final File pdfFile = File(pdfPath);
      if (!await pdfFile.exists()) {
        return const Left(FileNotFoundFailure());
      }

      // Try to load the PDF with password
      try {
        final String outputPath = _outputPathFor(pdfPath, '_unlocked');

        await AresDefenceLabsLocksmithPdf.decryptPdf(
          inputPath: pdfPath,
          outputPath: outputPath,
          password: password,
        );

        final File outFile = File(outputPath);
        if (!await outFile.exists()) {
          return const Left(
            PdfProtectionFailure('Failed to create unlocked PDF'),
          );
        }

        final List<int> bytes = await outFile.readAsBytes();
        await pdfFile.writeAsBytes(bytes);

        try {
          await outFile.delete();
        } catch (_) {}

        return Right(pdfPath);
      } catch (e) {
        // Handle incorrect password or loading errors
        if (e.toString().toLowerCase().contains('password') ||
            e.toString().toLowerCase().contains('invalid') ||
            e.toString().toLowerCase().contains('encrypted')) {
          return const Left(
            PdfProtectionFailure('Incorrect password. Please try again.'),
          );
        }
        rethrow;
      }
    } on FileSystemException catch (e) {
      return Left(FileReadWriteFailure('File error: ${e.message}'));
    } catch (e) {
      return Left(
        PdfProtectionFailure('Failed to unlock PDF: ${e.toString()}'),
      );
    }
  }

  static String _outputPathFor(String inputPath, String suffix) {
    final lower = inputPath.toLowerCase();
    if (lower.endsWith('.pdf')) {
      return inputPath.substring(0, inputPath.length - 4) + suffix + '.pdf';
    }
    return inputPath + suffix + '.pdf';
  }
}
