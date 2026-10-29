import 'dart:async';

import 'package:flutter/material.dart';

import 'package:yummealprep/app_services.dart';
import 'package:yummealprep/data/catalogue_repository.dart';
import 'package:yummealprep/models/catalogue_item.dart';
import 'package:yummealprep/models/meal.dart';
import 'package:yummealprep/models/meal_type.dart';
import 'package:yummealprep/models/recipe.dart';
import 'package:yummealprep/widgets/catalogue_tiles.dart';
import 'package:yummealprep/widgets/empty_state.dart';

/// A live list of meals, optionally narrowed to a type, favourites or a
/// search query.
class MealList extends StatelessWidget {
  const MealList({
    this.type,
    this.query = '',
    this.favouritesOnly = false,
    this.emptyMessage = 'No meals yet.',
    this.onRemove,
    this.removeLabel = 'Remove',
    super.key,
  });

  final MealType? type;
  final String query;
  final bool favouritesOnly;
  final String emptyMessage;

  /// If set, rows can be swiped away and this is called with the meal.
  final ValueChanged<Meal>? onRemove;
  final String removeLabel;

  @override
  Widget build(BuildContext context) => CatalogueList<Meal>(
    watch: (services) => services.meals.watchAll(),
    type: type,
    query: query,
    favouritesOnly: favouritesOnly,
    emptyMessage: emptyMessage,
    onRemove: onRemove,
    removeLabel: removeLabel,
    itemBuilder: (meal) => MealTile(meal: meal),
  );
}

/// A live list of recipes, optionally narrowed to a type, favourites or a
/// search query.
class RecipeList extends StatelessWidget {
  const RecipeList({
    this.type,
    this.query = '',
    this.favouritesOnly = false,
    this.emptyMessage = 'No recipes yet.',
    this.onRemove,
    this.removeLabel = 'Remove',
    super.key,
  });

  final MealType? type;
  final String query;
  final bool favouritesOnly;
  final String emptyMessage;
  final ValueChanged<Recipe>? onRemove;
  final String removeLabel;

  @override
  Widget build(BuildContext context) => CatalogueList<Recipe>(
    watch: (services) => services.recipes.watchAll(),
    type: type,
    query: query,
    favouritesOnly: favouritesOnly,
    emptyMessage: emptyMessage,
    onRemove: onRemove,
    removeLabel: removeLabel,
    itemBuilder: (recipe) => RecipeTile(recipe: recipe),
  );
}

class CatalogueList<T extends CatalogueItem> extends StatefulWidget {
  const CatalogueList({
    required this.watch,
    required this.itemBuilder,
    required this.emptyMessage,
    this.type,
    this.query = '',
    this.favouritesOnly = false,
    this.onRemove,
    this.removeLabel = 'Remove',
    super.key,
  });

  final Stream<List<T>> Function(AppServices services) watch;
  final Widget Function(T item) itemBuilder;
  final String emptyMessage;
  final MealType? type;
  final String query;
  final bool favouritesOnly;
  final ValueChanged<T>? onRemove;
  final String removeLabel;

  @override
  State<CatalogueList<T>> createState() => _CatalogueListState<T>();
}

class _CatalogueListState<T extends CatalogueItem>
    extends State<CatalogueList<T>> {
  // Subscribed once, so typing a search query filters the latest list
  // instead of starting a new database query on every keystroke.
  StreamSubscription<List<T>>? _subscription;
  List<T>? _items;
  Object? _error;

  // Rows swiped away but not yet updated by the database stream. A
  // dismissed row has to leave the list straight away.
  final Set<String> _dismissed = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _subscription ??= widget
        .watch(AppScope.of(context))
        .listen(
          (items) => setState(() {
            _items = items;
            _error = null;
            _dismissed.clear();
          }),
          onError: (Object error) => setState(() => _error = error),
        );
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return EmptyState(
        message: 'Something went wrong loading this list.\n$_error',
        showImage: false,
      );
    }
    final all = _items;
    if (all == null) return const Center(child: CircularProgressIndicator());

    final items = filterItems(
      all.where((item) => !_dismissed.contains(item.id)),
      type: widget.type,
      favouritesOnly: widget.favouritesOnly,
      query: widget.query,
    );
    if (items.isEmpty) {
      return EmptyState(
        message: widget.query.trim().isEmpty
            ? widget.emptyMessage
            : 'Nothing matches "${widget.query.trim()}".',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(top: 8, bottom: 96),
      itemCount: items.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = items[index];
        final tile = widget.itemBuilder(item);
        final onRemove = widget.onRemove;
        if (onRemove == null) return tile;
        return Dismissible(
          key: ValueKey(item.id),
          direction: DismissDirection.endToStart,
          background: _RemoveBackground(label: widget.removeLabel),
          onDismissed: (direction) {
            setState(() => _dismissed.add(item.id));
            onRemove(item);
          },
          child: tile,
        );
      },
    );
  }
}

class _RemoveBackground extends StatelessWidget {
  const _RemoveBackground({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colours = Theme.of(context).colorScheme;
    return ColoredBox(
      color: colours.errorContainer,
      child: Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            label,
            style: TextStyle(
              color: colours.onErrorContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
