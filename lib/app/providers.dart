import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sahifile/core/localization/app_strings.dart';
import 'package:sahifile/features/history/data/repositories/history_repository.dart';
import 'package:sahifile/features/history/domain/models/history_item.dart';
import 'package:sahifile/features/pdf_tools/data/services/pdf_service.dart';
import 'package:sahifile/features/photo_editor/data/services/image_processing_service.dart';
import 'package:sahifile/features/presets/data/repositories/preset_repository.dart';
import 'package:sahifile/features/presets/domain/models/preset_item.dart';
import 'package:sahifile/features/settings/data/repositories/settings_repository.dart';
import 'package:sahifile/features/settings/domain/models/app_settings.dart';

// SharedPreferences Provider (Overridden in bootstrap/main)
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
});

// Repositories & Services
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SettingsRepository(prefs);
});

final presetRepositoryProvider = Provider<PresetRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return PresetRepository(prefs);
});

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return HistoryRepository(prefs);
});

final imageProcessingServiceProvider = Provider<ImageProcessingService>((ref) {
  return ImageProcessingService();
});

final pdfServiceProvider = Provider<PdfService>((ref) {
  return PdfService();
});

// Modern Riverpod 3 Notifiers

// Settings Notifier
class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    final repo = ref.watch(settingsRepositoryProvider);
    return repo.loadSettings();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await ref.read(settingsRepositoryProvider).saveThemeMode(mode);
  }

  Future<void> setLanguage(AppLanguage lang) async {
    state = state.copyWith(language: lang);
    await ref.read(settingsRepositoryProvider).saveLanguage(lang);
  }

  Future<void> completeOnboarding() async {
    state = state.copyWith(onboardingCompleted: true);
    await ref.read(settingsRepositoryProvider).setOnboardingCompleted();
  }

  Future<void> setDefaultFormat(OutputFormat format) async {
    state = state.copyWith(defaultImageFormat: format);
    await ref.read(settingsRepositoryProvider).saveDefaultFormat(format);
  }

  Future<void> setDefaultPdfPageSize(String size) async {
    state = state.copyWith(defaultPdfPageSize: size);
    await ref.read(settingsRepositoryProvider).saveDefaultPdfPageSize(size);
  }
}

final settingsControllerProvider =
    NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

// Strings Provider depending on selected language
final appStringsProvider = Provider<AppStrings>((ref) {
  final settings = ref.watch(settingsControllerProvider);
  return AppStrings(settings.language);
});

// Presets Notifier
class PresetsNotifier extends Notifier<List<PresetItem>> {
  @override
  List<PresetItem> build() {
    final repo = ref.watch(presetRepositoryProvider);
    return repo.getAllPresets();
  }

  Future<void> savePreset(PresetItem preset) async {
    await ref.read(presetRepositoryProvider).savePreset(preset);
    state = ref.read(presetRepositoryProvider).getAllPresets();
  }

  Future<void> deletePreset(String presetId) async {
    await ref.read(presetRepositoryProvider).deletePreset(presetId);
    state = ref.read(presetRepositoryProvider).getAllPresets();
  }

  void refresh() {
    state = ref.read(presetRepositoryProvider).getAllPresets();
  }
}

final presetsControllerProvider =
    NotifierProvider<PresetsNotifier, List<PresetItem>>(PresetsNotifier.new);

// History Notifier
class HistoryNotifier extends Notifier<List<HistoryItem>> {
  @override
  List<HistoryItem> build() {
    final repo = ref.watch(historyRepositoryProvider);
    return repo.getHistory();
  }

  Future<void> addHistory(HistoryItem item) async {
    await ref.read(historyRepositoryProvider).addHistory(item);
    state = ref.read(historyRepositoryProvider).getHistory();
  }

  Future<void> deleteItem(String id) async {
    await ref.read(historyRepositoryProvider).deleteHistoryItem(id);
    state = ref.read(historyRepositoryProvider).getHistory();
  }

  Future<void> clearHistory({bool deleteFiles = false}) async {
    await ref
        .read(historyRepositoryProvider)
        .clearHistory(deleteFiles: deleteFiles);
    state = [];
  }

  void refresh() {
    state = ref.read(historyRepositoryProvider).getHistory();
  }
}

final historyControllerProvider =
    NotifierProvider<HistoryNotifier, List<HistoryItem>>(HistoryNotifier.new);
