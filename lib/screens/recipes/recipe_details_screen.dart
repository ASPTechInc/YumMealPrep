import 'package:flutter/material.dart';

import 'package:yummealprep/app_services.dart';
import 'package:yummealprep/models/recipe.dart';
import 'package:yummealprep/screens/navigation.dart';
import 'package:yummealprep/screens/share/pdf_share_screen.dart';
import 'package:yummealprep/services/pdf_documents.dart';
import 'package:yummealprep/utils/constants.dart';
import 'package:yummealprep/utils/ui.dart';
import 'package:yummealprep/widgets/detail_layout.dart';

enum _RecipeAction { edit, delete }

class RecipeDetailsScreen extends StatefulWidget {
  const RecipeDetailsScreen({required this.recipeId, super.key});

  final String recipeId;

  @override
  State<RecipeDetailsScreen> createState() => _RecipeDetailsScreenState();
}

class _RecipeDetailsScreenState extends State<RecipeDetailsScreen> {
  late final AppServices _services = AppScope.of(context);
  late final Stream<Recipe?> _recipe = _services.recipes.watch(widget.recipeId);

  // Ingredients ticked off while cooking. Not saved; they reset next time.
  final Set<int> _gathered = {};

  Future<void> _share(Recipe recipe) {
    final images = _services.images;
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => PdfShareScreen(
          title: 'Share recipe',
          fileName: PdfDocuments.fileName(recipe.name, 'recipe'),
          buildPdf: (format) async => PdfDocuments.recipe(
            recipe,
            format: format,
            theme: await PdfDocuments.loadTheme(),
            image: await images.load(recipe.image),
            logo: await images.load(Constants.appLogo),
          ),
        ),
      ),
    );
  }

  Future<void> _delete(Recipe recipe) async {
    final confirmed = await confirm(
      context,
      title: 'Delete ${recipe.name}?',
      message: 'This cannot be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    Navigator.pop(context);
    await _services.recipes.delete(recipe.id);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Recipe?>(
      stream: _recipe,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final recipe = snapshot.data;
        if (recipe == null) {
          return const ItemMissing(message: 'This recipe has been deleted.');
        }
        return Scaffold(
          body: DetailLayout(
            item: recipe,
            subtitle: recipe.isSideDish ? 'Side dish' : null,
            actions: [
              FavouriteButton(
                isFavourite: recipe.isFavourite,
                onPressed: () => _services.recipes.setFavourite(
                  recipe.id,
                  favourite: !recipe.isFavourite,
                ),
              ),
              IconButton(
                tooltip: 'Share or print',
                icon: const Icon(Icons.share),
                onPressed: () => _share(recipe),
              ),
              PopupMenuButton<_RecipeAction>(
                tooltip: 'More',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: 0.4),
                ),
                iconColor: Colors.white,
                onSelected: (action) => switch (action) {
                  _RecipeAction.edit => openRecipeForm(context, recipe: recipe),
                  _RecipeAction.delete => _delete(recipe),
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: _RecipeAction.edit,
                    child: ListTile(
                      leading: Icon(Icons.edit),
                      title: Text('Edit'),
                    ),
                  ),
                  PopupMenuItem(
                    value: _RecipeAction.delete,
                    child: ListTile(
                      leading: Icon(Icons.delete),
                      title: Text('Delete'),
                    ),
                  ),
                ],
              ),
            ],
            children: [
              const SizedBox(height: 16),
              _RecipeFacts(recipe: recipe),
              if (recipe.description.isNotEmpty) ...[
                const SectionHeading('Description'),
                Text(recipe.description),
              ],
              if (recipe.ingredients.isNotEmpty) ...[
                const SectionHeading('Ingredients'),
                for (final (index, ingredient) in recipe.ingredients.indexed)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                    value: _gathered.contains(index),
                    onChanged: (checked) => setState(
                      () => checked == true
                          ? _gathered.add(index)
                          : _gathered.remove(index),
                    ),
                    title: Text(
                      ingredient,
                      style: _gathered.contains(index)
                          ? const TextStyle(
                              decoration: TextDecoration.lineThrough,
                            )
                          : null,
                    ),
                  ),
              ],
              if (recipe.instructions.isNotEmpty) ...[
                const SectionHeading('Method'),
                for (final (index, step) in recipe.instructions.indexed)
                  _Step(number: index + 1, text: step),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _RecipeFacts extends StatelessWidget {
  const _RecipeFacts({required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    final facts = [
      if (recipe.preparationMinutes case final minutes?)
        (Icons.timer_outlined, 'Preparation', formatMinutes(minutes)),
      if (recipe.cookingMinutes case final minutes? when minutes > 0)
        (
          Icons.local_fire_department_outlined,
          'Cooking',
          formatMinutes(minutes),
        ),
      if (recipe.servings case final servings?)
        (Icons.people_outline, 'Serves', '$servings'),
    ];
    if (facts.isEmpty) return const SizedBox.shrink();
    final textTheme = Theme.of(context).textTheme;
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            // Equal shares of the width, wrapping long values such as
            // "1 hr 25 min" or large system text instead of overflowing.
            for (final (icon, label, value) in facts)
              Expanded(
                child: Column(
                  children: [
                    Icon(icon),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: textTheme.labelMedium,
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      value,
                      style: textTheme.titleSmall,
                      textAlign: TextAlign.center,
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

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colours = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: colours.primary,
            foregroundColor: colours.onPrimary,
            child: Text('$number'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(text),
            ),
          ),
        ],
      ),
    );
  }
}
