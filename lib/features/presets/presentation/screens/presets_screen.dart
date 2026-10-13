import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../app/providers.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/glass_surface.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/glass_app_bar.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../photo_editor/presentation/screens/photo_setup_screen.dart';
import '../../domain/models/preset_item.dart';
import 'preset_form_dialog.dart';

class PresetsScreen extends ConsumerWidget {
  const PresetsScreen({super.key});

  Future<void> _pickImageWithPreset(
    BuildContext context,
    PresetItem preset,
  ) async {
    try {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;

      if (!context.mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder:
              (context) => PhotoSetupScreen(
                imagePath: picked.path,
                isSignature: preset.category == 'Signature',
              ),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        AppDialog.showError(
          context,
          title: 'Photo Selection Failed',
          message: 'Could not access the selected photo.',
          technicalDetails: e.toString(),
        );
      }
    }
  }

  void _openPresetDialog(
    BuildContext context,
    WidgetRef ref, [
    PresetItem? existing,
  ]) {
    showDialog(
      context: context,
      builder:
          (ctx) => PresetFormDialog(
            existing: existing,
            onSave: (preset) {
              ref.read(presetsControllerProvider.notifier).savePreset(preset);
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presets = ref.watch(presetsControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: const GlassAppBar(title: 'Form Presets'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openPresetDialog(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'New Preset',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppColors.accentIndigo,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
          children: [
            // Disclaimer Banner
            GlassSurface(
              borderRadius: AppSpacing.radiusMd,
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: AppColors.accentBlue,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Examples only. Always verify exact portal requirements before submitting.',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Presets List
            ...presets.map((preset) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GlassSurface(
                  borderRadius: AppSpacing.radiusLg,
                  padding: const EdgeInsets.all(16),
                  onTap: () => _pickImageWithPreset(context, preset),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              preset.name,
                              style: TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w700,
                                color:
                                    isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.lightTextPrimary,
                              ),
                            ),
                          ),
                          if (!preset.isSystemPreset) ...[
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              onPressed:
                                  () => _openPresetDialog(context, ref, preset),
                              tooltip: 'Edit Preset',
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                size: 18,
                                color: AppColors.error,
                              ),
                              onPressed: () async {
                                final confirmed = await AppDialog.showConfirmation(
                                  context,
                                  title: 'Delete Preset?',
                                  message:
                                      'Are you sure you want to remove "${preset.name}"?',
                                  confirmText: 'Delete',
                                  isDestructive: true,
                                );
                                if (confirmed) {
                                  ref
                                      .read(presetsControllerProvider.notifier)
                                      .deletePreset(preset.id);
                                }
                              },
                              tooltip: 'Delete Preset',
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          StatusBadge(
                            label: Formatters.formatDimensions(
                              preset.targetWidth,
                              preset.targetHeight,
                            ),
                            type: StatusBadgeType.primary,
                          ),
                          const SizedBox(width: 8),
                          StatusBadge(
                            label: '< ${preset.maxFileSizeBytes ~/ 1024} KB',
                            type: StatusBadgeType.success,
                          ),
                          const SizedBox(width: 8),
                          StatusBadge(
                            label: preset.format.label,
                            type: StatusBadgeType.neutral,
                          ),
                        ],
                      ),
                      if (preset.notes != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          preset.notes!,
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
