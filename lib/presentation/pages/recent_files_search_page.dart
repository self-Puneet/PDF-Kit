// recent_files_search_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pdf_kit/models/file_model.dart';
import 'package:pdf_kit/presentation/component/document_tile.dart';
import 'package:pdf_kit/service/recent_file_service.dart';
import 'package:pdf_kit/core/app_export.dart';

class RecentFilesSearchPage extends StatefulWidget {
  const RecentFilesSearchPage({super.key});

  @override
  State<RecentFilesSearchPage> createState() => _RecentFilesSearchPageState();
}

class _RecentFilesSearchPageState extends State<RecentFilesSearchPage> {
  final TextEditingController _controller = TextEditingController();
  List<FileInfo> _allRecentFiles = [];
  List<FileInfo> _filteredResults = [];
  String _query = '';
  bool _isLoading = true;

  // Fake “Previous Search” seeds (static for now - can be made dynamic later)
  final List<String> _previous = const [
    'My Home Certificate',
    'Work Documents',
    'Recommendation Letter',
    'Sales Report Documents',
    'Business Plan Proposal',
    'Job Application Letter',
    'Legal & Terms of Reference',
    'My National ID Card',
  ];

  @override
  void initState() {
    super.initState();
    _loadRecentFiles();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadRecentFiles() async {
    setState(() => _isLoading = true);
    final result = await RecentFilesService.getRecentFiles();
    result.fold(
      (error) {
        debugPrint('❌ [RecentFilesSearch] Error loading: $error');
        if (mounted) {
          setState(() {
            _allRecentFiles = [];
            _isLoading = false;
          });
        }
      },
      (files) {
        debugPrint('✅ [RecentFilesSearch] Loaded ${files.length} files');
        if (mounted) {
          setState(() {
            _allRecentFiles = files;
            _isLoading = false;
          });
        }
      },
    );
  }

  void _search(String query) {
    setState(() {
      _query = query;
      if (query.isEmpty) {
        _filteredResults = [];
      } else {
        final q = query.toLowerCase();
        _filteredResults = _allRecentFiles.where((f) {
          // Get filename without extension for search
          final nameWithoutExt = f.name.contains('.')
              ? f.name.substring(0, f.name.lastIndexOf('.'))
              : f.name;
          return nameWithoutExt.toLowerCase().contains(q);
        }).toList();
      }
    });
  }

  void _handleFileOpen(FileInfo file) {
    debugPrint('🔓 [RecentFilesSearch] Opening file: ${file.name}');
    context.pushNamed(
      AppRouteName.showPdf,
      queryParameters: {'path': file.path},
    );
  }

  Future<void> _handleFileDelete(FileInfo file) async {
    debugPrint('🗑️ [RecentFilesSearch] Deleting file: ${file.name}');
    final result = await RecentFilesService.removeRecentFile(file.path);

    result.fold(
      (error) {
        debugPrint('❌ [RecentFilesSearch] Delete failed: $error');
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
          '✅ [RecentFilesSearch] Delete successful. Remaining: ${updatedFiles.length}',
        );
        if (mounted) {
          _loadRecentFiles();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Removed from recent files')),
          );
        }
      },
    );
  }

  void _handleFileMenu(FileInfo file, String action) {
    debugPrint(
      '📋 [RecentFilesSearch] Menu action "$action" for: ${file.name}',
    );
    switch (action) {
      case 'open':
        _handleFileOpen(file);
        break;
      case 'delete':
        _handleFileDelete(file);
        break;
      case 'rename':
        debugPrint('ℹ️ [RecentFilesSearch] Rename not implemented yet');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rename feature coming soon')),
        );
        break;
      case 'share':
        debugPrint('📤 [RecentFilesSearch] Share handled by DocEntryCard');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasQuery = _query.isNotEmpty;
    final noResults = hasQuery && !_isLoading && _filteredResults.isEmpty;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _searchBar(context),
            if (!hasQuery) _previousSection(context),
            if (hasQuery && !noResults) Expanded(child: _list()),
            if (noResults) _emptyState(context),
          ],
        ),
      ),
    );
  }

  Widget _previousSection(BuildContext context) {
    return Expanded(
      child: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
            child: Row(
              children: [
                Text(
                  'Previous Search',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {}, // optional: clear all later
                  icon: const Icon(Icons.close),
                  tooltip: 'Clear all',
                ),
              ],
            ),
          ),
          ..._previous.map(
            (label) => ListTile(
              title: Text(label),
              trailing: const Icon(Icons.close, size: 18),
              onTap: () {
                _controller.text = label;
                _controller.selection = TextSelection.collapsed(
                  offset: label.length,
                );
                _search(label);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () => Navigator.pop(context),
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.arrow_back),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest
                    .withAlpha((0.6 * 225).toInt()),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: TextField(
                controller: _controller,
                autofocus: true,
                onChanged: _search,
                style: Theme.of(context).textTheme.labelLarge,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Search recent files...',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  suffixIcon: (_controller.text.isNotEmpty)
                      ? IconButton(
                          constraints: const BoxConstraints(
                            minWidth: 28,
                            minHeight: 28,
                          ),
                          iconSize: 18,
                          padding: const EdgeInsets.all(5),
                          tooltip: 'Clear',
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _controller.clear();
                            _search('');
                          },
                        )
                      : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget _recentFilesHint(BuildContext context) {
  //   if (_isLoading) {
  //     return const Expanded(child: Center(child: CircularProgressIndicator()));
  //   }

  //   return Expanded(
  //     child: Center(
  //       child: Padding(
  //         padding: const EdgeInsets.symmetric(horizontal: 24),
  //         child: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             Icon(
  //               Icons.search,
  //               size: 64,
  //               color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
  //             ),
  //             const SizedBox(height: 16),
  //             Text(
  //               'Search your recent files',
  //               style: Theme.of(
  //                 context,
  //               ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
  //               textAlign: TextAlign.center,
  //             ),
  //             const SizedBox(height: 8),
  //             Text(
  //               'Type to search through ${_allRecentFiles.length} recent ${_allRecentFiles.length == 1 ? 'file' : 'files'}.',
  //               style: Theme.of(context).textTheme.bodyMedium?.copyWith(
  //                 color: Theme.of(
  //                   context,
  //                 ).colorScheme.onSurface.withOpacity(0.7),
  //               ),
  //               textAlign: TextAlign.center,
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }

  Widget _list() {
    return ListView.builder(
      key: const PageStorageKey('recent_search_list'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: _filteredResults.length,
      itemBuilder: (context, index) {
        final f = _filteredResults[index];
        return RepaintBoundary(
          key: ValueKey(f.path),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
            child: DocEntryCard(
              info: f,
              onOpen: () => _handleFileOpen(f),
              onMenu: (action) => _handleFileMenu(f, action),
            ),
          ),
        );
      },
    );
  }

  Widget _emptyState(BuildContext context) {
    return Expanded(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/not_found.png'),
              const SizedBox(height: 12),
              Text(
                'No results found',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Try searching with different keywords.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
