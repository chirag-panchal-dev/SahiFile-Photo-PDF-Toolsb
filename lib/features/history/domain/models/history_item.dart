import 'dart:convert';
import 'package:flutter/material.dart';

enum HistoryOperation {
  photo,
  signature,
  compress,
  imagesToPdf,
  pdfMerge,
  pdfCompress;

  String get label => switch (this) {
    HistoryOperation.photo => 'Photo Resize',
    HistoryOperation.signature => 'Signature',
    HistoryOperation.compress => 'Compressed Image',
    HistoryOperation.imagesToPdf => 'Images to PDF',
    HistoryOperation.pdfMerge => 'Merged PDF',
    HistoryOperation.pdfCompress => 'Optimized PDF',
  };

  IconData get icon => switch (this) {
    HistoryOperation.photo => Icons.image_outlined,
    HistoryOperation.signature => Icons.draw_outlined,
    HistoryOperation.compress => Icons.compress_outlined,
    HistoryOperation.imagesToPdf => Icons.picture_as_pdf_outlined,
    HistoryOperation.pdfMerge => Icons.call_merge_rounded,
    HistoryOperation.pdfCompress => Icons.picture_as_pdf_rounded,
  };

  bool get isPdf =>
      this == HistoryOperation.imagesToPdf ||
      this == HistoryOperation.pdfMerge ||
      this == HistoryOperation.pdfCompress;
}

class HistoryItem {
  final String id;
  final HistoryOperation operation;
  final String sourceName;
  final String outputName;
  final String filePath;
  final int fileSizeBytes;
  final String dimensionsOrPages;
  final DateTime timestamp;

  const HistoryItem({
    required this.id,
    required this.operation,
    required this.sourceName,
    required this.outputName,
    required this.filePath,
    required this.fileSizeBytes,
    required this.dimensionsOrPages,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'operation': operation.name,
      'sourceName': sourceName,
      'outputName': outputName,
      'filePath': filePath,
      'fileSizeBytes': fileSizeBytes,
      'dimensionsOrPages': dimensionsOrPages,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory HistoryItem.fromMap(Map<String, dynamic> map) {
    return HistoryItem(
      id: map['id'] as String,
      operation: HistoryOperation.values.firstWhere(
        (e) => e.name == map['operation'],
        orElse: () => HistoryOperation.photo,
      ),
      sourceName: map['sourceName'] as String,
      outputName: map['outputName'] as String,
      filePath: map['filePath'] as String,
      fileSizeBytes: (map['fileSizeBytes'] as num).toInt(),
      dimensionsOrPages: map['dimensionsOrPages'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }

  String toJson() => jsonEncode(toMap());
  factory HistoryItem.fromJson(String source) =>
      HistoryItem.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
