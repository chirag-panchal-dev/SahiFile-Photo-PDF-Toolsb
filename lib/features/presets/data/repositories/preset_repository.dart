import 'package:shared_preferences/shared_preferences.dart';
import 'package:sahifile/core/constants/app_constants.dart';
import 'package:sahifile/features/presets/domain/models/preset_item.dart';

class PresetRepository {
  final SharedPreferences _prefs;

  PresetRepository(this._prefs);

  List<PresetItem> getAllPresets() {
    final customRaw =
        _prefs.getStringList(AppConstants.prefCustomPresets) ?? [];
    final customPresets =
        customRaw
            .map((s) {
              try {
                return PresetItem.fromJson(s);
              } catch (_) {
                return null;
              }
            })
            .whereType<PresetItem>()
            .toList();

    return [...PresetItem.defaultPresets, ...customPresets];
  }

  Future<void> savePreset(PresetItem preset) async {
    final customRaw =
        _prefs.getStringList(AppConstants.prefCustomPresets) ?? [];
    final customPresets =
        customRaw
            .map((s) {
              try {
                return PresetItem.fromJson(s);
              } catch (_) {
                return null;
              }
            })
            .whereType<PresetItem>()
            .toList();

    final existingIndex = customPresets.indexWhere(
      (item) => item.id == preset.id,
    );
    if (existingIndex >= 0) {
      customPresets[existingIndex] = preset;
    } else {
      customPresets.add(preset);
    }

    final updatedRaw = customPresets.map((p) => p.toJson()).toList();
    await _prefs.setStringList(AppConstants.prefCustomPresets, updatedRaw);
  }

  Future<void> deletePreset(String presetId) async {
    final customRaw =
        _prefs.getStringList(AppConstants.prefCustomPresets) ?? [];
    final customPresets =
        customRaw
            .map((s) {
              try {
                return PresetItem.fromJson(s);
              } catch (_) {
                return null;
              }
            })
            .whereType<PresetItem>()
            .toList();

    customPresets.removeWhere((p) => p.id == presetId && !p.isSystemPreset);
    final updatedRaw = customPresets.map((p) => p.toJson()).toList();
    await _prefs.setStringList(AppConstants.prefCustomPresets, updatedRaw);
  }
}
