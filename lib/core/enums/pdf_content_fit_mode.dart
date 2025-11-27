/// Enum representing how image content should fit in PDF pages
enum PdfContentFitMode {
  /// Keep original image size without any modifications
  original('original'),

  /// Scale image to fit page with padding, maintaining aspect ratio
  fit('fit'),

  /// Scale image to fill entire page, cropping if necessary
  crop('crop');

  const PdfContentFitMode(this.value);

  /// String value for storage
  final String value;

  /// Get enum from string value
  static PdfContentFitMode fromString(String value) {
    switch (value) {
      case 'original':
        return PdfContentFitMode.original;
      case 'fit':
        return PdfContentFitMode.fit;
      case 'crop':
        return PdfContentFitMode.crop;
      default:
        return PdfContentFitMode.original;
    }
  }

  /// Get display name for the mode
  String get displayName {
    switch (this) {
      case PdfContentFitMode.original:
        return 'Original Size';
      case PdfContentFitMode.fit:
        return 'Fit with Padding';
      case PdfContentFitMode.crop:
        return 'Crop to Fit';
    }
  }
}
