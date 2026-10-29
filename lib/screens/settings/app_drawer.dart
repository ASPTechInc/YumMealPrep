import 'dart:async';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:yummealprep/app_services.dart';
import 'package:yummealprep/screens/navigation.dart';
import 'package:yummealprep/screens/settings/backup_actions.dart';
import 'package:yummealprep/screens/settings/text_document_screen.dart';
import 'package:yummealprep/utils/constants.dart';
import 'package:yummealprep/utils/ui.dart';

/// The side menu shared by the main tabs.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  /// Closes the drawer, then runs [action] with the screen's context. The
  /// drawer's own context is unmounted once it has closed.
  void _then(
    BuildContext context,
    Future<void> Function(BuildContext context) action,
  ) {
    final screenContext = Scaffold.of(context).context;
    Navigator.pop(context);
    unawaited(action(screenContext));
  }

  Future<void> _openDocument(
    BuildContext context,
    String title,
    String assetPath,
  ) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (context) =>
          TextDocumentScreen(title: title, assetPath: assetPath),
    ),
  );

  Future<void> _openLink(BuildContext context, String url) async {
    final opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && context.mounted) {
      showMessage(context, 'No app was found to open $url');
    }
  }

  Future<void> _showAbout(BuildContext context) async {
    final info = await PackageInfo.fromPlatform();
    if (!context.mounted) return;
    final year = DateTime.now().year;
    showAboutDialog(
      context: context,
      applicationName: Constants.appName,
      applicationVersion: 'Version ${info.version}',
      applicationIcon: Image.asset(Constants.appLogo, width: 48, height: 48),
      applicationLegalese:
          '© ${Constants.firstYear}–$year ${Constants.developer}\n'
          'Free and open-source software, released under the MIT licence.',
      children: const [
        SizedBox(height: 16),
        Text(
          'A meal planner and digital recipe book. Your meals, recipes and '
          'plans are stored only on this device. There are no accounts, '
          'adverts or tracking.',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return NavigationDrawer(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 16, 16),
          child: Row(
            children: [
              Image.asset(Constants.appLogo, width: 48, height: 48),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(Constants.appName, style: textTheme.titleLarge),
                    Text('Plan, cook, enjoy', style: textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
        ListTile(
          leading: const Icon(Icons.add),
          title: const Text('Add meal'),
          onTap: () => _then(context, openMealForm),
        ),
        ListTile(
          leading: const Icon(Icons.post_add),
          title: const Text('Add recipe'),
          onTap: () => _then(context, openRecipeForm),
        ),
        const Divider(indent: 16, endIndent: 16),
        const _ThemeSelector(),
        const Divider(indent: 16, endIndent: 16),
        ListTile(
          leading: const Icon(Icons.upload_file),
          title: const Text('Export data'),
          subtitle: const Text('Save everything to a .backup file'),
          onTap: () => _then(context, exportData),
        ),
        ListTile(
          leading: const Icon(Icons.download),
          title: const Text('Import data'),
          subtitle: const Text('Load a .backup file'),
          onTap: () => _then(context, importData),
        ),
        const Divider(indent: 16, endIndent: 16),
        ListTile(
          leading: const Icon(Icons.privacy_tip_outlined),
          title: const Text('Privacy policy'),
          onTap: () => _then(
            context,
            (context) => _openDocument(
              context,
              'Privacy policy',
              Constants.privacyPolicy,
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.new_releases_outlined),
          title: const Text("What's new"),
          onTap: () => _then(
            context,
            (context) =>
                _openDocument(context, "What's new", Constants.changelog),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.photo_camera_outlined),
          title: const Text('Photo credits'),
          onTap: () => _then(
            context,
            (context) =>
                _openDocument(context, 'Photo credits', Constants.photoCredits),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.code),
          title: const Text('Source code'),
          onTap: () => _openLink(context, Constants.sourceCodeUrl),
        ),
        ListTile(
          leading: const Icon(Icons.bug_report_outlined),
          title: const Text('Report a problem or idea'),
          onTap: () => _openLink(context, Constants.issuesUrl),
        ),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('About'),
          onTap: () => _showAbout(context),
        ),
      ],
    );
  }
}

class _ThemeSelector extends StatelessWidget {
  const _ThemeSelector();

  @override
  Widget build(BuildContext context) {
    final settings = AppScope.of(context).settings;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 8),
            child: Text('Theme', style: Theme.of(context).textTheme.titleSmall),
          ),
          ValueListenableBuilder<ThemeMode>(
            valueListenable: settings.themeMode,
            builder: (context, mode, child) => SegmentedButton<ThemeMode>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: ThemeMode.system, label: Text('System')),
                ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
              ],
              selected: {mode},
              onSelectionChanged: (selection) =>
                  unawaited(settings.setThemeMode(selection.single)),
            ),
          ),
        ],
      ),
    );
  }
}
