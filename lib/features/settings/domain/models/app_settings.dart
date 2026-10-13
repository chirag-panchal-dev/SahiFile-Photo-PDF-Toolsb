import 'package:flutter/material.dart';
import 'package:sahifile/core/localization/app_strings.dart';
import 'package:sahifile/features/presets/domain/models/preset_item.dart';

class AppSettings {
  final ThemeMode themeMode;
  final AppLanguage language;
  final bool onboardingCompleted;
  final OutputFormat defaultImageFormat;
  final String defaultPdfPageSize;

  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.language = AppLanguage.english,
    this.onboardingCompleted = false,
    this.defaultImageFormat = OutputFormat.jpg,
    this.defaultPdfPageSize = 'A4',
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    AppLanguage? language,
    bool? onboardingCompleted,
    OutputFormat? defaultImageFormat,
    String? defaultPdfPageSize,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      defaultImageFormat: defaultImageFormat ?? this.defaultImageFormat,
      defaultPdfPageSize: defaultPdfPageSize ?? this.defaultPdfPageSize,
    );
  }
}
