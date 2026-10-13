import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/glass_surface.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../domain/models/preset_item.dart';

class PresetFormDialog extends StatefulWidget {
  final PresetItem? existing;
  final Function(PresetItem) onSave;

  const PresetFormDialog({super.key, this.existing, required this.onSave});

  @override
  State<PresetFormDialog> createState() => _PresetFormDialogState();
}

class _PresetFormDialogState extends State<PresetFormDialog> {
  late TextEditingController _nameController;
  late TextEditingController _widthController;
  late TextEditingController _heightController;
  late TextEditingController _maxKbController;
  late TextEditingController _notesController;

  OutputFormat _format = OutputFormat.jpg;

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    _nameController = TextEditingController(text: p?.name ?? '');
    _widthController = TextEditingController(
      text: p != null ? '${p.targetWidth}' : '400',
    );
    _heightController = TextEditingController(
      text: p != null ? '${p.targetHeight}' : '500',
    );
    _maxKbController = TextEditingController(
      text: p != null ? '${p.maxFileSizeBytes ~/ 1024}' : '100',
    );
    _notesController = TextEditingController(text: p?.notes ?? '');
    _format = p?.format ?? OutputFormat.jpg;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _maxKbController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    final w = int.tryParse(_widthController.text.trim());
    final h = int.tryParse(_heightController.text.trim());
    final kb = int.tryParse(_maxKbController.text.trim());

    if (name.isEmpty) {
      AppDialog.showError(
        context,
        title: 'Preset Name Required',
        message: 'Please provide a descriptive name for this preset.',
      );
      return;
    }

    if (w == null || h == null || w < 20 || h < 20) {
      AppDialog.showError(
        context,
        title: 'Invalid Dimensions',
        message: 'Width and height must be at least 20 pixels.',
      );
      return;
    }

    final maxBytes = (kb != null && kb > 0) ? kb * 1024 : 100 * 1024;
    final aspect = w / h;

    final preset = PresetItem(
      id:
          widget.existing?.id ??
          'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      category: 'Custom',
      targetWidth: w,
      targetHeight: h,
      aspectRatio: aspect,
      format: _format,
      maxFileSizeBytes: maxBytes,
      notes:
          _notesController.text.trim().isNotEmpty
              ? _notesController.text.trim()
              : null,
      isSystemPreset: false,
    );

    widget.onSave(preset);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: GlassSurface(
          borderRadius: AppSpacing.radiusXl,
          padding: const EdgeInsets.all(22),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                    Text(
                      widget.existing == null
                          ? 'Add Custom Preset'
                          : 'Edit Preset',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color:
                            isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Preset Name',
                        hintText: 'e.g. Bank Exam Photo',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _widthController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Width (px)',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _heightController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Height (px)',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _maxKbController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Max File Size (KB)',
                        suffixText: 'KB',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<OutputFormat>(
                      value: _format,
                      decoration: const InputDecoration(labelText: 'Format'),
                      items:
                          OutputFormat.values.map((f) {
                            return DropdownMenuItem(
                              value: f,
                              child: Text(f.label),
                            );
                          }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _format = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes (Optional)',
                        hintText: 'e.g. White background required',
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: AppButton(
                            label: 'Save Preset',
                            onPressed: _submit,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
  }
}
