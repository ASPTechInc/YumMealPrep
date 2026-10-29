import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'package:yummealprep/app_services.dart';
import 'package:yummealprep/models/meal_type.dart';
import 'package:yummealprep/services/image_processing.dart';
import 'package:yummealprep/utils/ui.dart';
import 'package:yummealprep/widgets/item_image.dart';

/// Asks for a picture and saves a copy in the app's own storage, shrunk to
/// at most [maxImageSide] pixels as a JPEG without its metadata (see
/// [prepareImage]). Returns the new image source, or `null` if nothing was
/// picked.
Future<String?> pickAndSaveImage(BuildContext context) async {
  final images = AppScope.of(context).images;
  try {
    final file = await FilePicker.pickFile(type: FileType.image);
    if (file == null) return null;
    final prepared = await prepareImage(
      await file.readAsBytes(),
      extension: file.extension ?? 'jpg',
    );
    return await images.save(prepared.bytes, extension: prepared.extension);
  } on Exception {
    if (context.mounted) {
      showMessage(context, 'That picture could not be added.');
    }
    return null;
  }
}

/// A picture with buttons to choose a new one or remove it.
class ImageField extends StatelessWidget {
  const ImageField({
    required this.source,
    required this.onPick,
    required this.onRemove,
    super.key,
  });

  final String? source;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: ItemImage(
            source: source,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            FilledButton.tonalIcon(
              onPressed: onPick,
              icon: const Icon(Icons.photo_library),
              label: Text(source == null ? 'Add picture' : 'Change picture'),
            ),
            if (source != null)
              TextButton.icon(
                onPressed: onRemove,
                icon: const Icon(Icons.hide_image),
                label: const Text('Remove picture'),
              ),
          ],
        ),
      ],
    );
  }
}

class MealTypeField extends StatelessWidget {
  const MealTypeField({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final MealType value;
  final ValueChanged<MealType> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<MealType>(
      initialValue: value,
      decoration: const InputDecoration(labelText: 'Type'),
      items: [
        for (final type in MealType.values)
          DropdownMenuItem(
            value: type,
            child: Row(
              children: [
                Icon(type.icon, color: type.colour),
                const SizedBox(width: 12),
                Text(type.label),
              ],
            ),
          ),
      ],
      onChanged: (type) {
        if (type != null) onChanged(type);
      },
    );
  }
}

/// Wraps a form so leaving it with unsaved changes asks first.
class UnsavedChangesGuard extends StatelessWidget {
  const UnsavedChangesGuard({
    required this.hasChanges,
    required this.onDiscard,
    required this.child,
    super.key,
  });

  final bool hasChanges;
  final VoidCallback onDiscard;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: !hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final discard = await confirm(
          context,
          title: 'Discard changes?',
          message: 'Your changes have not been saved.',
          confirmLabel: 'Discard',
          destructive: true,
        );
        if (!discard || !context.mounted) return;
        onDiscard();
        Navigator.pop(context);
      },
      child: child,
    );
  }
}

String? requiredText(String? value, String field) =>
    value == null || value.trim().isEmpty ? '$field is required' : null;

/// Validates an optional whole number between [min] and [max].
String? optionalWholeNumber(String? value, {int min = 0, int max = 10000}) {
  if (value == null || value.trim().isEmpty) return null;
  final number = int.tryParse(value.trim());
  if (number == null) return 'Enter a whole number';
  if (number < min || number > max) return 'Enter a number from $min to $max';
  return null;
}
