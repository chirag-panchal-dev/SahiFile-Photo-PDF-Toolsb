import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sahifile/core/constants/app_constants.dart';
import 'package:sahifile/core/localization/app_strings.dart';
import 'package:sahifile/features/presets/domain/models/preset_item.dart';
import 'package:sahifile/features/settings/domain/models/app_settings.dart';

class SettingsRepository {
  final SharedPreferences _prefs;

  SettingsRepository(this._prefs);

  AppSettings loadSettings() {
    final themeStr = _prefs.getString(AppConstants.prefThemeMode) ?? 'system';
    final themeMode = switch (themeStr) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };

    final langStr = _prefs.getString(AppConstants.prefLocale) ?? 'en';
    final language = langStr == 'hi' ? AppLanguage.hindi : AppLanguage.english;

    final onboardingDone =
        _prefs.getBool(AppConstants.prefOnboardingCompleted) ?? false;

    final formatStr =
        _prefs.getString(AppConstants.prefDefaultImageFormat) ?? 'jpg';
    final format = formatStr == 'png' ? OutputFormat.png : OutputFormat.jpg;

    final pdfSize =
        _prefs.getString(AppConstants.prefDefaultPdfPageSize) ?? 'A4';

    return AppSettings(
      themeMode: themeMode,
      language: language,
      onboardingCompleted: onboardingDone,
      defaultImageFormat: format,
      defaultPdfPageSize: pdfSize,
    );
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    final str = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await _prefs.setString(AppConstants.prefThemeMode, str);
  }

  Future<void> saveLanguage(AppLanguage lang) async {
    final code = lang == AppLanguage.hindi ? 'hi' : 'en';
    await _prefs.setString(AppConstants.prefLocale, code);
  }

  Future<void> setOnboardingCompleted() async {
    await _prefs.setBool(AppConstants.prefOnboardingCompleted, true);
  }

  Future<void> saveDefaultFormat(OutputFormat format) async {
    await _prefs.setString(AppConstants.prefDefaultImageFormat, format.name);
  }

  Future<void> saveDefaultPdfPageSize(String size) async {
    await _prefs.setString(AppConstants.prefDefaultPdfPageSize, size);
  }
}
