import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:yummealprep/app_services.dart';
import 'package:yummealprep/data/catalogue_repository.dart';
import 'package:yummealprep/models/meal.dart';
import 'package:yummealprep/models/meal_type.dart';
import 'package:yummealprep/screens/navigation.dart';
import 'package:yummealprep/widgets/catalogue_tiles.dart';
import 'package:yummealprep/widgets/empty_state.dart';
import 'package:yummealprep/widgets/item_image.dart';

/// The meal and slot picked in [showPlanMealSheet].
typedef PlanChoice = ({Meal meal, MealType slot});

/// Lets the user pick a slot and a meal to plan on [date].
Future<PlanChoice?> showPlanMealSheet(
  BuildContext context, {
  required DateTime date,
}) => showModalBottomSheet<PlanChoice>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (context) => DraggableScrollableSheet(
    expand: false,
    initialChildSize: 0.75,
    minChildSize: 0.4,
    builder: (context, scrollController) =>
        _PlanMealSheet(date: date, scrollController: scrollController),
  ),
);

class _PlanMealSheet extends StatefulWidget {
  const _PlanMealSheet({required this.date, required this.scrollController});

  final DateTime date;
  final ScrollController scrollController;

  @override
  State<_PlanMealSheet> createState() => _PlanMealSheetState();
}

class _PlanMealSheetState extends State<_PlanMealSheet> {
  MealType _slot = _slotForNow();
  bool _anyType = false;
  String _query = '';
  late final Stream<List<Meal>> _meals = AppScope.of(context).meals.watchAll();

  /// A sensible first slot for the time of day.
  static MealType _slotForNow() => switch (DateTime.now().hour) {
    < 11 => MealType.breakfast,
    < 16 => MealType.lunch,
    _ => MealType.dinner,
  };

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Plan a meal for ${DateFormat('EEEE d MMMM').format(widget.date)}',
            style: textTheme.titleLarge,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              for (final slot in MealType.values)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    avatar: Icon(slot.icon, color: slot.colour),
                    label: Text(slot.label),
                    selected: _slot == slot,
                    onSelected: (_) => setState(() => _slot = slot),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search meals',
              isDense: true,
            ),
            onChanged: (value) => setState(() => _query = value),
          ),
        ),
        SwitchListTile(
          dense: true,
          title: const Text('Include meals of every type'),
          value: _anyType,
          onChanged: (value) => setState(() => _anyType = value),
        ),
        const Divider(height: 1),
        Expanded(
          child: StreamBuilder<List<Meal>>(
            stream: _meals,
            builder: (context, snapshot) {
              final all = snapshot.data;
              if (all == null) {
                return const Center(child: CircularProgressIndicator());
              }
              final meals = filterItems(
                all,
                type: _anyType ? null : _slot,
                query: _query,
              );
              if (meals.isEmpty) {
                return EmptyState(
                  showImage: false,
                  message: _query.isEmpty
                      ? 'You have no ${_slot.label.toLowerCase()} meals yet.'
                      : 'No meals match "$_query".',
                  action: FilledButton.tonalIcon(
                    icon: const Icon(Icons.add),
                    label: const Text('Add a meal'),
                    onPressed: () => openMealForm(context, type: _slot),
                  ),
                );
              }
              return ListView.builder(
                controller: widget.scrollController,
                itemCount: meals.length,
                itemBuilder: (context, index) {
                  final meal = meals[index];
                  return ListTile(
                    leading: ItemImage(
                      source: meal.image,
                      width: 48,
                      height: 48,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    title: Text(meal.name),
                    subtitle: Text(
                      mealSummary(meal),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => Navigator.pop<PlanChoice>(context, (
                      meal: meal,
                      slot: _slot,
                    )),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
