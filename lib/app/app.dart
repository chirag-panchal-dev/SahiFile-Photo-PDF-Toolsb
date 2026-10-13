import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_constants.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/shell/presentation/app_shell_screen.dart';
import 'providers.dart';
import 'theme/app_theme.dart';

class SahiFileApp extends ConsumerWidget {
  const SahiFileApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      themeMode: settings.themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home:
          settings.onboardingCompleted
              ? const AppShellScreen()
              : OnboardingScreen(
                onFinish: () {
                  // State update inside OnboardingScreen automatically causes rebuild
                },
              ),
    );
  }
}
