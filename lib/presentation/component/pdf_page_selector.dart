// lib/presentation/component/pdf_page_selector.dart

import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart' as pdfx;
import 'dart:io';
import 'dart:typed_data';

class PdfPageSelector extends StatefulWidget {
  final File pdfFile;
  final Set<int> initialSelectedPages;
  final Function(Set<int> selectedPages, bool hasRotationChanges)
  onSelectionChanged;

  const PdfPageSelector({
    super.key,
    required this.pdfFile,
    required this.initialSelectedPages,
    required this.onSelectionChanged,
  });

  @override
  State<PdfPageSelector> createState() => _PdfPageSelectorState();
}

class _PdfPageSelectorState extends State<PdfPageSelector> {
  late final TextEditingController _selectCtrl;
  late Set<int> _selectedPages;
  List<int> _pageOrder = []; // For reordering
  String? _selectError;
  bool _isLoading = true;
  int _totalPages = 0;
  final Map<int, Uint8List?> _pageCache = {};
  final Map<int, double> _rotations = {}; // Store rotation angles for pages
  bool _hasRotationChanges = false;

  @override
  void initState() {
    super.initState();
    _selectCtrl = TextEditingController();
    _selectedPages = Set.from(widget.initialSelectedPages);
    _loadPdf();
  }

