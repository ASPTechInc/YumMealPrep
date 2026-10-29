import 'package:flutter/material.dart';

import 'package:yummealprep/app_services.dart';
import 'package:yummealprep/data/catalogue_repository.dart';
import 'package:yummealprep/models/catalogue_item.dart';
import 'package:yummealprep/models/meal_type.dart';
import 'package:yummealprep/screens/browse/category_screen.dart';
import 'package:yummealprep/screens/navigation.dart';
import 'package:yummealprep/screens/settings/app_drawer.dart';
import 'package:yummealprep/widgets/item_image.dart';

/// Whether a screen is showing meals or recipes.
enum CatalogueKind {
  meals('Meals', 'meal', Icons.restaurant),
  recipes('Recipes', 'recipe', Icons.menu_book);

  const CatalogueKind(this.label, this.singular, this.icon);

  final String label;
  final String singular;
  final IconData icon;
}

/// The six categories as picture cards, for meals or for recipes.
class BrowseScreen extends StatefulWidget {
  const BrowseScreen({super.key});

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  CatalogueKind _kind = CatalogueKind.meals;

  // One stream per collection feeds every count badge.
  late final Stream<List<CatalogueItem>> _meals = AppScope.of(
    context,
  ).meals.watchAll();
  late final Stream<List<CatalogueItem>> _recipes = AppScope.of(
    context,
  ).recipes.watchAll();

  Future<void> _add() => switch (_kind) {
    CatalogueKind.meals => openMealForm(context),
    CatalogueKind.recipes => openRecipeForm(context),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Browse'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SegmentedButton<CatalogueKind>(
              segments: [
                for (final kind in CatalogueKind.values)
                  ButtonSegment(
                    value: kind,
                    label: Text(kind.label),
                    icon: Icon(kind.icon),
                  ),
              ],
              selected: {_kind},
              onSelectionChanged: (selection) =>
                  setState(() => _kind = selection.single),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        // Tabs stay mounted side by side, so their buttons must not share
        // the default hero tag.
        heroTag: null,
        onPressed: _add,
        icon: const Icon(Icons.add),
        label: Text('Add ${_kind.singular}'),
      ),
      body: StreamBuilder<List<CatalogueItem>>(
        // A key per kind so switching does not briefly show the other
        // collection's counts.
        key: ValueKey(_kind),
        stream: _kind == CatalogueKind.meals ? _meals : _recipes,
        builder: (context, snapshot) {
          final counts = snapshot.hasData
              ? countByType(snapshot.data!)
              : const <MealType, int>{};
          return GridView.extent(
            maxCrossAxisExtent: 240,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: [
              for (final type in MealType.values)
                _CategoryCard(
                  type: type,
                  count: counts[type],
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) =>
                          CategoryScreen(kind: _kind, type: type),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.type,
    required this.count,
    required this.onTap,
  });

  final MealType type;
  final int? count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ItemImage(source: type.image, width: 240),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black87],
                  stops: [0.4, 1],
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Row(
                children: [
                  Icon(type.icon, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      type.label,
                      style: textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (count != null)
                    Badge(
                      label: Text('$count'),
                      backgroundColor: type.colour,
                      textColor: Colors.white,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
