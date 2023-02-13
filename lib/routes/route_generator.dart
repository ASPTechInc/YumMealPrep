import 'package:flutter/material.dart';
import 'package:yummealprep/routes/route_paths.dart';
import 'package:yummealprep/screens/categories/categories_screen.dart';
import 'package:yummealprep/screens/favourites/favourites_screen.dart';
import 'package:yummealprep/screens/mealplanner/mealplanner_screen.dart';
import 'package:yummealprep/screens/meals/meals_screen.dart';
import 'package:yummealprep/screens/recipes/recipes_screen.dart';
import 'package:yummealprep/screens/search/search_screen.dart';
import 'package:yummealprep/screens/uploadDataToDB/upload_data_screen.dart';
import 'package:yummealprep/shared_widgets/bottom_navbar_widget.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case RoutePaths.bottomNavBar:
        return navigateTo(const BottomNavBar());

      case RoutePaths.categoriesScreen:
        return navigateTo(const CategoriesScreen());

      case RoutePaths.dataUploadScreen:
        return navigateTo(const DBDataUploadScreen());

      case RoutePaths.homeScreen:
        return navigateTo(const MealPlannerScreen());

      case RoutePaths.favouritesScreen:
        return navigateTo(const FavouritesScreen());

      case RoutePaths.mealsScreen:
        return navigateTo(const MealsScreen());

      case RoutePaths.recipesScreen:
        return navigateTo(const RecipesScreen());

      case RoutePaths.searchScreen:
        return navigateTo(const SearchScreen());

      default:
        return navigateTo(const BottomNavBar());
    }
  }

  static MaterialPageRoute navigateTo(Widget widget) =>
      MaterialPageRoute<dynamic>(builder: (context) => widget);
}
