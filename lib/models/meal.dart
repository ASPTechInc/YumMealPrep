import 'package:flutter/foundation.dart';

import 'package:yummealprep/models/catalogue_item.dart';
import 'package:yummealprep/models/meal_type.dart';
import 'package:yummealprep/models/model_helpers.dart';

/// A meal that can be planned for a day, such as "Pelau with coleslaw".
@immutable
class Meal implements CatalogueItem {
  const Meal({
    required this.id,
    required this.name,
    required this.type,
    this.description = '',
    this.drink = '',
    this.sideDishes = const [],
    this.image,
    this.nutritionFactImages = const [],
    this.isFavourite = false,
  });

  /// Reads a stored record. The [id] is the record key, so it is not part
  /// of [map].
  factory Meal.fromMap(String id, Map<String, Object?> map) => Meal(
    id: id,
    name: readString(map['name']),
    type: MealType.parse(map['type']),
    description: readString(map['description']),
    drink: readString(map['drink']),
    sideDishes: readStrings(map['sideDishes']),
    image: readOptionalString(map['image']),
    nutritionFactImages: readStrings(map['nutritionFactImages']),
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
  final String drink;
  final List<String> sideDishes;

  /// An image source understood by `ItemImage`: a bundled asset path, a
  /// picture saved by the app, or `null` for the placeholder.
  @override
  final String? image;

  /// Photos of nutrition labels for the meal's items.
  final List<String> nutritionFactImages;
  @override
  final bool isFavourite;

  /// The text searched when looking for this meal.
  @override
  Iterable<String> get searchableText => [
    name,
    type.label,
    description,
    drink,
    ...sideDishes,
  ];

  Meal copyWith({
    String? name,
    MealType? type,
    String? description,
    String? drink,
    List<String>? sideDishes,
    String? Function()? image,
    List<String>? nutritionFactImages,
    bool? isFavourite,
  }) => Meal(
    id: id,
    name: name ?? this.name,
    type: type ?? this.type,
    description: description ?? this.description,
    drink: drink ?? this.drink,
    sideDishes: sideDishes ?? this.sideDishes,
    image: image != null ? image() : this.image,
    nutritionFactImages: nutritionFactImages ?? this.nutritionFactImages,
    isFavourite: isFavourite ?? this.isFavourite,
  );

  @override
  Iterable<String> get imageSources => [?image, ...nutritionFactImages];

  @override
  Map<String, Object?> toMap() => {
    'name': name,
    'type': type.name,
    'description': description,
    'drink': drink,
    'sideDishes': sideDishes,
    'image': image,
    'nutritionFactImages': nutritionFactImages,
    'isFavourite': isFavourite,
  };

  @override
  bool operator ==(Object other) =>
      other is Meal &&
      other.id == id &&
      other.name == name &&
      other.type == type &&
      other.description == description &&
      other.drink == drink &&
      listEquals(other.sideDishes, sideDishes) &&
      other.image == image &&
      listEquals(other.nutritionFactImages, nutritionFactImages) &&
      other.isFavourite == isFavourite;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    type,
    description,
    drink,
    Object.hashAll(sideDishes),
    image,
    Object.hashAll(nutritionFactImages),
    isFavourite,
  );

  @override
  String toString() => 'Meal($id, $name)';
}
