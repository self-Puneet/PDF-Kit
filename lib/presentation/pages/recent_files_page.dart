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

    result.fold(
      (error) {
        debugPrint('❌ [RecentFilesPage] Delete failed: $error');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $error'),
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
            const SnackBar(content: Text('Removed from recent files')),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rename feature coming soon')),
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
        result.fold(
          (error) {
            debugPrint('❌ [RecentFilesPage] Clear All failed: $error');
            if (mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Error: $error')));
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
                      return Center(
                        child: Text(
                          'Failed to load recent files.',
                          style: theme.textTheme.bodyLarge,
                        ),
                      );
                    }

                    final files = snapshot.data ?? [];
                    debugPrint(
                      '📊 [RecentFilesPage] Rendering ${files.length} files',
                    );

                    if (files.isEmpty) {
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
                              'No recent files',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Your recently accessed files will appear here.',
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
            'Recent Files',
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
            tooltip: 'Search',
          ),
          PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.more_vert),
            tooltip: 'More',
            onSelected: (value) {
              if (value == 'clear_all') {
                _openClearRecentFilesSheet();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear_all',
                child: Text('Clear all recent files'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
