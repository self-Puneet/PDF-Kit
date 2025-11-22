import 'package:flutter/material.dart';
import 'package:pdf_kit/models/file_model.dart';
import 'package:pdf_kit/presentation/component/document_tile.dart';
import 'package:pdf_kit/service/recent_file_service.dart';
import 'package:pdf_kit/core/app_export.dart';
import 'package:pdf_kit/presentation/sheets/clear_recent_files_sheet.dart';

class RecentFilesPage extends StatefulWidget {
  const RecentFilesPage({Key? key}) : super(key: key);

  @override
  State<RecentFilesPage> createState() => _RecentFilesPageState();
}

class _RecentFilesPageState extends State<RecentFilesPage> {
  late Future<List<FileInfo>> _recentFilesFuture;

  @override
  void initState() {
    super.initState();
    debugPrint('📱 [RecentFilesPage] initState called');
    _loadRecentFiles();
  }

  void _loadRecentFiles() {
    debugPrint('🔄 [RecentFilesPage] Loading recent files...');
    _recentFilesFuture = RecentFilesService.getRecentFiles().then((result) {
      return result.fold(
        (error) {
          debugPrint('❌ [RecentFilesPage] Error loading: $error');
          return <FileInfo>[];
        },
        (files) {
          debugPrint('✅ [RecentFilesPage] Loaded ${files.length} files');
          return files;
        },
      );
    });
  }

  void _handleFileOpen(FileInfo file) {
    debugPrint('🔓 [RecentFilesPage] Opening file: ${file.name}');
    context.pushNamed(
      AppRouteName.showPdf,
      queryParameters: {'path': file.path},
    );
  }

  Future<void> _handleFileDelete(FileInfo file) async {
    debugPrint('🗑️ [RecentFilesPage] Deleting file: ${file.name}');
    final result = await RecentFilesService.removeRecentFile(file.path);
    final t = AppLocalizations.of(context);

    result.fold(
      (error) {
        debugPrint('❌ [RecentFilesPage] Delete failed: $error');
        if (mounted) {
          final msg = t
              .t('snackbar_error')
              .replaceAll('{message}', error.toString());
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      },
      (updatedFiles) {
        debugPrint(
          '✅ [RecentFilesPage] Delete successful. Remaining: ${updatedFiles.length}',
        );
        if (mounted) {
          setState(() => _loadRecentFiles());
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(t.t('snackbar_removed_recent'))),
          );
        }
      },
    );
  }

  void _handleFileMenu(FileInfo file, String action) {
    debugPrint('📋 [RecentFilesPage] Menu action "$action" for: ${file.name}');
    switch (action) {
      case 'open':
        _handleFileOpen(file);
        break;
      case 'delete':
        _handleFileDelete(file);
        break;
      case 'rename':
        debugPrint('ℹ️ [RecentFilesPage] Rename not implemented yet');
        final t = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.t('common_rename_coming_soon'))),
        );
        break;
      case 'share':
        debugPrint('📤 [RecentFilesPage] Share handled by DocEntryCard');
        break;
    }
  }

  Future<void> _openClearRecentFilesSheet() async {
    await showClearRecentFilesSheet(
      context: context,
      onClear: () async {
        debugPrint('🧹 [RecentFilesPage] Clear All pressed');
        final result = await RecentFilesService.clearRecentFiles();
        final t = AppLocalizations.of(context);

        result.fold(
          (error) {
            debugPrint('❌ [RecentFilesPage] Clear All failed: $error');
            if (mounted) {
              final msg = t
                  .t('snackbar_error')
                  .replaceAll('{message}', error.toString());
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(msg)));
            }
          },
          (_) {
            debugPrint('✅ [RecentFilesPage] Clear All successful');
            if (mounted) {
              setState(() => _loadRecentFiles());
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: screenPadding,
          child: Column(
            children: [
              _buildHeader(context),
              const SizedBox(height: 8),
              Expanded(
                child: FutureBuilder<List<FileInfo>>(
                  future: _recentFilesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      debugPrint(
                        '⏳ [RecentFilesPage] Showing loading indicator',
                      );
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      debugPrint(
                        '⚠️ [RecentFilesPage] Error: ${snapshot.error}',
                      );
                      final t = AppLocalizations.of(context);
                      return Center(
                        child: Text(
                          t.t('errors_failed_to_load_recent'),
                          style: theme.textTheme.bodyLarge,
                        ),
                      );
                    }

                    final files = snapshot.data ?? [];
                    debugPrint(
                      '📊 [RecentFilesPage] Rendering ${files.length} files',
                    );

                    if (files.isEmpty) {
                      final t = AppLocalizations.of(context);
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.history,
                              size: 64,
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.3,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              t.t('recent_files_empty_title'),
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              t.t('recent_files_empty_message'),
                              style: theme.textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: files.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: DocEntryCard(
                          info: files[i],
                          onOpen: () => _handleFileOpen(files[i]),
                          onMenu: (action) => _handleFileMenu(files[i], action),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.center,
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.history,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            t.t('recent_files_title'),
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              context.pushNamed(AppRouteName.recentFilesSearch);
            },
            tooltip: t.t('common_search'),
          ),
          PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.more_vert),
            tooltip: t.t('files_more_tooltip'),
            onSelected: (value) {
              if (value == 'clear_all') {
                _openClearRecentFilesSheet();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'clear_all',
                child: Text(t.t('recent_files_clear_menu')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
