// lib/presentation/pages/merge_pdf_page.dart
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:pdf_kit/models/file_model.dart';
import 'package:pdf_kit/core/app_export.dart';
import 'package:pdf_kit/presentation/state/selection_state.dart';


class MergePdfPage extends StatefulWidget {
  const MergePdfPage({super.key});

  @override
  State<MergePdfPage> createState() => _MergePdfPageState();
}

class _MergePdfPageState extends State<MergePdfPage> {
  late final TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: 'Merged Document');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  String _displayName(FileInfo f) {
    // Prefer a model-provided name if present, else derive from path.
    try {
      final dynamic maybeName = (f as dynamic).name;
      if (maybeName is String && maybeName.trim().isNotEmpty) return maybeName;
    } catch (_) {}
    return p.basenameWithoutExtension(f.path);
  }

  String _suggestDefaultName(List<FileInfo> files) {
    if (files.isEmpty) return 'Merged Document';
    // Take first file name + " - Merged"
    final first = _displayName(files.first);
    return '${first.isEmpty ? "Merged Document" : first} - Merged';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<SelectionProvider>(
      builder: (context, selection, _) {
        final files = selection.files;

        // First-time suggestion based on current selection
        if ((_nameCtrl.text.isEmpty || _nameCtrl.text == 'Merged Document') &&
            files.isNotEmpty) {
          _nameCtrl.text = _suggestDefaultName(files);
          _nameCtrl.selection = TextSelection.fromPosition(
            TextPosition(offset: _nameCtrl.text.length),
          );
        }

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
            title: const Text('Merge PDF'),
            centerTitle: false,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${files.length} selected files to be merged',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // File Name section
                  Text(
                    'File Name',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameCtrl,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      hintText: 'Type output file name',
                      border: const UnderlineInputBorder(),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: theme.colorScheme.primary.withOpacity(0.3),
                        ),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: theme.colorScheme.primary,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Selected files
                  for (final f in files) ...[
                    _SelectedFileTile(
                      name: _displayName(f),
                      subtitle: _tryFormatSubtitle(f),
                      onRemove: () => selection.toggle(f),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Add more files
                  _AddMoreButton(
                    onTap: () {
                      context.pushNamed(
                        AppRouteName.filesRootFullscreen,
                        queryParameters: {'actionText': 'Add'},
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: SafeArea(
            minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: files.length >= 2
                    ? () {
                        // TODO: Plug in actual merge operation.
                        // For now, show a confirmation.
                        final outName = _nameCtrl.text.trim().isEmpty
                            ? 'Merged Document'
                            : _nameCtrl.text.trim();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Merging ${files.length} files into "$outName"...'),
                          ),
                        );
                      }
                    : null,
                child: const Text('Merge'),
              ),
            ),
          ),
        );
      },
    );
  }

  // Graceful, no-dependency subtitle fallback.
  String _tryFormatSubtitle(FileInfo f) {
    // If your FileInfo carries a "modified" DateTime, show it; otherwise path.
    try {
      final dynamic modified = (f as dynamic).modified;
      if (modified is DateTime) {
        final d = modified;
        final mm = d.month.toString().padLeft(2, '0');
        final dd = d.day.toString().padLeft(2, '0');
        final yy = d.year.toString();
        final hh = d.hour.toString().padLeft(2, '0');
        final min = d.minute.toString().padLeft(2, '0');
        return '$mm/$dd/$yy  $hh:$min';
      }
    } catch (_) {}
    return p.basename(f.path);
  }
}

class _SelectedFileTile extends StatelessWidget {
  const _SelectedFileTile({
    required this.name,
    required this.subtitle,
    required this.onRemove,
  });

  final String name;
  final String subtitle;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Thumbnail placeholder
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.picture_as_pdf_rounded),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: onRemove,
            tooltip: 'Remove',
          ),
        ],
      ),
    );
  }
}

class _AddMoreButton extends StatelessWidget {
  const _AddMoreButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Add More Files',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
