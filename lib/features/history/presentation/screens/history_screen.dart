import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../app/providers.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/glass_surface.dart';
import '../../../../core/utils/file_utils.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/glass_app_bar.dart';
import '../../../../core/widgets/status_badge.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'All'; // 'All', 'Images', 'PDFs'

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(historyControllerProvider);
    final strings = ref.watch(appStringsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Filter items
    final filtered =
        history.where((item) {
          final matchesSearch =
              item.outputName.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ||
              item.sourceName.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              );

          final matchesType = switch (_selectedFilter) {
            'Images' => !item.operation.isPdf,
            'PDFs' => item.operation.isPdf,
            _ => true,
          };

          return matchesSearch && matchesType;
        }).toList();

    return Scaffold(
      appBar: GlassAppBar(
        title: strings.navMyFiles,
        showBackButton: false,
        actions: [
          if (history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Clear History',
              onPressed: () async {
                final confirmed = await AppDialog.showConfirmation(
                  context,
                  title: strings.confirmTitle,
                  message: strings.confirmClearHistory,
                  confirmText: 'Clear',
                  isDestructive: true,
                );
                if (confirmed) {
                  ref
                      .read(historyControllerProvider.notifier)
                      .clearHistory(deleteFiles: true);
                }
              },
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search and Filter Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
              child: Column(
                children: [
                  TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: strings.search,
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children:
                        ['All', 'Images', 'PDFs'].map((f) {
                          final isSelected = _selectedFilter == f;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(f),
                              selected: isSelected,
                              onSelected: (sel) {
                                if (sel) setState(() => _selectedFilter = f);
                              },
                              labelStyle: TextStyle(
                                fontSize: 12.5,
                                fontWeight:
                                    isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                color:
                                    isSelected
                                        ? Colors.white
                                        : (isDark
                                            ? AppColors.darkTextPrimary
                                            : AppColors.lightTextPrimary),
                              ),
                              selectedColor: AppColors.accentIndigo,
                            ),
                          );
                        }).toList(),
                  ),
                ],
              ),
            ),

            // History List
            Expanded(
              child:
                  filtered.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.folder_open_rounded,
                              size: 48,
                              color: isDark ? Colors.white24 : Colors.black26,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              strings.noRecentFiles,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              strings.noRecentFilesDesc,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color:
                                    isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                      : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 6, 20, 100),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          final file = File(item.filePath);
                          final exists = file.existsSync();

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: GlassSurface(
                              borderRadius: AppSpacing.radiusLg,
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color:
                                          item.operation.isPdf
                                              ? AppColors.error.withValues(
                                                alpha: 0.12,
                                              )
                                              : AppColors.accentIndigo
                                                  .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusSm,
                                      ),
                                    ),
                                    child: Icon(
                                      item.operation.icon,
                                      color:
                                          item.operation.isPdf
                                              ? AppColors.error
                                              : AppColors.accentIndigo,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.outputName,
                                          style: TextStyle(
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.w700,
                                            color:
                                                isDark
                                                    ? AppColors.darkTextPrimary
                                                    : AppColors
                                                        .lightTextPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 4,
                                          children: [
                                            StatusBadge(
                                              label: Formatters.formatBytes(
                                                item.fileSizeBytes,
                                              ),
                                              type: StatusBadgeType.primary,
                                            ),
                                            StatusBadge(
                                              label: item.dimensionsOrPages,
                                              type: StatusBadgeType.neutral,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          Formatters.formatDate(item.timestamp),
                                          style: TextStyle(
                                            fontSize: 11,
                                            color:
                                                isDark
                                                    ? AppColors
                                                        .darkTextSecondary
                                                    : AppColors
                                                        .lightTextSecondary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    padding: const EdgeInsets.all(4),
                                    constraints: const BoxConstraints(
                                      minWidth: 32,
                                      minHeight: 32,
                                    ),
                                    icon: const Icon(
                                      Icons.share_outlined,
                                      size: 18,
                                    ),
                                    tooltip: 'Share',
                                    onPressed:
                                        exists
                                            ? () {
                                              Share.shareXFiles(
                                                [XFile(item.filePath)],
                                                text:
                                                    'Shared from SahiFile: ${item.outputName}',
                                              );
                                            }
                                            : null,
                                  ),
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    padding: const EdgeInsets.all(4),
                                    constraints: const BoxConstraints(
                                      minWidth: 32,
                                      minHeight: 32,
                                    ),
                                    icon: const Icon(
                                      Icons.save_alt_rounded,
                                      size: 18,
                                      color: AppColors.accentBlue,
                                    ),
                                    tooltip: item.operation.isPdf
                                        ? 'Save to Downloads'
                                        : 'Save to Gallery',
                                    onPressed:
                                        exists
                                            ? () async {
                                              if (item.operation.isPdf) {
                                                final path = await FileUtils.savePdfToDownloads(
                                                  item.filePath,
                                                  item.outputName,
                                                );
                                                if (!context.mounted) return;
                                                if (path != null) {
                                                  AppDialog.showSuccess(
                                                    context,
                                                    title: 'Saved to Downloads',
                                                    message: 'File saved to:\n$path',
                                                  );
                                                }
                                              } else {
                                                final ok = await FileUtils.saveImageToGallery(
                                                  item.filePath,
                                                );
                                                if (!context.mounted) return;
                                                if (ok) {
                                                  AppDialog.showSuccess(
                                                    context,
                                                    title: 'Saved to Gallery',
                                                    message: 'Photo saved to your device Gallery ("SahiFile" album).',
                                                  );
                                                }
                                              }
                                            }
                                            : null,
                                  ),
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    padding: const EdgeInsets.all(4),
                                    constraints: const BoxConstraints(
                                      minWidth: 32,
                                      minHeight: 32,
                                    ),
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      size: 18,
                                      color: AppColors.error,
                                    ),
                                    tooltip: 'Delete File',
                                    onPressed: () async {
                                      final confirmed =
                                          await AppDialog.showConfirmation(
                                            context,
                                            title: 'Delete App Copy?',
                                            message:
                                                'Delete "${item.outputName}" from FormMate\'s workspace?',
                                            confirmText: 'Delete',
                                            isDestructive: true,
                                          );
                                      if (confirmed) {
                                        ref
                                            .read(
                                              historyControllerProvider
                                                  .notifier,
                                            )
                                            .deleteItem(item.id);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
