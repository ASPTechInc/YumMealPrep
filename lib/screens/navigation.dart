import 'package:flutter/material.dart';

import 'package:yummealprep/models/meal.dart';
import 'package:yummealprep/models/meal_type.dart';
import 'package:yummealprep/models/recipe.dart';
import 'package:yummealprep/screens/meals/meal_details_screen.dart';
import 'package:yummealprep/screens/meals/meal_form_screen.dart';
import 'package:yummealprep/screens/recipes/recipe_details_screen.dart';
import 'package:yummealprep/screens/recipes/recipe_form_screen.dart';

Future<void> openMeal(BuildContext context, String mealId) =>
    _push<void>(context, MealDetailsScreen(mealId: mealId));

Future<void> openRecipe(BuildContext context, String recipeId) =>
    _push<void>(context, RecipeDetailsScreen(recipeId: recipeId));

/// Opens the meal form to add a meal, or to edit [meal]. Completes with the
/// id of the saved meal, or `null` if the form was closed without saving.
Future<String?> openMealForm(
  BuildContext context, {
  Meal? meal,
  MealType? type,
}) => _push<String>(
  context,
  MealFormScreen(meal: meal, initialType: type),
  fullscreenDialog: true,
);

/// Opens the recipe form to add a recipe, or to edit [recipe].
Future<String?> openRecipeForm(
  BuildContext context, {
  Recipe? recipe,
  MealType? type,
}) => _push<String>(
  context,
  RecipeFormScreen(recipe: recipe, initialType: type),
  fullscreenDialog: true,
);

Future<T?> _push<T>(
  BuildContext context,
  Widget screen, {
  bool fullscreenDialog = false,
}) => Navigator.of(context).push<T>(
  MaterialPageRoute(
    builder: (context) => screen,
    fullscreenDialog: fullscreenDialog,
  ),
);
