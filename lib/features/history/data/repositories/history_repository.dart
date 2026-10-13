import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sahifile/core/constants/app_constants.dart';
import 'package:sahifile/features/history/domain/models/history_item.dart';

class HistoryRepository {
  final SharedPreferences _prefs;

  HistoryRepository(this._prefs);

  List<HistoryItem> getHistory() {
    final rawList = _prefs.getStringList(AppConstants.prefHistoryItems) ?? [];
    final items = <HistoryItem>[];

    for (final raw in rawList) {
      try {
        final item = HistoryItem.fromJson(raw);
        items.add(item);
      } catch (_) {}
    }

    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return items;
  }

  Future<void> addHistory(HistoryItem item) async {
    final rawList = _prefs.getStringList(AppConstants.prefHistoryItems) ?? [];
    final updatedList = [item.toJson(), ...rawList];
    if (updatedList.length > 50) {
      updatedList.removeRange(50, updatedList.length);
    }
    await _prefs.setStringList(AppConstants.prefHistoryItems, updatedList);
  }

  Future<void> deleteHistoryItem(String id) async {
    final rawList = _prefs.getStringList(AppConstants.prefHistoryItems) ?? [];
    final updatedList = <String>[];

    for (final raw in rawList) {
      try {
        final item = HistoryItem.fromJson(raw);
        if (item.id == id) {
          final file = File(item.filePath);
          if (file.existsSync()) {
            file.deleteSync();
          }
          continue;
        }
        updatedList.add(raw);
      } catch (_) {}
    }

    await _prefs.setStringList(AppConstants.prefHistoryItems, updatedList);
  }

  Future<void> clearHistory({bool deleteFiles = false}) async {
    if (deleteFiles) {
      final items = getHistory();
      for (final item in items) {
        try {
          final file = File(item.filePath);
          if (file.existsSync()) {
            file.deleteSync();
          }
        } catch (_) {}
      }
    }
    await _prefs.remove(AppConstants.prefHistoryItems);
  }
}
