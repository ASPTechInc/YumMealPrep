import 'dart:async';

import 'package:flutter/material.dart';

import 'package:yummealprep/app_services.dart';
import 'package:yummealprep/data/catalogue_repository.dart';
import 'package:yummealprep/models/catalogue_item.dart';
import 'package:yummealprep/screens/settings/app_drawer.dart';
import 'package:yummealprep/widgets/catalogue_list.dart';

/// Favourite meals and recipes. Swipe a row away to unfavourite it.
class FavouritesScreen extends StatelessWidget {
  const FavouritesScreen({super.key});

  void _unfavourite(
    BuildContext context,
    CatalogueRepository<CatalogueItem> repository,
    CatalogueItem item,
  ) {
    unawaited(repository.setFavourite(item.id, favourite: false));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${item.name} removed from favourites'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () =>
                unawaited(repository.setFavourite(item.id, favourite: true)),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        drawer: const AppDrawer(),
        appBar: AppBar(
          title: const Text('Favourites'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Meals'),
              Tab(text: 'Recipes'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            MealList(
              favouritesOnly: true,
              emptyMessage: 'Tap the heart on a meal to add it here.',
              onRemove: (meal) => _unfavourite(context, services.meals, meal),
            ),
            RecipeList(
              favouritesOnly: true,
              emptyMessage: 'Tap the heart on a recipe to add it here.',
              onRemove: (recipe) =>
                  _unfavourite(context, services.recipes, recipe),
            ),
          ],
        ),
      ),
    );
  }
}