  @override
  void dispose() {
    _selectCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPdf() async {
    setState(() => _isLoading = true);
    try {
      final doc = await pdfx.PdfDocument.openFile(widget.pdfFile.path);
      _totalPages = doc.pagesCount;
      _pageOrder = List.generate(_totalPages, (i) => i + 1);

      // If no pages were initially selected, select all by default
      if (_selectedPages.isEmpty) {
        _selectedPages = Set.from(_pageOrder);
      }

      await doc.close();
      setState(() => _isLoading = false);

      // Notify parent of initial state
      widget.onSelectionChanged(_selectedPages, _hasRotationChanges);

      // Start loading page thumbnails
      _loadPageThumbnails();
    } catch (e) {
      debugPrint('Error loading PDF: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadPageThumbnails() async {
    try {
      final doc = await pdfx.PdfDocument.openFile(widget.pdfFile.path);

      for (int pageNum in _pageOrder) {
        if (!mounted) break;
        if (_pageCache.containsKey(pageNum)) continue;

        try {
          final page = await doc.getPage(pageNum);
          final pageImage = await page.render(
            width: 300,
            height: 300 * page.height / page.width,
            format: pdfx.PdfPageImageFormat.jpeg,
            backgroundColor: '#FFFFFF',
            quality: 70,
          );

          if (mounted && pageImage != null) {
            setState(() {
              _pageCache[pageNum] = pageImage.bytes;
            });
          }

          await page.close();
        } catch (e) {
          debugPrint('Error loading page $pageNum: $e');
        }
      }

      await doc.close();
    } catch (e) {
      debugPrint('Error loading thumbnails: $e');
    }
  }

  void _notifyParent() {
    widget.onSelectionChanged(_selectedPages, _hasRotationChanges);
  }

  void _parseSelectionRange(String input) {
    if (input.trim().isEmpty) {
      setState(() {
        _selectError = 'At least one page must be selected';
      });
      return;
    }

    try {
      final ranges = input.split(',');
      final Set<int> selected = {};

      for (var range in ranges) {
        range = range.trim();
        if (range.isEmpty) continue;

        if (range.contains('-')) {
          final parts = range.split('-');
          if (parts.length != 2) {
            throw 'Invalid range format. Use format like 1-5';
          }

          final start = int.tryParse(parts[0].trim());
          final end = int.tryParse(parts[1].trim());

          if (start == null || end == null) {
            throw 'Please enter valid page numbers';
          }

          if (start < 1 || end > _totalPages) {
            throw 'Pages must be between 1 and $_totalPages';
          }

          if (start > end) {
            throw 'Start page must be less than or equal to end page';
          }

          for (int i = start; i <= end; i++) {
            selected.add(i);
          }
        } else {
          final page = int.tryParse(range);
          if (page == null) {
            throw 'Please enter valid page numbers';
          }

          if (page < 1 || page > _totalPages) {
            throw 'Page must be between 1 and $_totalPages';
          }
          selected.add(page);
        }
      }

      if (selected.isEmpty) {
        throw 'At least one page must be selected';
      }

      setState(() {
        _selectedPages = selected;
        _selectError = null;
      });
      _notifyParent();
    } catch (e) {
      setState(() {
        _selectError = e.toString();
      });
    }
  }

  void _updateTextFieldFromSelection() {
    if (_selectedPages.isEmpty) {
      _selectCtrl.text = '';
      return;
    }

    // Sort the selected pages
    final sortedPages = _selectedPages.toList()..sort();

    // Group consecutive pages into ranges
    final List<String> ranges = [];
    int? rangeStart;
    int? rangeEnd;

    for (int i = 0; i < sortedPages.length; i++) {
      final currentPage = sortedPages[i];

      if (rangeStart == null) {
        rangeStart = currentPage;
        rangeEnd = currentPage;
      } else if (currentPage == rangeEnd! + 1) {
        rangeEnd = currentPage;
      } else {
        // End of consecutive sequence
        if (rangeStart == rangeEnd) {
          ranges.add('$rangeStart');
        } else {
          ranges.add('$rangeStart-$rangeEnd');
        }
        rangeStart = currentPage;
        rangeEnd = currentPage;
      }
    }

    // Add the last range
    if (rangeStart != null) {
      if (rangeStart == rangeEnd) {
        ranges.add('$rangeStart');
      } else {
        ranges.add('$rangeStart-$rangeEnd');
      }
    }

    _selectCtrl.text = ranges.join(', ');
  }

  void _togglePage(int pageNum) {
    setState(() {
      if (_selectedPages.contains(pageNum)) {
        // Don't allow deselecting if it's the last selected page
        if (_selectedPages.length > 1) {
          _selectedPages.remove(pageNum);
        }
      } else {
        _selectedPages.add(pageNum);
      }
      _updateTextFieldFromSelection();
    });
    _notifyParent();
  }

  void _rotatePage(int pageNum) {
    setState(() {
      final currentRotation = _rotations[pageNum] ?? 0.0;
      _rotations[pageNum] = (currentRotation + 90) % 360;
      _hasRotationChanges = true;
    });
    _notifyParent();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Select pages text field
        TextField(
          controller: _selectCtrl,
          decoration: InputDecoration(
            hintText: 'e.g., 1-5, 8, 10-15',
            labelText: 'Select Pages',
            helperText: 'Enter page ranges to select, separated by commas',
            helperMaxLines: 2,
            errorText: _selectError,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.check_box_outlined),
            suffixIcon: _selectError != null
                ? Tooltip(
                    message: _selectError!,
                    child: Icon(
                      Icons.error_outline,
                      color: theme.colorScheme.error,
                    ),
                  )
                : (_selectCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _selectCtrl.clear();
                            setState(() => _selectError = null);
                            _notifyParent();
                          },
                        )
                      : null),
          ),
          onChanged: _parseSelectionRange,
        ),
        const SizedBox(height: 16),

        // Selected count info and actions
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                '${_selectedPages.length} of $_totalPages page${_selectedPages.length != 1 ? 's' : ''} selected',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Pages grid (2 columns)
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.65,
            ),
            itemCount: _pageOrder.length,
            itemBuilder: (context, index) {
              final pageNum = _pageOrder[index];
              final isSelected = _selectedPages.contains(pageNum);
              final rotation = _rotations[pageNum] ?? 0.0;

              return _PageThumbnail(
                pageNum: pageNum,
                isSelected: isSelected,
                thumbnailBytes: _pageCache[pageNum],
                rotation: rotation,
                onToggle: () => _togglePage(pageNum),
                onRotate: () => _rotatePage(pageNum),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PageThumbnail extends StatelessWidget {
  final int pageNum;
  final bool isSelected;
  final Uint8List? thumbnailBytes;
  final double rotation;
  final VoidCallback onToggle;
  final VoidCallback onRotate;

  const _PageThumbnail({
    required this.pageNum,
    required this.isSelected,
    required this.thumbnailBytes,
    required this.rotation,
    required this.onToggle,
    required this.onRotate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onToggle,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? theme.colorScheme.primaryContainer.withOpacity(0.2)
              : theme.colorScheme.surface,
        ),
        child: Column(
          children: [
            // Header with page number and buttons
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(11),
                  topRight: Radius.circular(11),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Page $pageNum',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? theme.colorScheme.onPrimaryContainer
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onRotate,
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Icon(
                              Icons.rotate_right,
                              size: 18,
                              color: isSelected
                                  ? theme.colorScheme.onPrimaryContainer
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 2),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onToggle,
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Icon(
                              isSelected
                                  ? Icons.check_circle
                                  : Icons.circle_outlined,
                              size: 18,
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Thumbnail
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: thumbnailBytes != null
                    ? LayoutBuilder(
                        builder: (context, constraints) {
                          return Center(
                            child: Transform.rotate(
                              angle: rotation * 3.14159 / 180,
                              child: Image.memory(
                                thumbnailBytes!,
                                fit: BoxFit.contain,
                              ),
                            ),
                          );
                        },
                      )
                    : Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.primary,
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
