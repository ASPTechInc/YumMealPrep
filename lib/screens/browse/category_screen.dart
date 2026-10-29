import 'package:flutter/material.dart';

import 'package:yummealprep/models/meal_type.dart';
import 'package:yummealprep/screens/browse/browse_screen.dart';
import 'package:yummealprep/screens/navigation.dart';
import 'package:yummealprep/widgets/catalogue_list.dart';
import 'package:yummealprep/widgets/item_image.dart';

/// The meals or recipes of one type, with a search box.
class CategoryScreen extends StatefulWidget {
  const CategoryScreen({required this.kind, required this.type, super.key});

  final CatalogueKind kind;
  final MealType type;

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final type = widget.type;
    final kind = widget.kind;
    final isMeals = kind == CatalogueKind.meals;
    return Scaffold(
      appBar: AppBar(title: Text('${type.label} ${kind.label.toLowerCase()}')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => isMeals
            ? openMealForm(context, type: type)
            : openRecipeForm(context, type: type),
        icon: const Icon(Icons.add),
        label: Text('Add ${kind.singular}'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                ItemImage(
                  source: type.image,
                  width: 72,
                  height: 72,
                  borderRadius: BorderRadius.circular(12),
                ),
                const SizedBox(width: 16),
                Expanded(child: Text(type.description)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText:
                    'Search ${type.label.toLowerCase()} '
                    '${kind.label.toLowerCase()}',
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: isMeals
                ? MealList(
                    type: type,
                    query: _query,
                    emptyMessage:
                        'No ${type.label.toLowerCase()} meals yet. '
                        'Tap "Add meal" to create one.',
                  )
                : RecipeList(
                    type: type,
                    query: _query,
                    emptyMessage:
                        'No ${type.label.toLowerCase()} recipes yet. '
                        'Tap "Add recipe" to create one.',
                  ),
          ),
        ],
      ),
    );
  }
}
