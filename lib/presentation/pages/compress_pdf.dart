import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:pdf_kit/core/app_export.dart';
import 'package:pdf_kit/models/file_model.dart';
import 'package:pdf_kit/presentation/component/document_tile.dart';
import 'package:pdf_kit/presentation/provider/selection_provider.dart';
import 'package:pdf_kit/presentation/layouts/selection_layout.dart';
import 'package:pdf_kit/presentation/pages/home_page.dart';
import 'package:path/path.dart' as p;
import 'package:pdf_kit/service/pdf_compress_service.dart';
import 'package:pdf_kit/service/recent_file_service.dart';
import 'package:dartz/dartz.dart' show Either; // avoid State name clash
import 'package:pdf_kit/service/pdf_merge_service.dart'
    show CustomException; // for Either left type

class CompressPdfPage extends StatefulWidget {
  final String? selectionId;
  const CompressPdfPage({super.key, this.selectionId});

  @override
  State<CompressPdfPage> createState() => _CompressPdfPageState();
}

class _CompressPdfPageState extends State<CompressPdfPage> {
  @override
  void initState() {
    super.initState();
    // Ensure minimum required selection for compress is 1
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        SelectionScope.of(context).setMinSelectable(1);
      } catch (_) {}
    });
  }

  double _compressionQuality = 60.0; // 0-100, where 100 is best quality
  bool _isWorking = false;
  int? _originalFileSize;
  int? _estimatedSize;

  void _updateEstimatedSize() {
    if (_originalFileSize == null) {
      _estimatedSize = null;
      return;
    }
    // Estimate compressed size based on quality slider
    // Higher quality (closer to 100) = less compression = larger size
    // Lower quality (closer to 0) = more compression = smaller size
    final compressionFactor = 0.2 + (_compressionQuality / 100) * 0.7;
    _estimatedSize = (_originalFileSize! * compressionFactor).round();
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  int _qualityToLevel(double quality) {
    // Convert 0-100 quality to 0-2 level (inverted)
    // 0-33 quality -> level 0 (high compression)
    // 34-66 quality -> level 1 (medium)
    // 67-100 quality -> level 2 (low compression)
    if (quality <= 33) return 0;
    if (quality <= 66) return 1;
    return 2;
  }

  Future<void> _handleCompress(
    BuildContext context,
    SelectionProvider sel,
  ) async {
    final t = AppLocalizations.of(context);
    if (sel.files.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.t('compress_pdf_select_first_error')),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }
    setState(() => _isWorking = true);
    final file = sel.files.first;
    try {
      final level = _qualityToLevel(_compressionQuality);
      final Either<CustomException, FileInfo> result =
          await PdfCompressService.compressFile(fileInfo: file, level: level);
      if (!mounted) return;
      result.fold(
        (err) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(err.message),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        },
        (compressed) async {
          // Store resulting compressed file to recent files
          debugPrint(
            '📝 [CompressPDF] Storing compressed file: ${compressed.name}',
          );
          final storeResult = await RecentFilesService.addRecentFile(
            compressed,
          );
          storeResult.fold(
            (error) => debugPrint('❌ [CompressPDF] Failed to store: $error'),
            (_) => debugPrint(
              '✅ [CompressPDF] Compressed file stored successfully',
            ),
          );

          if (!mounted) return;

          // Navigate to home and clear all routes
          sel.disable();
          context.go('/');

          // Trigger home page reload
          RecentFilesSection.refreshNotifier.value++;

          // Show success message after navigation
          Future.delayed(const Duration(milliseconds: 300), () {
            if (context.mounted) {
              final originalName = p.basename(file.path);
              final resultName = p.basename(compressed.path);
              final pattern = t
                  .t('compress_pdf_result_pattern')
                  .replaceFirst('{original}', originalName)
                  .replaceFirst(
                    '{level}',
                    '${_compressionQuality.round()}% quality',
                  )
                  .replaceFirst('{result}', resultName);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(pattern),
                  action: SnackBarAction(
                    label: t.t('common_open_snackbar'),
                    onPressed: () {},
                  ),
                ),
              );
            }
          });
        },
      );
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    print(AppLocalizations.of(context).t('compress_pdf_title'));

    final theme = Theme.of(context);
    return Consumer<SelectionProvider>(
      builder: (context, selection, _) {
        final hasFile = selection.files.isNotEmpty;
        final FileInfo? file = hasFile ? selection.files.first : null;
        return Scaffold(
          appBar: AppBar(
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 18),
              onPressed: _isWorking ? null : () => context.pop(),
            ),
          ),
          body: SafeArea(
            child: AbsorbPointer(
              absorbing: _isWorking,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context).t('compress_pdf_title'),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(
                        context,
                      ).t('compress_pdf_description'),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),
                    hasFile
                        ? Builder(
                            builder: (context) {
                              // Update original file size when file changes
                              if (_originalFileSize != file!.size) {
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  setState(() {
                                    _originalFileSize = file.size;
                                    _updateEstimatedSize();
                                  });
                                });
                              }
                              return DocEntryCard(
                                info: file,
                                showEdit: false,
                                showRemove: true,
                                selectable: false,
                                reorderable: false,
                                onOpen: null,
                              );
                            },
                          )
                        : Row(
                            children: [
                              const Icon(
                                Icons.picture_as_pdf_outlined,
                                size: 32,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  AppLocalizations.of(
                                    context,
                                  ).t('compress_pdf_no_pdf_selected'),
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                    const SizedBox(height: 28),
                    Text(
                      AppLocalizations.of(
                        context,
                      ).t('compress_pdf_select_level_label'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Quality: ${_compressionQuality.round()}%',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Slider(
                      value: _compressionQuality,
                      min: 0,
                      max: 100,
                      divisions: 100,
                      label: '${_compressionQuality.round()}%',
                      onChanged: _isWorking
                          ? null
                          : (value) {
                              setState(() {
                                _compressionQuality = value;
                                _updateEstimatedSize();
                              });
                            },
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Smallest', style: theme.textTheme.bodySmall),
                        Text('Best Quality', style: theme.textTheme.bodySmall),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (hasFile && _originalFileSize != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest
                              .withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.outline.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Original Size:',
                                  style: theme.textTheme.bodyMedium,
                                ),
                                Text(
                                  _formatFileSize(_originalFileSize!),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Estimated Size:',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                Text(
                                  _estimatedSize != null
                                      ? _formatFileSize(_estimatedSize!)
                                      : '--',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            if (_estimatedSize != null &&
                                _originalFileSize != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Savings: ${((1 - _estimatedSize! / _originalFileSize!) * 100).toStringAsFixed(0)}%',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.secondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          bottomNavigationBar: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: hasFile && !_isWorking
                      ? () => _handleCompress(context, selection)
                      : null,
                  child: _isWorking
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 12),
                            Text(
                              AppLocalizations.of(
                                context,
                              ).t('compress_pdf_compressing'),
                            ),
                          ],
                        )
                      : Text(
                          AppLocalizations.of(context).t('compress_pdf_button'),
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
