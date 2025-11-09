// android_files_screen.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf_kit/core/models/file_model.dart';
import 'package:pdf_kit/presentation/component/document_tile.dart';
import 'package:pdf_kit/presentation/component/folder_tile.dart';
import 'package:pdf_kit/service/file_system_serevice.dart';
import 'package:pdf_kit/service/open_service.dart';
import 'package:pdf_kit/service/path_service.dart';
import 'package:pdf_kit/service/permission_service.dart';

class AndroidFilesScreen extends StatefulWidget {
  final String? initialPath;
  const AndroidFilesScreen({super.key, this.initialPath});
  @override
  State<AndroidFilesScreen> createState() => _AndroidFilesScreenState();
}

class _AndroidFilesScreenState extends State<AndroidFilesScreen> {
  List<Directory> _roots = [];
  String? _currentPath;
  List<FileInfo> _entries = [];
  String _query = '';
  bool _searching = false;

  StreamSubscription? _searchSub;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  @override
  void dispose() {
    _searchSub?.cancel();
    super.dispose();
  }

  Future<void> _boot() async {
    final perm = await PermissionService.requestStoragePermission();
    perm.fold((_) {}, (ok) async {
      if (!ok) return;
      final vols = await PathService.volumes();
      vols.fold((_) {}, (dirs) async {
        setState(() => _roots = dirs);
        final startPath =
            widget.initialPath ?? (dirs.isNotEmpty ? dirs.first.path : null);
        if (startPath != null) await _open(startPath);
      });
    });
  }

  Future<void> _open(String path) async {
    _cancelSearch();
    final res = await FileSystemService.list(path);
    res.fold((_) {}, (items) {
      setState(() {
        _currentPath = path;
        _entries = items;
        _query = '';
        _searching = false;
      });
    });
  }

  void _cancelSearch() {
    _searchSub?.cancel();
    _searchSub = null;
  }

  Future<void> _openFolder(String path) async {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AndroidFilesScreen(initialPath: path)),
    );
  }

  void _startDeepSearch(String q) {
    if (_currentPath == null) return;
    _cancelSearch();
    setState(() {
      _query = q;
      _entries = [];
      _searching = true;
    });
    debugPrint('startDeepSearch: query="$q" path=$_currentPath');
    // Optional: exclude heavy system paths if desired.
    final stream = FileSystemService.searchStream(
      _currentPath!,
      q,
      // excludePrefixes: const ['/storage/emulated/0/Android/obb'],
    );
    _searchSub = stream.listen(
      (either) {
        either.fold(
          (err) {
            debugPrint('searchStream yielded error: $err');
          },
          (fi) {
            debugPrint('searchStream hit: ${fi.path}');
            setState(() => _entries = [..._entries, fi]);
          },
        );
      },
      onDone: () {
        debugPrint('searchStream done for query="$q"');
      },
      onError: (err) {
        debugPrint('searchStream subscription error: $err');
      },
    );
  }

  Future<void> _clearSearchAndRestore() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _query = '';
      _searching = false;
    });
    debugPrint('clearSearchAndRestore: restoring $_currentPath');
    if (_currentPath != null) await _open(_currentPath!);
  }

  @override
  Widget build(BuildContext context) {
    // In AndroidFilesScreen.build:
    final items = _searching
        ? _entries // deep-search already filtered to files
        : (_query.isEmpty
              ? _entries
              : _entries
                    .where(
                      (e) =>
                          e.name.toLowerCase().contains(_query.toLowerCase()),
                    )
                    .toList());

    final folders = items
        .where((e) => e.isDirectory)
        .toList(); // will be empty when _searching
    final files = items.where((e) => !e.isDirectory).toList();

    return PopScope(
      canPop: !(_searching || _query.isNotEmpty),
      onPopInvoked: (didPop) async {
        if (didPop) return;
        // Back pressed while searching: clear filter and stay
        await _clearSearchAndRestore();
      },
      child: Scaffold(
        appBar: AppBar(
          title: _searching || _query.isNotEmpty
              ? TextField(
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Search files and folders...',
                  ),
                  onChanged: _startDeepSearch,
                )
              : Text(_currentPath ?? 'Storage'),
          actions: [
            if (!_searching && _query.isEmpty)
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () => setState(() => _searching = true),
              ),
            if (_searching || _query.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: _clearSearchAndRestore,
              ),
          ],
        ),
        body: SafeArea(
          top: false,
          bottom: true,
          child: _currentPath == null
              ? _buildRoots()
              : _buildListing(folders, files),
        ),
        floatingActionButton: !_searching && _query.isEmpty
            ? FloatingActionButton(
                onPressed: () =>
                    Navigator.of(context).popUntil((r) => r.isFirst),
                tooltip: 'Back to Roots',
                child: const Icon(Icons.home),
              )
            : null,
      ),
    );
  }

  Widget _buildRoots() => ListView(
    children: _roots
        .map(
          (d) => ListTile(
            leading: const Icon(Icons.sd_storage),
            title: Text(d.path),
            onTap: () => _openFolder(d.path),
          ),
        )
        .toList(),
  );

  Widget _buildListing(
    List<FileInfo> folders,
    List<FileInfo> files,
  ) => RefreshIndicator(
    onRefresh: () => _open(_currentPath!),
    child: ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text('Total: ${folders.length + files.length} items'),
        ),

        if (folders.isNotEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text('Folders'),
          ),

        // Folders with FolderEntryCard (uses only FileInfo)
        ...folders.map(
          (f) => Container(
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            child: FolderEntryCard(
              info: f,
              onTap: () => _openFolder(f.path),
              onMenuSelected: (v) => _handleFolderMenu(v, f),
            ),
          ),
        ),

        // if (files.isNotEmpty) const Divider(),

        // Files with DocEntryCard (uses only FileInfo; shows PDF/image preview)
        ...files.map(
          (f) => Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            child: DocEntryCard(
              info: f,
              onOpen: () => OpenService.open(f.path),
              onMenu: (v) => _handleFileMenu(v, f),
            ),
          ),
        ),
      ],
    ),
  );

  // Optional simple handlers
  void _handleFolderMenu(String v, FileInfo f) {
    switch (v) {
      case 'open':
        _openFolder(f.path);
        break;
      case 'rename':
        // TODO: implement rename
        break;
      case 'delete':
        // TODO: implement delete
        break;
    }
  }

  void _handleFileMenu(String v, FileInfo f) {
    switch (v) {
      case 'open':
        OpenService.open(f.path);
        break;
      case 'rename':
        // TODO: implement rename
        break;
      case 'delete':
        // TODO: implement delete
        break;
    }
  }
}
