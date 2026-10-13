import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/providers.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/glass_surface.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/utils/file_utils.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/glass_app_bar.dart';
import '../../../presets/presentation/screens/presets_screen.dart';
import 'about_screen.dart';
import 'privacy_policy_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  int _cacheSize = 0;

  @override
  void initState() {
    super.initState();
    _loadCacheSize();
  }

  Future<void> _loadCacheSize() async {
    final size = await FileUtils.getCacheSize();
    if (mounted) {
      setState(() => _cacheSize = size);
    }
  }

  Future<void> _clearCache() async {
    await FileUtils.clearCache();
    await _loadCacheSize();
    if (mounted) {
      final strings = ref.read(appStringsProvider);
      AppDialog.showSuccess(
        context,
        title: strings.cacheCleared,
        message: 'Temporary processing files have been safely removed.',
        buttonText: 'OK',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsControllerProvider);
    final strings = ref.watch(appStringsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: GlassAppBar(title: strings.navSettings, showBackButton: false),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          children: [
            // Local-First Guarantee Callout
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color:
                    isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: isDark ? Colors.white10 : const Color(0xFFBFDBFE),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.shield_rounded,
                    color: AppColors.accentBlue,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      strings.localFirstNotice,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color:
                            isDark
                                ? AppColors.darkTextPrimary
                                : const Color(0xFF1E3A8A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Section 1: Appearance
            _SectionTitle(title: strings.appearance),
            const SizedBox(height: 8),
            GlassSurface(
              borderRadius: AppSpacing.radiusLg,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                children: [
                  _SettingsRadioTile<ThemeMode>(
                    title: 'System Default',
                    value: ThemeMode.system,
                    groupValue: settings.themeMode,
                    icon: Icons.brightness_auto_rounded,
                    onChanged: (mode) {
                      if (mode != null) {
                        ref
                            .read(settingsControllerProvider.notifier)
                            .setThemeMode(mode);
                      }
                    },
                  ),
                  const Divider(height: 1),
                  _SettingsRadioTile<ThemeMode>(
                    title: 'Light Theme',
                    value: ThemeMode.light,
                    groupValue: settings.themeMode,
                    icon: Icons.light_mode_rounded,
                    onChanged: (mode) {
                      if (mode != null) {
                        ref
                            .read(settingsControllerProvider.notifier)
                            .setThemeMode(mode);
                      }
                    },
                  ),
                  const Divider(height: 1),
                  _SettingsRadioTile<ThemeMode>(
                    title: 'Dark Theme',
                    value: ThemeMode.dark,
                    groupValue: settings.themeMode,
                    icon: Icons.dark_mode_rounded,
                    onChanged: (mode) {
                      if (mode != null) {
                        ref
                            .read(settingsControllerProvider.notifier)
                            .setThemeMode(mode);
                      }
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Section 2: Language
            _SectionTitle(title: strings.languageTitle),
            const SizedBox(height: 8),
            GlassSurface(
              borderRadius: AppSpacing.radiusLg,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                children: [
                  _SettingsRadioTile<AppLanguage>(
                    title: AppLanguage.english.displayName,
                    value: AppLanguage.english,
                    groupValue: settings.language,
                    icon: Icons.language_rounded,
                    onChanged: (lang) {
                      if (lang != null) {
                        ref
                            .read(settingsControllerProvider.notifier)
                            .setLanguage(lang);
                      }
                    },
                  ),
                  const Divider(height: 1),
                  _SettingsRadioTile<AppLanguage>(
                    title: AppLanguage.hindi.displayName,
                    value: AppLanguage.hindi,
                    groupValue: settings.language,
                    icon: Icons.translate_rounded,
                    onChanged: (lang) {
                      if (lang != null) {
                        ref
                            .read(settingsControllerProvider.notifier)
                            .setLanguage(lang);
                      }
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Section 3: Presets & Tools Management
            _SectionTitle(title: 'Presets & Templates'),
            const SizedBox(height: 8),
            GlassSurface(
              borderRadius: AppSpacing.radiusLg,
              padding: const EdgeInsets.all(4),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accentIndigo.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: const Icon(
                    Icons.bookmark_border_rounded,
                    color: AppColors.accentIndigo,
                    size: 20,
                  ),
                ),
                title: const Text(
                  'Manage Form Presets',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Add, edit, or customize upload dimensions',
                  style: TextStyle(fontSize: 12),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const PresetsScreen(),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // Section 4: Storage & Cache
            _SectionTitle(title: 'Storage & Cache'),
            const SizedBox(height: 8),
            GlassSurface(
              borderRadius: AppSpacing.radiusLg,
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Temporary Workspace',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Cached size: ${Formatters.formatBytes(_cacheSize)}',
                        style: TextStyle(
                          fontSize: 12.5,
                          color:
                              isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                    onPressed: _cacheSize > 0 ? _clearCache : null,
                    icon: const Icon(Icons.cleaning_services_rounded, size: 16),
                    label: Text(strings.clearCache),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusSm,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Section 5: Legal & About
            _SectionTitle(title: 'Information'),
            const SizedBox(height: 8),
            GlassSurface(
              borderRadius: AppSpacing.radiusLg,
              padding: const EdgeInsets.all(4),
              child: Column(
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.successBg,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusSm,
                        ),
                      ),
                      child: const Icon(
                        Icons.privacy_tip_outlined,
                        color: AppColors.success,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      strings.privacyPolicy,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const PrivacyPolicyScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.infoBg,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusSm,
                        ),
                      ),
                      child: const Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.info,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      strings.aboutApp,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const AboutScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Text(
      title,
      style: TextStyle(
        fontSize: 14.5,
        fontWeight: FontWeight.w700,
        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
      ),
    );
  }
}

class _SettingsRadioTile<T> extends StatelessWidget {
  final String title;
  final T value;
  final T groupValue;
  final IconData icon;
  final ValueChanged<T?> onChanged;

  const _SettingsRadioTile({
    required this.title,
    required this.value,
    required this.groupValue,
    required this.icon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;

    return InkWell(
      onTap: () => onChanged(value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? AppColors.accentIndigo : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.accentIndigo : null,
                ),
              ),
            ),
            Radio<T>(
              value: value,
              groupValue: groupValue,
              onChanged: onChanged,
              activeColor: AppColors.accentIndigo,
            ),
          ],
        ),
      ),
    );
  }
}
