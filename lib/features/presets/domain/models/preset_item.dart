import 'dart:convert';

enum OutputFormat {
  jpg,
  png;

  String get extension => switch (this) {
    OutputFormat.jpg => 'jpg',
    OutputFormat.png => 'png',
  };

  String get label => switch (this) {
    OutputFormat.jpg => 'JPG / JPEG',
    OutputFormat.png => 'PNG',
  };
}

class PresetItem {
  final String id;
  final String name;
  final String category; // 'General', 'Passport', 'Exam', 'Signature', 'Custom'
  final int targetWidth;
  final int targetHeight;
  final double aspectRatio;
  final OutputFormat format;
  final int maxFileSizeBytes; // in bytes
  final String? notes;
  final bool isSystemPreset;

  const PresetItem({
    required this.id,
    required this.name,
    required this.category,
    required this.targetWidth,
    required this.targetHeight,
    required this.aspectRatio,
    required this.format,
    required this.maxFileSizeBytes,
    this.notes,
    this.isSystemPreset = false,
  });

  PresetItem copyWith({
    String? id,
    String? name,
    String? category,
    int? targetWidth,
    int? targetHeight,
    double? aspectRatio,
    OutputFormat format = OutputFormat.jpg,
    int? maxFileSizeBytes,
    String? notes,
    bool? isSystemPreset,
  }) {
    return PresetItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      targetWidth: targetWidth ?? this.targetWidth,
      targetHeight: targetHeight ?? this.targetHeight,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      format: format,
      maxFileSizeBytes: maxFileSizeBytes ?? this.maxFileSizeBytes,
      notes: notes ?? this.notes,
      isSystemPreset: isSystemPreset ?? this.isSystemPreset,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'targetWidth': targetWidth,
      'targetHeight': targetHeight,
      'aspectRatio': aspectRatio,
      'format': format.name,
      'maxFileSizeBytes': maxFileSizeBytes,
      'notes': notes,
      'isSystemPreset': isSystemPreset,
    };
  }

  factory PresetItem.fromMap(Map<String, dynamic> map) {
    return PresetItem(
      id: map['id'] as String,
      name: map['name'] as String,
      category: map['category'] as String? ?? 'Custom',
      targetWidth: (map['targetWidth'] as num).toInt(),
      targetHeight: (map['targetHeight'] as num).toInt(),
      aspectRatio: (map['aspectRatio'] as num).toDouble(),
      format: map['format'] == 'png' ? OutputFormat.png : OutputFormat.jpg,
      maxFileSizeBytes: (map['maxFileSizeBytes'] as num).toInt(),
      notes: map['notes'] as String?,
      isSystemPreset: map['isSystemPreset'] as bool? ?? false,
    );
  }

  String toJson() => jsonEncode(toMap());
  factory PresetItem.fromJson(String source) =>
      PresetItem.fromMap(jsonDecode(source) as Map<String, dynamic>);

  static List<PresetItem> get defaultPresets => [
    const PresetItem(
      id: 'passport_std',
      name: 'Passport Photo (35×45 mm)',
      category: 'Passport',
      targetWidth: 413,
      targetHeight: 531,
      aspectRatio: 35 / 45,
      format: OutputFormat.jpg,
      maxFileSizeBytes: 50 * 1024, // 50 KB
      notes: 'Standard 3.5cm x 4.5cm dimension for passport & visas.',
      isSystemPreset: true,
    ),
    const PresetItem(
      id: 'signature_std',
      name: 'Signature Standard',
      category: 'Signature',
      targetWidth: 300,
      targetHeight: 150,
      aspectRatio: 2.0,
      format: OutputFormat.jpg,
      maxFileSizeBytes: 20 * 1024, // 20 KB
      notes: 'Standard 2:1 ratio signature box for online forms.',
      isSystemPreset: true,
    ),
    const PresetItem(
      id: 'ssc_upsc_photo',
      name: 'SSC / UPSC Exam Photo',
      category: 'Exam',
      targetWidth: 350,
      targetHeight: 450,
      aspectRatio: 3.5 / 4.5,
      format: OutputFormat.jpg,
      maxFileSizeBytes: 50 * 1024, // 50 KB
      notes: 'Widely used for national exam portal submissions.',
      isSystemPreset: true,
    ),
    const PresetItem(
      id: 'pan_card_photo',
      name: 'PAN Card Photo (2×2 inch)',
      category: 'Identity',
      targetWidth: 600,
      targetHeight: 600,
      aspectRatio: 1.0,
      format: OutputFormat.jpg,
      maxFileSizeBytes: 100 * 1024, // 100 KB
      notes: 'Square 1:1 aspect ratio for ID cards.',
      isSystemPreset: true,
    ),
    const PresetItem(
      id: 'general_compact',
      name: 'General Form Photo (<100 KB)',
      category: 'General',
      targetWidth: 400,
      targetHeight: 500,
      aspectRatio: 4 / 5,
      format: OutputFormat.jpg,
      maxFileSizeBytes: 100 * 1024, // 100 KB
      notes: 'Clean compact portrait for everyday forms.',
      isSystemPreset: true,
    ),
  ];
}
