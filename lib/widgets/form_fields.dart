// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:file_picker/file_picker.dart';

// Project imports:
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

/// A dropdown that opens a searchable list of [options] to pick any number
/// from. Typing a name that is not listed offers to add it.
class SideDishesField extends StatelessWidget {
  const SideDishesField({
    required this.options,
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final Iterable<String> options;
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  Future<void> _open(BuildContext context) async {
    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) => _SideDishesDialog(
        // A meal can have sides that are not in the suggestions (typed in
        // earlier, or from a backup). They still need to be listed so they
        // can be unticked.
        options: {...options, ...selected},
        selected: selected,
      ),
    );
    if (result != null) onChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    // Drawn with InputDecorator so it matches the Type dropdown above it.
    return InkWell(
      onTap: () => _open(context),
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        isEmpty: selected.isEmpty,
        decoration: const InputDecoration(
          labelText: 'Side dishes',
          suffixIcon: Icon(Icons.arrow_drop_down),
        ),
        child: selected.isEmpty
            ? null
            : Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final side in selected)
                    InputChip(
                      label: Text(side),
                      onDeleted: () => onChanged(
                        selected.where((other) => other != side).toList(),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class _SideDishesDialog extends StatefulWidget {
  const _SideDishesDialog({required this.options, required this.selected});

  final Set<String> options;
  final List<String> selected;

  @override
  State<_SideDishesDialog> createState() => _SideDishesDialogState();
}

class _SideDishesDialogState extends State<_SideDishesDialog> {
  late final List<String> _options = widget.options.toList()..sort(_byName);

  // Ticks change a copy, so Cancel leaves the meal as it was.
  late final List<String> _selected = [...widget.selected];
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _toggle(String side) => setState(() {
    _selected.contains(side) ? _selected.remove(side) : _selected.add(side);
  });

  void _add(String side) => setState(() {
    _options
      ..add(side)
      ..sort(_byName);
    _selected.add(side);
    _search.clear();
  });

  @override
  Widget build(BuildContext context) {
    final text = _search.text.trim();
    final query = text.toLowerCase();
    final matches = _options
        .where((side) => side.toLowerCase().contains(query))
        .toList();
    // Only offer to add a name that is not already listed, whatever its
    // case, so "coleslaw" does not end up beside "Coleslaw".
    final canAdd =
        text.isNotEmpty && !_options.any((side) => side.toLowerCase() == query);
    return AlertDialog(
      title: const Text('Side dishes'),
      contentPadding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
      content: SizedBox(
        width: 400,
        height: 480,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TextField(
                controller: _search,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  hintText: 'Search or add a side dish',
                  prefixIcon: Icon(Icons.search),
                  isDense: true,
                ),
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) {
                  if (canAdd) _add(text);
                },
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                children: [
                  if (canAdd)
                    ListTile(
                      leading: const Icon(Icons.add),
                      title: Text('Add "$text"'),
                      onTap: () => _add(text),
                    ),
                  for (final side in matches)
                    CheckboxListTile(
                      title: Text(side),
                      value: _selected.contains(side),
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (_) => _toggle(side),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _selected),
          child: const Text('Done'),
        ),
      ],
    );
  }
}

/// Same order as the meal and recipe lists (see `compareByName`).
int _byName(String a, String b) => a.toLowerCase().compareTo(b.toLowerCase());

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
