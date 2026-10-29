import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:yummealprep/app_services.dart';
import 'package:yummealprep/models/meal.dart';
import 'package:yummealprep/screens/navigation.dart';
import 'package:yummealprep/screens/share/pdf_share_screen.dart';
import 'package:yummealprep/services/pdf_documents.dart';
import 'package:yummealprep/utils/constants.dart';
import 'package:yummealprep/utils/dates.dart';
import 'package:yummealprep/utils/ui.dart';
import 'package:yummealprep/widgets/detail_layout.dart';
import 'package:yummealprep/widgets/item_image.dart';

enum _MealAction { edit, delete }

class MealDetailsScreen extends StatefulWidget {
  const MealDetailsScreen({required this.mealId, super.key});

  final String mealId;

  @override
  State<MealDetailsScreen> createState() => _MealDetailsScreenState();
}

class _MealDetailsScreenState extends State<MealDetailsScreen> {
  late final AppServices _services = AppScope.of(context);
  late final Stream<Meal?> _meal = _services.meals.watch(widget.mealId);

  Future<void> _addToPlan(Meal meal) async {
    final today = dateOnly(DateTime.now());
    final date = await showDatePicker(
      context: context,
      helpText: 'Plan ${meal.name} for',
      initialDate: today,
      firstDate: today,
      lastDate: lastPlannableDay(today),
    );
    if (date == null) return;
    await _services.mealPlan.add(mealId: meal.id, date: date, slot: meal.type);
    if (!mounted) return;
    showMessage(
      context,
      'Planned for ${meal.type.label.toLowerCase()} on '
      '${DateFormat('EEEE d MMMM').format(date)}',
    );
  }

  Future<void> _share(Meal meal) {
    final images = _services.images;
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => PdfShareScreen(
          title: 'Share meal',
          fileName: PdfDocuments.fileName(meal.name, 'meal'),
          buildPdf: (format) async => PdfDocuments.meal(
            meal,
            format: format,
            theme: await PdfDocuments.loadTheme(),
            image: await images.load(meal.image),
            logo: await images.load(Constants.appLogo),
            nutritionFacts: [
              for (final source in meal.nutritionFactImages)
                ?await images.load(source),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _delete(Meal meal) async {
    final confirmed = await confirm(
      context,
      title: 'Delete ${meal.name}?',
      message:
          'The meal will be removed from your meal plan too. '
          'This cannot be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    Navigator.pop(context);
    await _services.meals.delete(meal.id);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Meal?>(
      stream: _meal,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final meal = snapshot.data;
        if (meal == null) {
          return const ItemMissing(message: 'This meal has been deleted.');
        }
        return Scaffold(
          floatingActionButton: FloatingActionButton.extended(
            heroTag: null,
            onPressed: () => _addToPlan(meal),
            icon: const Icon(Icons.event),
            label: const Text('Add to plan'),
          ),
          body: DetailLayout(
            item: meal,
            actions: [
              FavouriteButton(
                isFavourite: meal.isFavourite,
                onPressed: () => _services.meals.setFavourite(
                  meal.id,
                  favourite: !meal.isFavourite,
                ),
              ),
              IconButton(
                tooltip: 'Share or print',
                icon: const Icon(Icons.share),
                onPressed: () => _share(meal),
              ),
              PopupMenuButton<_MealAction>(
                tooltip: 'More',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: 0.4),
                ),
                iconColor: Colors.white,
                onSelected: (action) => switch (action) {
                  _MealAction.edit => openMealForm(context, meal: meal),
                  _MealAction.delete => _delete(meal),
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: _MealAction.edit,
                    child: ListTile(
                      leading: Icon(Icons.edit),
                      title: Text('Edit'),
                    ),
                  ),
                  PopupMenuItem(
                    value: _MealAction.delete,
                    child: ListTile(
                      leading: Icon(Icons.delete),
                      title: Text('Delete'),
                    ),
                  ),
                ],
              ),
            ],
            children: [
              if (meal.drink.isNotEmpty || meal.sideDishes.isNotEmpty)
                const SizedBox(height: 8),
              if (meal.drink.isNotEmpty)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.local_cafe),
                  title: const Text('Drink'),
                  subtitle: Text(meal.drink),
                ),
              if (meal.sideDishes.isNotEmpty)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.rice_bowl),
                  title: const Text('Side dishes'),
                  subtitle: Text(meal.sideDishes.join(', ')),
                ),
              if (meal.description.isNotEmpty) ...[
                const SectionHeading('Description'),
                Text(meal.description),
              ],
              if (meal.nutritionFactImages.isNotEmpty) ...[
                const SectionHeading('Nutrition facts'),
                SizedBox(
                  height: 180,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: meal.nutritionFactImages.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final source = meal.nutritionFactImages[index];
                      return InkWell(
                        onTap: () => showImageViewer(
                          context,
                          source: source,
                          title: 'Nutrition facts',
                        ),
                        child: ItemImage(
                          source: source,
                          width: 130,
                          height: 180,
                          borderRadius: BorderRadius.circular(8),
                          semanticLabel: 'Nutrition facts label ${index + 1}',
                        ),
                      );
                    },
                  ),
                ),
              ],
              // Room for the floating button.
              const SizedBox(height: 72),
            ],
          ),
        );
      },
    );
  }
}
