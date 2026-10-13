class AppConstants {
  AppConstants._();

  static const String appName = 'SahiFile';
  static const String appTagline = 'Photo & PDF Tools';
  static const String appSlogan = 'Make every file upload-ready.';
  static const String googlePlayTitle = 'SahiFile: Photo & PDF Tools';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';

  // Storage and directories
  static const String appWorkspaceDir = 'sahifile_workspace';
  static const String appExportsDir = 'SahiFile_Exports';
  static const String appTempPrefix = 'sahifile_temp_';

  // Supported image extensions
  static const List<String> supportedImageExtensions = [
    'jpg',
    'jpeg',
    'png',
    'webp',
    'bmp',
  ];

  // Supported PDF extensions
  static const List<String> supportedPdfExtensions = ['pdf'];

  // Default targets
  static const int defaultMaxImageSizeBytes = 100 * 1024; // 100 KB
  static const int minAcceptableQuality = 15;
  static const int maxDimensions = 8000;
  static const int minDimensions = 50;

  // SharedPreferences Keys
  static const String prefThemeMode = 'pref_theme_mode';
  static const String prefLocale = 'pref_locale';
  static const String prefOnboardingCompleted = 'pref_onboarding_completed';
  static const String prefDefaultImageFormat = 'pref_default_image_format';
  static const String prefDefaultPdfPageSize = 'pref_default_pdf_page_size';
  static const String prefCustomPresets = 'pref_custom_presets';
  static const String prefHistoryItems = 'pref_history_items';
}
