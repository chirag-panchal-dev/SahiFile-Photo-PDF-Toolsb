import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sahifile/features/history/data/repositories/history_repository.dart';
import 'package:sahifile/features/history/domain/models/history_item.dart';
import 'package:sahifile/features/presets/data/repositories/preset_repository.dart';
import 'package:sahifile/features/presets/domain/models/preset_item.dart';

void main() {
  group('PresetRepository Tests', () {
    test('loads default presets when no custom presets exist', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = PresetRepository(prefs);

      final presets = repo.getAllPresets();
      expect(presets.length, greaterThanOrEqualTo(5));
      expect(presets.any((p) => p.name.contains('Passport')), isTrue);
      expect(presets.any((p) => p.category == 'Signature'), isTrue);
    });

    test('saves and deletes custom preset properly', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = PresetRepository(prefs);

      const customPreset = PresetItem(
        id: 'test_custom_1',
        name: 'Custom Police Exam',
        category: 'Exam',
        targetWidth: 350,
        targetHeight: 450,
        aspectRatio: 350 / 450,
        format: OutputFormat.jpg,
        maxFileSizeBytes: 50 * 1024,
        isSystemPreset: false,
      );

      await repo.savePreset(customPreset);

      final listAfterSave = repo.getAllPresets();
      expect(listAfterSave.any((p) => p.id == 'test_custom_1'), isTrue);

      await repo.deletePreset('test_custom_1');
      final listAfterDelete = repo.getAllPresets();
      expect(listAfterDelete.any((p) => p.id == 'test_custom_1'), isFalse);
    });
  });

  group('HistoryRepository Tests', () {
    test('adds, retrieves, and clears history items', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = HistoryRepository(prefs);

      final item = HistoryItem(
        id: 'test_hist_1',
        operation: HistoryOperation.photo,
        sourceName: 'input.jpg',
        outputName: 'photo_ready.jpg',
        filePath: '/tmp/photo_ready.jpg',
        fileSizeBytes: 45000,
        dimensionsOrPages: '413 × 531 px',
        timestamp: DateTime.now(),
      );

      await repo.addHistory(item);

      final history = repo.getHistory();
      expect(history.length, 1);
      expect(history.first.outputName, 'photo_ready.jpg');

      await repo.clearHistory();
      expect(repo.getHistory().isEmpty, isTrue);
    });
  });
}
