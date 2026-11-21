// Dart imports:
import 'dart:async';

// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:yummealprep/app_services.dart';
import 'package:yummealprep/data/choice_list_repository.dart';
import 'package:yummealprep/models/meal.dart';
import 'package:yummealprep/models/meal_type.dart';
import 'package:yummealprep/screens/meals/manage_choices_screen.dart';
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
  // Subscribed once here rather than in StreamBuilders: the fields sit in a
  // lazy ListView, so scrolling or the keyboard closing rebuilds them, and
  // the database streams can only be listened to once.
  final List<StreamSubscription<List<String>>> _subscriptions = [];
  List<String> _drinkChoices = const [];
  List<String> _sideDishChoices = const [];

  late final TextEditingController _name = TextEditingController(
    text: widget.meal?.name,
  );
  late final TextEditingController _description = TextEditingController(
    text: widget.meal?.description,
  );
  late final TextEditingController _drink = TextEditingController(
    text: widget.meal?.drink,
  );

  late MealType _type =
      widget.meal?.type ?? widget.initialType ?? MealType.lunch;
  late List<String> _sideDishes = [...?widget.meal?.sideDishes];
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_subscriptions.isNotEmpty) return;
    _subscriptions.addAll([
      _services.drinks.watch().listen(
        (names) => setState(() => _drinkChoices = names),
      ),
      _services.sideDishes.watch().listen(
        (names) => setState(() => _sideDishChoices = names),
      ),
    ]);
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _name.dispose();
    _description.dispose();
    _drink.dispose();
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

  void _manage(ChoiceList list) => Navigator.of(context).push<void>(
    MaterialPageRoute(builder: (context) => ManageChoicesScreen(list: list)),
  );

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
            // Explicit padding replaces the system inset ListView would add
            // on its own, so add it back to keep the last field clear of
            // the navigation bar.
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              16 + MediaQuery.paddingOf(context).bottom,
            ),
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
              _DrinkField(
                controller: _drink,
                options: _drinkChoices,
                onChanged: _changed,
              ),
              _ManageButton(
                label: 'Manage drinks',
                onPressed: () => _manage(ChoiceList.drinks),
              ),
              const SizedBox(height: 16),
              SideDishesField(
                options: _sideDishChoices,
                selected: _sideDishes,
                onChanged: (sides) => setState(() {
                  _sideDishes = sides;
                  _hasChanges = true;
                }),
              ),
              _ManageButton(
                label: 'Manage side dishes',
                onPressed: () => _manage(ChoiceList.sideDishes),
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

/// Opens the screen for editing the names a field suggests.
class _ManageButton extends StatelessWidget {
  const _ManageButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.edit_note),
          label: Text(label),
        ),
      ),
    );
  }
}

/// A text field that suggests the drinks in [options] but accepts any text.
class _DrinkField extends StatefulWidget {
  const _DrinkField({
    required this.controller,
    required this.options,
    required this.onChanged,
  });

  final TextEditingController controller;
  final List<String> options;
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
        return widget.options.where(
          (drink) =>
              drink.toLowerCase().contains(text) && drink.toLowerCase() != text,
        );
      },
      onSelected: (_) => widget.onChanged(),
      fieldViewBuilder: (context, controller, focusNode, onSubmitted) =>
          TextFormField(
            controller: controller,
            focusNode: focusNode,
            // On phones a tap outside keeps the focus by default, which
            // leaves the suggestions open. Taps on the suggestions count as
            // inside the field, so picking one still works.
            onTapOutside: (_) => focusNode.unfocus(),
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
