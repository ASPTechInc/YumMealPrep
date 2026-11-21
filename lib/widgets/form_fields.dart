// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:file_picker/file_picker.dart';

// Project imports:
import 'package:yummealprep/app_services.dart';
import 'package:yummealprep/models/catalogue_item.dart';
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

  @override
  Widget build(BuildContext context) {
    return _PickManyField(
      label: 'Side dishes',
      hint: 'Search or add a side dish',
      // A meal can have sides that are not in the suggestions (typed in
      // earlier, or from a backup). They still need to be listed so they
      // can be unticked.
      options: {
        for (final side in {...options, ...selected}) side: side,
      },
      selected: selected,
      onChanged: onChanged,
      canAddNew: true,
    );
  }
}

/// A dropdown that opens a searchable list of meals or recipes, [items], to
/// link any number of by id.
///
/// Ids in [selectedIds] that are not in [items] (a deleted item, or one a
/// restored backup did not include) are not shown, and are kept as they
/// are when the selection changes.
class LinkedItemsField extends StatelessWidget {
  const LinkedItemsField({
    required this.label,
    required this.hint,
    required this.items,
    required this.selectedIds,
    required this.onChanged,
    super.key,
  });

  final String label;
  final String hint;
  final Iterable<CatalogueItem> items;
  final List<String> selectedIds;
  final ValueChanged<List<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    final names = {for (final item in items) item.id: item.name};
    final missing = selectedIds.where((id) => !names.containsKey(id));
    return _PickManyField(
      label: label,
      hint: hint,
      options: names,
      selected: selectedIds.where(names.containsKey).toList(),
      onChanged: (ids) => onChanged([...missing, ...ids]),
    );
  }
}

/// Picks any number of [options], given as value to label, shown as chips
/// in a field that opens a searchable dialog.
class _PickManyField extends StatelessWidget {
  const _PickManyField({
    required this.label,
    required this.hint,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.canAddNew = false,
  });

  final String label;
  final String hint;
  final Map<String, String> options;
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  /// Whether typing a label that is not listed offers to add it, as its own
  /// value.
  final bool canAddNew;

  Future<void> _open(BuildContext context) async {
    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) => _PickManyDialog(
        title: label,
        hint: hint,
        options: options,
        selected: selected,
        canAddNew: canAddNew,
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
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.arrow_drop_down),
        ),
        child: selected.isEmpty
            ? null
            : Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final value in selected)
                    InputChip(
                      label: Text(options[value] ?? value),
                      onDeleted: () => onChanged(
                        selected.where((other) => other != value).toList(),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class _PickManyDialog extends StatefulWidget {
  const _PickManyDialog({
    required this.title,
    required this.hint,
    required this.options,
    required this.selected,
    required this.canAddNew,
  });

  final String title;
  final String hint;
  final Map<String, String> options;
  final List<String> selected;
  final bool canAddNew;

  @override
  State<_PickManyDialog> createState() => _PickManyDialogState();
}

class _PickManyDialogState extends State<_PickManyDialog> {
  late final Map<String, String> _labels = {...widget.options};
  late final List<String> _options = _labels.keys.toList()..sort(_byLabel);

  // Ticks change a copy, so Cancel leaves the item as it was.
  late final List<String> _selected = [...widget.selected];
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  int _byLabel(String a, String b) => _byName(_labels[a]!, _labels[b]!);

  void _toggle(String value) => setState(() {
    _selected.contains(value) ? _selected.remove(value) : _selected.add(value);
  });

  void _add(String label) => setState(() {
    _labels[label] = label;
    _options
      ..add(label)
      ..sort(_byLabel);
    _selected.add(label);
    _search.clear();
  });

  @override
  Widget build(BuildContext context) {
    final text = _search.text.trim();
    final query = text.toLowerCase();
    final matches = _options
        .where((value) => _labels[value]!.toLowerCase().contains(query))
        .toList();
    // Only offer to add a name that is not already listed, whatever its
    // case, so "coleslaw" does not end up beside "Coleslaw".
    final canAdd =
        widget.canAddNew &&
        text.isNotEmpty &&
        !_labels.values.any((label) => label.toLowerCase() == query);
    return AlertDialog(
      title: Text(widget.title),
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
                decoration: InputDecoration(
                  hintText: widget.hint,
                  prefixIcon: const Icon(Icons.search),
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
                  for (final value in matches)
                    CheckboxListTile(
                      title: Text(_labels[value]!),
                      value: _selected.contains(value),
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (_) => _toggle(value),
                    ),
                  if (matches.isEmpty && !canAdd)
                    const ListTile(title: Text('Nothing found')),
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
