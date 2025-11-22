import 'package:flutter/material.dart';
import 'package:pdf_kit/core/utility/storage_utility.dart';

class LocaleProvider extends ChangeNotifier {
  static const _key = 'app_language_code';
  Locale? _locale;
  Locale? get locale => _locale;

  LocaleProvider() {
    _loadLocale();
  }

  void _loadLocale() {
    final saved = Prefs.getString(_key);
    debugPrint('LocaleProvider: loaded saved locale -> $saved');
    if (saved != null && saved.isNotEmpty) {
      _locale = Locale(saved);
      notifyListeners();
    }
  }

  Future<void> setLocale(String code) async {
    debugPrint('LocaleProvider: setLocale -> $code');
    _locale = Locale(code);
    await Prefs.setString(_key, code);
    notifyListeners();
  }
}
