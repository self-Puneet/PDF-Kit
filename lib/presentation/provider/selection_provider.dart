// selection_provider.dart
import 'package:flutter/foundation.dart';
import 'package:pdf_kit/models/file_model.dart';

class SelectionProvider extends ChangeNotifier {
  final Map<String, FileInfo> _selected = {};
  final Map<String, int> _rotations = {};
  int _mode = 0;

  int get mode => _mode;
  bool get isEnabled => _mode != 0;
  int get count => _selected.length;
  Map<String, FileInfo> get selected => _selected;
  bool isSelected(String path) => _selected.containsKey(path);
  List<FileInfo> get files => _selected.values.toList(growable: false);
  
  int getRotation(String path) => _rotations[path] ?? 0;
  
  List<MapEntry<FileInfo, int>> get filesWithRotation {
    return _selected.entries
        .map((e) => MapEntry(e.value, _rotations[e.key] ?? 0))
        .toList(growable: false);
  }

  void enable() {
    if (_mode == 0) {
      _mode = 1;
      notifyListeners();
    }
  }

  void disable() {
    if (_mode != 0) {
      _mode = 0;
      _selected.clear();
      _rotations.clear();
      notifyListeners();
    }
  }

  void toggle(FileInfo f) {
    if (_selected.containsKey(f.path)) {
      _selected.remove(f.path);
      _rotations.remove(f.path);
    } else {
      _selected[f.path] = f;
      _rotations[f.path] = 0;
    }
    notifyListeners();
  }
  
  void removeFile(String path) {
    _selected.remove(path);
    _rotations.remove(path);
    notifyListeners();
  }
  
  void rotateFile(String path) {
    if (_selected.containsKey(path)) {
      final currentRotation = _rotations[path] ?? 0;
      _rotations[path] = (currentRotation + 90) % 360;
      notifyListeners();
    }
  }

  bool areAllSelected(Iterable<FileInfo> visible) {
    var any = false;
    for (final f in visible) {
      if (f.isDirectory) continue;
      any = true;
      if (!_selected.containsKey(f.path)) return false;
    }
    return any;
  }

  bool anySelected(Iterable<FileInfo> visible) {
    for (final f in visible) {
      if (!f.isDirectory && _selected.containsKey(f.path)) return true;
    }
    return false;
  }

  void selectAllVisible(Iterable<FileInfo> visible) {
    for (final f in visible) {
      if (!f.isDirectory) {
        _selected[f.path] = f;
        if (!_rotations.containsKey(f.path)) {
          _rotations[f.path] = 0;
        }
      }
    }
    if (_mode == 0) _mode = 1;
    notifyListeners();
  }

  void clearVisible(Iterable<FileInfo> visible) {
    for (final f in visible) {
      _selected.remove(f.path);
      _rotations.remove(f.path);
    }
    if (_mode == 0) _mode = 1;
    notifyListeners();
  }

  void clearKeepEnabled() {
    _selected.clear();
    _rotations.clear();
    _mode = 1;
    notifyListeners();
  }

  void cyclePage(Iterable<FileInfo> visible) {
    if (_mode == 0) {
      _mode = 1;
      notifyListeners();
      return;
    }
    if (areAllSelected(visible)) {
      clearVisible(visible);
    } else {
      selectAllVisible(visible);
    }
  }
}
