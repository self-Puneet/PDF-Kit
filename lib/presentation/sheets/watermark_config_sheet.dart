import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf_kit/core/app_export.dart';

Future<Map<String, dynamic>?> showWatermarkConfigSheet({
  required BuildContext context,
  String? initialText,
  String? initialImagePath,
  bool? initialIsGridPattern,
}) async {
  return await showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => WatermarkConfigSheet(
      initialText: initialText,
      initialImagePath: initialImagePath,
      initialIsGridPattern: initialIsGridPattern,
    ),
  );
}

class WatermarkConfigSheet extends StatefulWidget {
  final String? initialText;
  final String? initialImagePath;
  final bool? initialIsGridPattern;

  const WatermarkConfigSheet({
    super.key,
    this.initialText,
    this.initialImagePath,
    this.initialIsGridPattern,
  });

  @override
  State<WatermarkConfigSheet> createState() => _WatermarkConfigSheetState();
}

class _WatermarkConfigSheetState extends State<WatermarkConfigSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _textController;
  String? _selectedImagePath;
  bool _isGridPattern = false; // false = single, true = grid

  @override
  void initState() {
    super.initState();
    _isGridPattern = widget.initialIsGridPattern ?? false;
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(() {
        if (mounted) setState(() {});
      });
    _textController = TextEditingController(text: widget.initialText);
    _selectedImagePath = widget.initialImagePath;

    if (widget.initialImagePath != null) {
      _tabController.index = 1;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _selectImage() async {
    // Navigate to file selection for image
    final selectionId =
        'watermark_img_${DateTime.now().microsecondsSinceEpoch}';

    try {
      final mgr = Get.find<SelectionManager>();
      mgr.of(selectionId);
    } catch (_) {
      // if DI not initialized, still continue
    }

    if (!mounted) return;

    // Close the sheet first to avoid navigation conflicts
    Navigator.of(context).pop({
      'text': null,
      'imagePath': _selectedImagePath,
      'needsImageSelection': true,
      'selectionId': selectionId,
    });
  }

  void _apply() {
    final text = _textController.text.trim();

    if (_tabController.index == 0 && text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter watermark text')),
      );
      return;
    }

    if (_tabController.index == 1 && _selectedImagePath == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select an image')));
      return;
    }

    Navigator.of(context).pop({
      'text': _tabController.index == 0 ? text : null,
      'imagePath': _tabController.index == 1 ? _selectedImagePath : null,
      'isGridPattern': _isGridPattern,
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final viewInsets = mediaQuery.viewInsets;

    return SafeArea(
      top: false,
      left: false,
      right: false,
      bottom: true,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + viewInsets.bottom),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Container(
            color: theme.dialogBackgroundColor,
            child: Padding(
              padding: const EdgeInsets.only(
                left: 20,
                right: 20,
                top: 10,
                bottom: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  Container(
                    width: 48,
                    height: 4,
                    margin: const EdgeInsets.only(top: 0, bottom: 16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  // Header
                  Text(
                    'Add Watermark',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.15,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Divider(height: 1, color: theme.dividerColor.withAlpha(64)),
                  const SizedBox(height: 16),
                  // Tabs
                  TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(
                        text: 'Watermark Text',
                        icon: Icon(Icons.text_fields),
                      ),
                      Tab(text: 'Watermark Logo', icon: Icon(Icons.image)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Tab content with flexible height
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    switchInCurve: Curves.easeInOut,
                    switchOutCurve: Curves.easeInOut,
                    child: _tabController.index == 0
                        ? _buildTextTab(
                            context,
                          ) // key ensures height can change
                        : _buildImageTab(context),
                  ),
                  // const SizedBox(height: 16),
                  // Watermark pattern toggle
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withAlpha((0.3 * 255).toInt()),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isGridPattern ? Icons.grid_on : Icons.filter_1,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Watermark Pattern',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                _isGridPattern
                                    ? 'Grid pattern across page'
                                    : 'Single watermark centered',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _isGridPattern,
                          onChanged: (value) {
                            setState(() {
                              _isGridPattern = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            backgroundColor: const Color(0xFFE9EDFF),
                            foregroundColor: const Color(0xFF3D5AFE),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: const StadiumBorder(),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _canApply() ? _apply : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3D5AFE),
                            foregroundColor: Colors.white,
                            elevation: 4,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: const StadiumBorder(),
                          ),
                          child: const Text('Continue'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextTab(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      key: const ValueKey('text_tab'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Your Text',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _textController,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              isDense: true,
              hintText: 'Enter watermark text...',
              border: UnderlineInputBorder(),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFE0E0E0)),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF3D5AFE), width: 2),
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 10),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _buildImageTab(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      key: const ValueKey('image_tab'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Select Logo',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          if (_selectedImagePath != null) ...[
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: theme.dividerColor),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(_selectedImagePath!),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          OutlinedButton.icon(
            onPressed: _selectImage,
            icon: const Icon(Icons.image),
            label: Text(
              _selectedImagePath != null ? 'Change Image' : 'Select Image',
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ],
      ),
    );
  }

  bool _canApply() {
    if (_tabController.index == 0) {
      return _textController.text.trim().isNotEmpty;
    } else {
      return _selectedImagePath != null;
    }
  }
}
