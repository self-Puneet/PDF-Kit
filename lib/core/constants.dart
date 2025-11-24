class Constants {
  Constants._();

  /// Shared preferences keys
  static const String prefsLanguageKey = 'app_language_code';
  static const String prefsThemeKey = 'app_theme_mode';
  static const String prefsOnboardingCompletedKey = 'onboarding_completed';

  /// Recent files storage key (used by RecentFilesService)
  static const String recentFilesKey = 'recent_files';

  /// Default image compression quality (0-100) used when compressing images
  /// during merge/compress flows. Tweak this value as needed.
  static const int imageCompressQuality = 60;
}
