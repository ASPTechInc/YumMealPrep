import 'dart:async';

import 'package:flutter/material.dart';

import 'package:yummealprep/app_services.dart';
import 'package:yummealprep/models/meal.dart';
import 'package:yummealprep/models/meal_type.dart';
import 'package:yummealprep/utils/constants.dart';
import 'package:yummealprep/utils/ids.dart';
import 'package:yummealprep/utils/ui.dart';
import 'package:yummealprep/widgets/form_fields.dart';
import 'package:yummealprep/widgets/item_image.dart';

/// Adds a new meal, or edits [meal].
class MealFormScreen extends StatefulWidget {
  const MealFormScreen({this.meal, this.initialType, super.key});

  final Meal? meal;
  final MealType? initialType;

  @override
  State<MealFormScreen> createState() => _MealFormScreenState();
}

class _MealFormScreenState extends State<MealFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final AppServices _services = AppScope.of(context);

  late final TextEditingController _name = TextEditingController(
    text: widget.meal?.name,
  );
  late final TextEditingController _description = TextEditingController(
    text: widget.meal?.description,
  );
  late final TextEditingController _drink = TextEditingController(
    text: widget.meal?.drink,
  );
  final TextEditingController _otherSide = TextEditingController();

  late MealType _type =
      widget.meal?.type ?? widget.initialType ?? MealType.lunch;
  late final List<String> _sideDishes = [...?widget.meal?.sideDishes];
  late String? _image = widget.meal?.image;
  late final List<String> _nutritionFacts = [
    ...?widget.meal?.nutritionFactImages,
  ];

  /// Pictures picked while the form is open, deleted again if unused.
  final Set<String> _pickedImages = {};
  bool _hasChanges = false;
  bool _saving = false;

  bool get _isNew => widget.meal == null;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _drink.dispose();
    _otherSide.dispose();
    super.dispose();
  }

  void _changed() {
    if (!_hasChanges) setState(() => _hasChanges = true);
  }

  Future<void> _pickImage() async {
    final services = _services;
    final source = await pickAndSaveImage(context);
    if (source == null) return;
    if (!mounted) {
      // The form was closed while the picture was being prepared.
      unawaited(services.deleteUnusedImages([source]));
      return;
    }
    setState(() {
      _pickedImages.add(source);
      _image = source;
      _hasChanges = true;
    });
  }

  Future<void> _addNutritionFacts() async {
    final services = _services;
    final source = await pickAndSaveImage(context);
    if (source == null) return;
    if (!mounted) {
      // The form was closed while the picture was being prepared.
      unawaited(services.deleteUnusedImages([source]));
      return;
    }
    setState(() {
      _pickedImages.add(source);
      _nutritionFacts.add(source);
      _hasChanges = true;
    });
  }

  void _toggleSide(String side, {required bool selected}) {
    setState(() {
      selected ? _sideDishes.add(side) : _sideDishes.remove(side);
      _hasChanges = true;
    });
  }

  void _addOtherSide() {
    final side = _otherSide.text.trim();
    if (side.isEmpty) return;
    if (!_sideDishes.contains(side)) _toggleSide(side, selected: true);
    _otherSide.clear();
  }

  /// Deletes pictures picked in this form that are not in [keep].
  void _discardPickedImages({Set<String> keep = const {}}) {
    // Only deleted if nothing uses them: a picked photo may already belong
    // to another meal or recipe.
    unawaited(_services.deleteUnusedImages(_pickedImages.difference(keep)));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final meal = Meal(
      id: widget.meal?.id ?? newId(),
      name: _name.text.trim(),
      type: _type,
      description: _description.text.trim(),
      drink: _drink.text.trim(),
      sideDishes: List.unmodifiable(_sideDishes),
      image: _image,
      nutritionFactImages: List.unmodifiable(_nutritionFacts),
      isFavourite: widget.meal?.isFavourite ?? false,
    );
    try {
      await _services.meals.save(meal);
      _discardPickedImages(keep: meal.imageSources.toSet());
      if (!mounted) return;
      showMessage(context, _isNew ? 'Meal added' : 'Meal saved');
      Navigator.pop(context, meal.id);
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      showMessage(context, 'The meal could not be saved: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final sideChoices = {
      ...Constants.sideDishSuggestions,
      ..._sideDishes,
    }.toList()..sort();
    return UnsavedChangesGuard(
      hasChanges: _hasChanges,
      onDiscard: _discardPickedImages,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isNew ? 'Add meal' : 'Edit meal'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: const Text('Save'),
              ),
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          onChanged: _changed,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ImageField(
                source: _image,
                onPick: _pickImage,
                onRemove: () => setState(() {
                  _image = null;
                  _hasChanges = true;
                }),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                autofocus: _isNew,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Name *'),
                validator: (value) => requiredText(value, 'Name'),
              ),
              const SizedBox(height: 16),
              MealTypeField(
                value: _type,
                onChanged: (type) => setState(() {
                  _type = type;
                  _hasChanges = true;
                }),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _description,
                minLines: 3,
                maxLines: 8,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              _DrinkField(controller: _drink, onChanged: _changed),
              const SizedBox(height: 24),
              Text(
                'Side dishes',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final side in sideChoices)
                    FilterChip(
                      label: Text(side),
                      selected: _sideDishes.contains(side),
                      onSelected: (selected) =>
                          _toggleSide(side, selected: selected),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _otherSide,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Another side dish',
                  isDense: true,
                  suffixIcon: IconButton(
                    tooltip: 'Add side dish',
                    icon: const Icon(Icons.add),
                    onPressed: _addOtherSide,
                  ),
                ),
                onSubmitted: (_) => _addOtherSide(),
              ),
              const SizedBox(height: 24),
              Text(
                'Nutrition facts',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              const Text('Add photos of the nutrition labels.'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final source in _nutritionFacts)
                    Stack(
                      children: [
                        ItemImage(
                          source: source,
                          width: 90,
                          height: 120,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: IconButton.filledTonal(
                            visualDensity: VisualDensity.compact,
                            tooltip: 'Remove',
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: () => setState(() {
                              _nutritionFacts.remove(source);
                              _hasChanges = true;
                            }),
                          ),
                        ),
                      ],
                    ),
                  SizedBox(
                    width: 90,
                    height: 120,
                    child: OutlinedButton(
                      onPressed: _addNutritionFacts,
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Icon(Icons.add_photo_alternate),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A text field that suggests common drinks but accepts any text.
class _DrinkField extends StatefulWidget {
  const _DrinkField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  State<_DrinkField> createState() => _DrinkFieldState();
}

class _DrinkFieldState extends State<_DrinkField> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<String>(
      textEditingController: widget.controller,
      focusNode: _focusNode,
      optionsBuilder: (value) {
        final text = value.text.trim().toLowerCase();
        return Constants.drinkSuggestions.where(
          (drink) =>
              drink.toLowerCase().contains(text) && drink.toLowerCase() != text,
        );
      },
      onSelected: (_) => widget.onChanged(),
      fieldViewBuilder: (context, controller, focusNode, onSubmitted) =>
          TextFormField(
            controller: controller,
            focusNode: focusNode,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Drink'),
          ),
      optionsViewBuilder: (context, onSelected, options) => Align(
        alignment: Alignment.topLeft,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 240, maxWidth: 320),
            child: ListView(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              children: [
                for (final option in options)
                  ListTile(
                    title: Text(option),
                    onTap: () => onSelected(option),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
