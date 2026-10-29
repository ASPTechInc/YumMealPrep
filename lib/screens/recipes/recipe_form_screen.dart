import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:yummealprep/app_services.dart';
import 'package:yummealprep/models/meal_type.dart';
import 'package:yummealprep/models/recipe.dart';
import 'package:yummealprep/utils/ids.dart';
import 'package:yummealprep/utils/search.dart';
import 'package:yummealprep/utils/ui.dart';
import 'package:yummealprep/widgets/form_fields.dart';

/// Adds a new recipe, or edits [recipe].
class RecipeFormScreen extends StatefulWidget {
  const RecipeFormScreen({this.recipe, this.initialType, super.key});

  final Recipe? recipe;
  final MealType? initialType;

  @override
  State<RecipeFormScreen> createState() => _RecipeFormScreenState();
}

class _RecipeFormScreenState extends State<RecipeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final AppServices _services = AppScope.of(context);

  late final _name = TextEditingController(text: widget.recipe?.name);
  late final _description = TextEditingController(
    text: widget.recipe?.description,
  );
  // One ingredient or step per line, which is easier to type and edit than
  // the old "end each one with a full stop" rule.
  late final _ingredients = TextEditingController(
    text: widget.recipe?.ingredients.join('\n'),
  );
  late final _instructions = TextEditingController(
    text: widget.recipe?.instructions.join('\n'),
  );
  late final _preparation = TextEditingController(
    text: widget.recipe?.preparationMinutes?.toString(),
  );
  late final _cooking = TextEditingController(
    text: widget.recipe?.cookingMinutes?.toString(),
  );
  late final _servings = TextEditingController(
    text: widget.recipe?.servings?.toString(),
  );

  late MealType _type =
      widget.recipe?.type ?? widget.initialType ?? MealType.lunch;
  late bool _isSideDish = widget.recipe?.isSideDish ?? false;
  late String? _image = widget.recipe?.image;

  /// Pictures picked while the form is open, deleted again if unused.
  final Set<String> _pickedImages = {};
  bool _hasChanges = false;
  bool _saving = false;

  bool get _isNew => widget.recipe == null;

  @override
  void dispose() {
    for (final controller in [
      _name,
      _description,
      _ingredients,
      _instructions,
      _preparation,
      _cooking,
      _servings,
    ]) {
      controller.dispose();
    }
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

  void _discardPickedImages({Set<String> keep = const {}}) {
    // Only deleted if nothing uses them: a picked photo may already belong
    // to another meal or recipe.
    unawaited(_services.deleteUnusedImages(_pickedImages.difference(keep)));
  }

  static int? _number(TextEditingController controller) =>
      int.tryParse(controller.text.trim());

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final recipe = Recipe(
      id: widget.recipe?.id ?? newId(),
      name: _name.text.trim(),
      type: _type,
      description: _description.text.trim(),
      ingredients: List.unmodifiable(splitLines(_ingredients.text)),
      instructions: List.unmodifiable(splitLines(_instructions.text)),
      preparationMinutes: _number(_preparation),
      cookingMinutes: _number(_cooking),
      servings: _number(_servings),
      image: _image,
      isSideDish: _isSideDish,
      isFavourite: widget.recipe?.isFavourite ?? false,
    );
    try {
      await _services.recipes.save(recipe);
      _discardPickedImages(keep: recipe.imageSources.toSet());
      if (!mounted) return;
      showMessage(context, _isNew ? 'Recipe added' : 'Recipe saved');
      Navigator.pop(context, recipe.id);
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      showMessage(context, 'The recipe could not be saved: $error');
    }
  }

  Widget _numberField(
    TextEditingController controller,
    String label, {
    String? suffix,
    int max = 10000,
  }) => TextFormField(
    controller: controller,
    keyboardType: TextInputType.number,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    textInputAction: TextInputAction.next,
    decoration: InputDecoration(labelText: label, suffixText: suffix),
    validator: (value) => optionalWholeNumber(value, max: max),
  );

  @override
  Widget build(BuildContext context) {
    return UnsavedChangesGuard(
      hasChanges: _hasChanges,
      onDiscard: _discardPickedImages,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isNew ? 'Add recipe' : 'Edit recipe'),
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
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Side dish'),
                subtitle: const Text('Served alongside a main meal'),
                value: _isSideDish,
                onChanged: (value) => setState(() {
                  _isSideDish = value;
                  _hasChanges = true;
                }),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _description,
                minLines: 2,
                maxLines: 6,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _numberField(
                      _preparation,
                      'Preparation',
                      suffix: 'min',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _numberField(_cooking, 'Cooking', suffix: 'min'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: _numberField(_servings, 'Serves', max: 100)),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ingredients,
                minLines: 4,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Ingredients',
                  helperText: 'One ingredient per line',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _instructions,
                minLines: 4,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Method',
                  helperText: 'One step per line, in order',
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
