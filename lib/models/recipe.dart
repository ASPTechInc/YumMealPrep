import 'package:flutter/foundation.dart';

import 'package:yummealprep/models/catalogue_item.dart';
import 'package:yummealprep/models/meal_type.dart';
import 'package:yummealprep/models/model_helpers.dart';

/// A recipe in the cook book, with its ingredients and method.
@immutable
class Recipe implements CatalogueItem {
  const Recipe({
    required this.id,
    required this.name,
    required this.type,
    this.description = '',
    this.ingredients = const [],
    this.instructions = const [],
    this.preparationMinutes,
    this.cookingMinutes,
    this.servings,
    this.image,
    this.isSideDish = false,
    this.isFavourite = false,
  });

  /// Reads a stored record. The [id] is the record key, so it is not part
  /// of [map].
  factory Recipe.fromMap(String id, Map<String, Object?> map) => Recipe(
    id: id,
    name: readString(map['name']),
    type: MealType.parse(map['type']),
    description: readString(map['description']),
    ingredients: readStrings(map['ingredients']),
    instructions: readStrings(map['instructions']),
    preparationMinutes: readInt(map['preparationMinutes']),
    cookingMinutes: readInt(map['cookingMinutes']),
    servings: readInt(map['servings']),
    image: readOptionalString(map['image']),
    isSideDish: readBool(map['isSideDish']),
    isFavourite: readBool(map['isFavourite']),
  );

  @override
  final String id;
  @override
  final String name;
  @override
  final MealType type;
  @override
  final String description;
  final List<String> ingredients;

  /// The method, in the order the steps are carried out.
  final List<String> instructions;
  final int? preparationMinutes;
  final int? cookingMinutes;
  final int? servings;

  /// An image source understood by `ItemImage`.
  @override
  final String? image;
  final bool isSideDish;
  @override
  final bool isFavourite;

  /// Preparation plus cooking time, or `null` if neither is known.
  int? get totalMinutes => preparationMinutes == null && cookingMinutes == null
      ? null
      : (preparationMinutes ?? 0) + (cookingMinutes ?? 0);

  /// The text searched when looking for this recipe.
  @override
  Iterable<String> get searchableText => [
    name,
    type.label,
    description,
    ...ingredients,
  ];

  Recipe copyWith({
    String? name,
    MealType? type,
    String? description,
    List<String>? ingredients,
    List<String>? instructions,
    int? Function()? preparationMinutes,
    int? Function()? cookingMinutes,
    int? Function()? servings,
    String? Function()? image,
    bool? isSideDish,
    bool? isFavourite,
  }) => Recipe(
    id: id,
    name: name ?? this.name,
    type: type ?? this.type,
    description: description ?? this.description,
    ingredients: ingredients ?? this.ingredients,
    instructions: instructions ?? this.instructions,
    preparationMinutes: preparationMinutes != null
        ? preparationMinutes()
        : this.preparationMinutes,
    cookingMinutes: cookingMinutes != null
        ? cookingMinutes()
        : this.cookingMinutes,
    servings: servings != null ? servings() : this.servings,
    image: image != null ? image() : this.image,
    isSideDish: isSideDish ?? this.isSideDish,
    isFavourite: isFavourite ?? this.isFavourite,
  );

  @override
  Iterable<String> get imageSources => [?image];

  @override
  Map<String, Object?> toMap() => {
    'name': name,
    'type': type.name,
    'description': description,
    'ingredients': ingredients,
    'instructions': instructions,
    'preparationMinutes': preparationMinutes,
    'cookingMinutes': cookingMinutes,
    'servings': servings,
    'image': image,
    'isSideDish': isSideDish,
    'isFavourite': isFavourite,
  };

  @override
  bool operator ==(Object other) =>
      other is Recipe &&
      other.id == id &&
      other.name == name &&
      other.type == type &&
      other.description == description &&
      listEquals(other.ingredients, ingredients) &&
      listEquals(other.instructions, instructions) &&
      other.preparationMinutes == preparationMinutes &&
      other.cookingMinutes == cookingMinutes &&
      other.servings == servings &&
      other.image == image &&
      other.isSideDish == isSideDish &&
      other.isFavourite == isFavourite;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    type,
    description,
    Object.hashAll(ingredients),
    Object.hashAll(instructions),
    preparationMinutes,
    cookingMinutes,
    servings,
    image,
    isSideDish,
    isFavourite,
  );

  @override
  String toString() => 'Recipe($id, $name)';
}
