import 'package:yummealprep/models/meal_type.dart';

/// What meals and recipes have in common, so lists, search, favourites and
/// storage can treat them the same way.
abstract interface class CatalogueItem {
  String get id;
  String get name;
  MealType get type;
  String get description;
  String? get image;
  bool get isFavourite;

  /// The text searched when looking for this item.
  Iterable<String> get searchableText;

  /// Every image this item refers to, so pictures the app saved can be
  /// cleaned up when they are no longer used.
  Iterable<String> get imageSources;

  Map<String, Object?> toMap();
}
