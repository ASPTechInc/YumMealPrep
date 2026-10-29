import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'package:yummealprep/app_services.dart';
import 'package:yummealprep/data/backup_service.dart';
import 'package:yummealprep/utils/ui.dart';

/// Exports all meals, recipes, the meal plan and added pictures to a
/// `.backup` file (plain JSON) the user chooses where to save.
Future<void> exportData(BuildContext context) async {
  final backup = AppScope.of(context).backup;
  try {
    final bytes = await backup.export();
    final saved = await FilePicker.saveFile(
      dialogTitle: 'Export data',
      fileName: backupFileName(DateTime.now()),
      bytes: bytes,
      // Not application/json: some Android file pickers would then add
      // ".json" to the name.
      mimeType: 'application/octet-stream',
    );
    if (saved != null && context.mounted) showMessage(context, 'Data exported');
  } on Exception catch (error) {
    if (context.mounted) {
      showMessage(context, 'The data could not be exported: $error');
    }
  }
}

/// The largest file Import data will read: room for well over a thousand
/// added photos at their saved size.
const int maxImportBytes = 512 * 1024 * 1024;

enum _ImportMode { merge, replaceAll }

/// Imports a `.backup` (or `.json`) file chosen by the user, after asking
/// whether to add to the current data or replace it.
Future<void> importData(BuildContext context) async {
  final backup = AppScope.of(context).backup;
  final mode = await showDialog<_ImportMode>(
    context: context,
    builder: (context) => const SimpleDialog(
      title: Text('Import data'),
      children: [
        _ModeOption(
          mode: _ImportMode.merge,
          icon: Icons.merge_type,
          title: 'Add to my data',
          description:
              'Adds everything in the file. Items in both are replaced by '
              'the copy in the file. Nothing is deleted.',
        ),
        _ModeOption(
          mode: _ImportMode.replaceAll,
          icon: Icons.published_with_changes,
          title: 'Replace everything',
          description:
              'Deletes all meals, recipes and planned meals, then loads the '
              'file. Use this after editing an exported file.',
        ),
      ],
    ),
  );
  if (mode == null || !context.mounted) return;
  if (mode == _ImportMode.replaceAll) {
    final sure = await confirm(
      context,
      title: 'Replace everything?',
      message:
          'Your current meals, recipes and meal plan will be deleted and '
          'replaced by the file. Consider exporting your data first.',
      confirmLabel: 'Choose file',
      destructive: true,
    );
    if (!sure) return;
  }
  try {
    final file = await FilePicker.pickFile(
      dialogTitle: 'Choose a .backup file',
      // Any file: Android and iOS pickers cannot filter by an extension
      // they do not know, such as .backup. The contents are checked
      // instead.
      type: FileType.any,
    );
    if (file == null) return;
    // Check the size before reading the whole file into memory, in case a
    // video or other large file was picked by mistake.
    final length = await file.length();
    if (length != null && length > maxImportBytes) {
      if (context.mounted) {
        showMessage(
          context,
          'That file is too large to be a YumMealPrep backup '
          '(${length ~/ (1024 * 1024)} MB).',
        );
      }
      return;
    }
    final summary = await backup.restore(
      await file.readAsBytes(),
      replaceAll: mode == _ImportMode.replaceAll,
    );
    if (context.mounted) showMessage(context, 'Imported $summary');
  } on BackupFormatException catch (error) {
    if (context.mounted) showMessage(context, error.message);
  } on Exception catch (error) {
    if (context.mounted) {
      showMessage(context, 'The file could not be imported: $error');
    }
  }
}

class _ModeOption extends StatelessWidget {
  const _ModeOption({
    required this.mode,
    required this.icon,
    required this.title,
    required this.description,
  });

  final _ImportMode mode;
  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => SimpleDialogOption(
    onPressed: () => Navigator.pop(context, mode),
    child: ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(description),
    ),
  );
}
