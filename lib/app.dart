import 'package:flutter/material.dart';

import 'package:yummealprep/app_services.dart';
import 'package:yummealprep/screens/home_shell.dart';
import 'package:yummealprep/themes/themes.dart';
import 'package:yummealprep/utils/constants.dart';

class YumMealPrepApp extends StatelessWidget {
  const YumMealPrepApp({required this.services, super.key});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      services: services,
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: services.settings.themeMode,
        builder: (context, themeMode, child) => MaterialApp(
          title: Constants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          home: const HomeShell(),
        ),
      ),
    );
  }
}

/// Shown instead of the app if its data cannot be opened.
class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp({required this.error, super.key});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: Constants.appName,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 16),
                const Text(
                  '${Constants.appName} could not open its data.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                SelectableText('$error', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                const SelectableText(
                  'Please report this at ${Constants.issuesUrl}',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
