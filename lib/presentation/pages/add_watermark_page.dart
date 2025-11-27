import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf_kit/core/app_export.dart';
import 'package:pdf_kit/models/file_model.dart';
import 'package:pdf_kit/presentation/sheets/watermark_config_sheet.dart';
import 'package:pdf_kit/service/watermark_service.dart';
import 'package:pdf_kit/service/recent_file_service.dart';
import 'package:pdf_kit/service/action_callback_manager.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class AddWatermarkPage extends StatefulWidget {
  final String? selectionId;

  const AddWatermarkPage({super.key, this.selectionId});

  @override
  State<AddWatermarkPage> createState() => _AddWatermarkPageState();
}

class _AddWatermarkPageState extends State<AddWatermarkPage> {
  FileInfo? _selectedPdf;
  final PdfViewerController _pdfController = PdfViewerController();

  // Watermark configuration
  String? _watermarkText;
  String? _watermarkImagePath;
  bool _isGridPattern = false;
  bool _isProcessing = false;
  bool _hasAppliedWatermark = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSelectedFile();
    });
  }

  Future<void> _loadSelectedFile() async {
    if (widget.selectionId == null) {
      debugPrint('❌ [AddWatermarkPage] No selectionId provided');
      return;
    }

    try {
      final mgr = Get.find<SelectionManager>();
      final provider = mgr.of(widget.selectionId!);

      if (provider.files.isEmpty) {
        debugPrint('❌ [AddWatermarkPage] No files selected');
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('No PDF file selected')));
          Navigator.of(context).pop();
        }
        return;
      }

      setState(() {
        _selectedPdf = provider.files.first;
      });

      // Auto-open watermark configuration sheet
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        _openWatermarkConfigSheet();
      }
    } catch (e) {
      debugPrint('❌ [AddWatermarkPage] Error loading file: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading file: $e')));
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _openWatermarkConfigSheet() async {
    final result = await showWatermarkConfigSheet(
      context: context,
      initialText: _watermarkText,
      initialImagePath: _watermarkImagePath,
      initialIsGridPattern: _isGridPattern,
    );

    if (result != null && mounted) {
      // Check if we need to handle image selection
      if (result['needsImageSelection'] == true) {
        // Use callback-based selection (actionId) to avoid duplicate route keys
        final actionId =
            'watermark_image_${DateTime.now().microsecondsSinceEpoch}';
        final actionManager = Get.find<ActionCallbackManager>();

        actionManager.register(actionId, (List<FileInfo> files) async {
          if (!mounted) return;
          if (files.isNotEmpty) {
            setState(() {
              _watermarkImagePath = files.first.path;
              _watermarkText = null; // Clear text when image is selected
            });
          }
          // After selection, re-open config sheet
          if (mounted) {
            await Future.delayed(const Duration(milliseconds: 100));
            _openWatermarkConfigSheet();
          }
        });

        // Navigate to image selection using actionId instead of selectionId
        // final imageResult = await context.pushNamed(
        //   AppRouteName.filesRootFullscreen,
        //   queryParameters: {
        //     'actionId': actionId,
        //     'actionText': 'Select Image for Watermark',
        //     'max': '1',
        //     'min': '1',
        //     'allowed': 'image-only',
        //   },
        // );
      } else {
        setState(() {
          _watermarkText = result['text'] as String?;
          _watermarkImagePath = result['imagePath'] as String?;
          _isGridPattern = result['isGridPattern'] as bool? ?? false;
        });
      }
    }
  }

  Future<void> _applyWatermark() async {
    if (_selectedPdf == null) return;
    if (_watermarkText == null && _watermarkImagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please configure watermark first')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final result = await WatermarkService.addWatermark(
        pdfPath: _selectedPdf!.path,
        text: _watermarkText,
        imagePath: _watermarkImagePath,
        isGridPattern: _isGridPattern,
      );

      if (!mounted) return;

      result.fold(
        (error) {
          debugPrint('❌ [AddWatermarkPage] Watermark failed: $error');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to add watermark: $error'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
          setState(() {
            _isProcessing = false;
          });
        },
        (outputPath) async {
          debugPrint('✅ [AddWatermarkPage] Watermark applied: $outputPath');

          // Add to recent files
          final file = File(outputPath);
          final stat = await file.stat();
          final newFileInfo = FileInfo(
            name: file.uri.pathSegments.last,
            path: outputPath,
            size: stat.size,
            lastModified: stat.modified,
            extension: 'pdf',
            isDirectory: false,
          );

          await RecentFilesService.addRecentFile(newFileInfo);

          setState(() {
            _isProcessing = false;
            _hasAppliedWatermark = true;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Watermark applied successfully!')),
            );

            // Return true to trigger home refresh
            Navigator.of(context).pop(true);
          }
        },
      );
    } catch (e) {
      debugPrint('❌ [AddWatermarkPage] Exception: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(t.t('watermark_pdf_title'))),
      body: _selectedPdf == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: AnimatedBuilder(
                    animation: _pdfController,
                    builder: (context, child) {
                      final currentPage = _pdfController.pageNumber;
                      final totalPages = _pdfController.pageCount;
                      final canGoPrevious = currentPage > 1;
                      final canGoNext =
                          totalPages > 0 && currentPage < totalPages;

                      return Stack(
                        children: [
                          SfPdfViewer.file(
                            File(_selectedPdf!.path),
                            controller: _pdfController,
                            canShowScrollHead: true,
                            canShowScrollStatus: true,
                            scrollDirection: PdfScrollDirection.horizontal,
                            pageLayoutMode: PdfPageLayoutMode.single,
                          ),
                          // Watermark preview overlay
                          if (_watermarkText != null ||
                              _watermarkImagePath != null)
                            Positioned.fill(
                              child: IgnorePointer(
                                child: CustomPaint(
                                  painter: WatermarkPreviewPainter(
                                    text: _watermarkText,
                                    imagePath: _watermarkImagePath,
                                    isGridPattern: _isGridPattern,
                                  ),
                                ),
                              ),
                            ),
                          // Previous arrow (only show if can go previous)
                          if (canGoPrevious)
                            Positioned(
                              left: 16,
                              top: 0,
                              bottom: 0,
                              child: Center(
                                child: IconButton(
                                  icon: const Icon(Icons.arrow_back_ios),
                                  iconSize: 32,
                                  color: Colors.white,
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.black.withOpacity(
                                      0.5,
                                    ),
                                  ),
                                  onPressed: () {
                                    _pdfController.previousPage();
                                  },
                                ),
                              ),
                            ),
                          // Next arrow (only show if can go next)
                          if (canGoNext)
                            Positioned(
                              right: 16,
                              top: 0,
                              bottom: 0,
                              child: Center(
                                child: IconButton(
                                  icon: const Icon(Icons.arrow_forward_ios),
                                  iconSize: 32,
                                  color: Colors.white,
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.black.withOpacity(
                                      0.5,
                                    ),
                                  ),
                                  onPressed: () {
                                    _pdfController.nextPage();
                                  },
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        decoration: BoxDecoration(
          color: Colors.transparent,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              offset: const Offset(0, -2),
              blurRadius: 8,
            ),
          ],
        ),
        child: SafeArea(
          bottom: true,
          minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Row(
            children: [
              // Configure button - takes half space
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: _hasAppliedWatermark
                        ? null
                        : _openWatermarkConfigSheet,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF5B7FFF)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    icon: Icon(
                      _watermarkText != null
                          ? Icons.text_fields
                          : _watermarkImagePath != null
                          ? Icons.image
                          : Icons.settings,
                      color: const Color(0xFF5B7FFF),
                    ),
                    label: Text(
                      _watermarkText != null
                          ? 'Configure'
                          : _watermarkImagePath != null
                          ? 'Configure'
                          : 'Configure',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF5B7FFF),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Apply button - takes half space
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: FilledButton.icon(
                    onPressed: (_isProcessing || _hasAppliedWatermark)
                        ? null
                        : _applyWatermark,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF5B7FFF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    icon: _isProcessing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Icon(Icons.check, color: Colors.white),
                    label: const Text(
                      'Apply',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom painter for watermark preview overlay
class WatermarkPreviewPainter extends CustomPainter {
  final String? text;
  final String? imagePath;
  final bool isGridPattern;

  WatermarkPreviewPainter({
    this.text,
    this.imagePath,
    required this.isGridPattern,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (text == null && imagePath == null) return;

    if (isGridPattern) {
      _paintGridPattern(canvas, size);
    } else {
      _paintSingleWatermark(canvas, size);
    }
  }

  void _paintGridPattern(Canvas canvas, Size size) {
    const spacing = 200.0; // Space between watermarks
    final positions = <Offset>[];

    // Generate grid positions
    for (double x = spacing / 2; x < size.width; x += spacing) {
      for (double y = spacing / 2; y < size.height; y += spacing) {
        positions.add(Offset(x, y));
      }
    }

    // Draw watermark at each position
    for (final position in positions) {
      _drawWatermark(canvas, position, size);
    }
  }

  void _paintSingleWatermark(Canvas canvas, Size size) {
    // Center position
    final position = Offset(size.width / 2, size.height / 2);
    _drawWatermark(canvas, position, size);
  }

  void _drawWatermark(Canvas canvas, Offset position, Size size) {
    if (text != null) {
      _drawTextWatermark(canvas, position);
    }
    // Image watermark preview would require async loading
    // For now, show placeholder text for image watermarks
    if (imagePath != null && text == null) {
      _drawImagePlaceholder(canvas, position);
    }
  }

  void _drawTextWatermark(Canvas canvas, Offset position) {
    final textSpan = TextSpan(
      text: text,
      style: const TextStyle(
        color: Color(0x33000000), // Semi-transparent black
        fontSize: 48,
        fontWeight: FontWeight.bold,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    // Save canvas state
    canvas.save();

    // Translate to position
    canvas.translate(position.dx, position.dy);

    // Rotate by 45 degrees (diagonal)
    canvas.rotate(-0.785398); // -45 degrees in radians

    // Draw text centered at position
    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, -textPainter.height / 2),
    );

    // Restore canvas state
    canvas.restore();
  }

  void _drawImagePlaceholder(Canvas canvas, Offset position) {
    final textSpan = TextSpan(
      text: '🖼️ Image',
      style: const TextStyle(
        color: Color(0x33000000), // Semi-transparent black
        fontSize: 48,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    // Save canvas state
    canvas.save();

    // Translate to position
    canvas.translate(position.dx, position.dy);

    // Rotate by 45 degrees (diagonal)
    canvas.rotate(-0.785398); // -45 degrees in radians

    // Draw text centered at position
    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, -textPainter.height / 2),
    );

    // Restore canvas state
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant WatermarkPreviewPainter oldDelegate) {
    return oldDelegate.text != text ||
        oldDelegate.imagePath != imagePath ||
        oldDelegate.isGridPattern != isGridPattern;
  }
}
