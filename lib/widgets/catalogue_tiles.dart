import 'package:flutter/material.dart';

import 'package:yummealprep/models/catalogue_item.dart';
import 'package:yummealprep/models/meal.dart';
import 'package:yummealprep/models/recipe.dart';
import 'package:yummealprep/screens/navigation.dart';
import 'package:yummealprep/utils/ui.dart';
import 'package:yummealprep/widgets/item_image.dart';

/// A list row for a meal or recipe: picture, name, a short summary and a
/// heart if it is a favourite.
class CatalogueTile extends StatelessWidget {
  const CatalogueTile({
    required this.item,
    required this.summary,
    required this.onTap,
    super.key,
  });

  final CatalogueItem item;
  final String summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colours = Theme.of(context).colorScheme;
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: ItemImage(
        source: item.image,
        width: 64,
        height: 64,
        borderRadius: BorderRadius.circular(8),
      ),
      title: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(summary, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: item.isFavourite
          ? Icon(
              Icons.favorite,
              color: colours.error,
              semanticLabel: 'Favourite',
            )
          : null,
    );
  }
}

class MealTile extends StatelessWidget {
  const MealTile({required this.meal, super.key});

  final Meal meal;

  @override
  Widget build(BuildContext context) => CatalogueTile(
    item: meal,
    summary: mealSummary(meal),
    onTap: () => openMeal(context, meal.id),
  );
}

class RecipeTile extends StatelessWidget {
  const RecipeTile({required this.recipe, super.key});

  final Recipe recipe;

  @override
  Widget build(BuildContext context) => CatalogueTile(
    item: recipe,
    summary: recipeSummary(recipe),
    onTap: () => openRecipe(context, recipe.id),
  );
}

/// "Lunch · Sorrel · Coleslaw"
String mealSummary(Meal meal) => [
  meal.type.label,
  if (meal.drink.isNotEmpty) meal.drink,
  ...meal.sideDishes,
].join(' · ');

/// "Lunch · 25 min · Serves 4"
String recipeSummary(Recipe recipe) => [
  recipe.type.label,
  if (recipe.totalMinutes case final minutes? when minutes > 0)
    formatMinutes(minutes),
  if (recipe.servings case final servings?) 'Serves $servings',
].join(' · ');
