// Dart imports:
import 'dart:async';

// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

// Package imports:
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

// Project imports:
import 'package:yummealprep/app_services.dart';
import 'package:yummealprep/data/meal_plan_repository.dart';
import 'package:yummealprep/models/meal.dart';
import 'package:yummealprep/models/planned_meal.dart';
import 'package:yummealprep/screens/navigation.dart';
import 'package:yummealprep/screens/planner/plan_meal_sheet.dart';
import 'package:yummealprep/screens/settings/app_drawer.dart';
import 'package:yummealprep/utils/dates.dart';
import 'package:yummealprep/utils/ui.dart';
import 'package:yummealprep/widgets/empty_state.dart';
import 'package:yummealprep/widgets/item_image.dart';

/// A calendar of planned meals. Pick a day to see and change its meals.
class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  // Read each time, so the planner moves on if the app stays open past
  // midnight.
  DateTime get _today => dateOnly(DateTime.now());
  late DateTime _selectedDay = _today;
  late DateTime _focusedDay = _today;
  CalendarFormat _format = CalendarFormat.twoWeeks;

  final List<StreamSubscription<Object?>> _subscriptions = [];
  Map<DateTime, List<PlannedMeal>> _plan = const {};
  Map<String, Meal> _meals = const {};
  bool _loaded = false;

  // Entries swiped away but not yet gone from the database stream. A
  // dismissed row has to leave the list straight away.
  final Set<String> _removing = {};

  // While a day's meals are held and dragged across the calendar to copy
  // them, the day they came from and the day under the finger.
  DateTime? _dragFrom;
  DateTime? _dragTo;

  // The calendar's day cells on screen, to find the day under the finger.
  final Set<_RenderDayCell> _dayCells = {};

  AppServices get _services => AppScope.of(context);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_subscriptions.isNotEmpty) return;
    _subscriptions
      ..add(
        _services.mealPlan.watchAll().listen(
          (entries) => setState(() {
            _plan = groupByDay(entries);
            _removing.clear();
            _loaded = true;
          }),
        ),
      )
      ..add(
        _services.meals.watchAll().listen(
          (meals) => setState(
            () => _meals = {for (final meal in meals) meal.id: meal},
          ),
        ),
      );
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    super.dispose();
  }

  /// Planned meals whose meal still exists.
  List<PlannedMeal> _entriesFor(DateTime day) => [
    for (final entry in _plan[dateOnly(day)] ?? const <PlannedMeal>[])
      if (_meals.containsKey(entry.mealId) && !_removing.contains(entry.id))
        entry,
  ];

  Future<void> _planMeal() async {
    if (!isTodayOrLater(_selectedDay)) {
      showMessage(context, 'Meals can only be planned for today or later.');
      return;
    }
    final choice = await showPlanMealSheet(context, date: _selectedDay);
    if (choice == null || !mounted) return;
    await _services.mealPlan.add(
      mealId: choice.meal.id,
      date: _selectedDay,
      slot: choice.slot,
    );
  }

  Future<void> _remove(PlannedMeal entry) async {
    final meal = _meals[entry.mealId];
    setState(() => _removing.add(entry.id));
    await _services.mealPlan.remove(entry.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${meal?.name ?? 'Meal'} removed from the plan'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => unawaited(
              _services.mealPlan.add(
                mealId: entry.mealId,
                date: entry.date,
                slot: entry.slot,
              ),
            ),
          ),
        ),
      );
  }

  void _startDrag(DateTime pressed, DateTime focused) {
    final day = dateOnly(pressed);
    if (_entriesFor(day).isEmpty) {
      showMessage(
        context,
        'Plan a meal on this day first, then hold and drag it across '
        'the calendar to copy it to the days after.',
      );
      return;
    }
    unawaited(HapticFeedback.mediumImpact());
    setState(() {
      _selectedDay = day;
      _focusedDay = focused;
      _dragFrom = day;
      _dragTo = day;
    });
  }

  void _dragOver(PointerMoveEvent event) {
    final day = _dayAt(event.position);
    if (day == null || day == _dragTo) return;
    unawaited(HapticFeedback.selectionClick());
    setState(() => _dragTo = day);
  }

  DateTime? _dayAt(Offset position) {
    for (final cell in _dayCells) {
      if (!cell.hasSize) continue;
      if (cell.size.contains(cell.globalToLocal(position))) return cell.day;
    }
    return null;
  }

  /// The days a drag would copy to: neither the day the meals came from nor
  /// a day that cannot be planned.
  List<DateTime> _dragTargets() {
    final from = _dragFrom;
    final to = _dragTo;
    if (from == null || to == null) return const [];
    final last = lastPlannableDay(_today);
    return [
      for (final day in daysBetween(from, to))
        if (day != from && isTodayOrLater(day) && !day.isAfter(last)) day,
    ];
  }

  Future<void> _endDrag() async {
    final from = _dragFrom;
    final days = _dragTargets();
    setState(() {
      _dragFrom = null;
      _dragTo = null;
    });
    if (from == null || days.isEmpty) return;
    final copies = copyToDays(_entriesFor(from), days, _plan);
    if (copies.isEmpty) {
      showMessage(context, 'Those days already have these meals.');
      return;
    }
    await _services.mealPlan.addAll(copies);
    if (!mounted) return;
    final meals = copies.map((copy) => copy.mealId).toSet().length;
    final dayCount = copies.map((copy) => copy.date).toSet().length;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            '${meals == 1 ? 'Meal' : '$meals meals'} copied to '
            '${dayCount == 1 ? '1 day' : '$dayCount days'}',
          ),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => unawaited(
              _services.mealPlan.removeAll(copies.map((copy) => copy.id)),
            ),
          ),
        ),
      );
  }

  void _cancelDrag() => setState(() {
    _dragFrom = null;
    _dragTo = null;
  });

  void _goToToday() => setState(() {
    _selectedDay = _today;
    _focusedDay = _today;
  });

  @override
  Widget build(BuildContext context) {
    final colours = Theme.of(context).colorScheme;
    final entries = _entriesFor(_selectedDay);
    final dragFrom = _dragFrom;
    final dragTargets = _dragTargets().toSet();
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Meal Planner'),
        actions: [
          IconButton(
            tooltip: 'Go to today',
            icon: const Icon(Icons.today),
            onPressed: _goToToday,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        // Tabs stay mounted side by side, so their buttons must not share
        // the default hero tag.
        heroTag: null,
        onPressed: _planMeal,
        icon: const Icon(Icons.add),
        label: const Text('Plan a meal'),
      ),
      body: Column(
        children: [
          // Holding a day starts the drag through onDayLongPressed. The
          // calendar's long press then owns the pointer, so its page swipes
          // stay still, and this listener follows the finger.
          Listener(
            onPointerMove: dragFrom == null ? null : _dragOver,
            onPointerUp: dragFrom == null ? null : (_) => _endDrag(),
            onPointerCancel: dragFrom == null ? null : (_) => _cancelDrag(),
            child: TableCalendar<PlannedMeal>(
              firstDay: DateTime(_today.year - 1, _today.month),
              lastDay: lastPlannableDay(_today),
              focusedDay: _focusedDay,
              currentDay: _today,
              calendarFormat: _format,
              startingDayOfWeek: StartingDayOfWeek.monday,
              availableCalendarFormats: const {
                CalendarFormat.month: 'Month',
                CalendarFormat.twoWeeks: '2 weeks',
                CalendarFormat.week: 'Week',
              },
              selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
              eventLoader: _entriesFor,
              onDaySelected: (selected, focused) => setState(() {
                _selectedDay = dateOnly(selected);
                _focusedDay = focused;
              }),
              onDayLongPressed: _startDrag,
              onFormatChanged: (format) => setState(() => _format = format),
              onPageChanged: (focused) => _focusedDay = focused,
              headerStyle: HeaderStyle(
                // Label the button with the current view, not the next one.
                formatButtonShowsNext: false,
                formatButtonDecoration: BoxDecoration(
                  border: Border.all(color: colours.outline),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                todayDecoration: BoxDecoration(
                  color: colours.primaryContainer,
                  shape: BoxShape.circle,
                ),
                todayTextStyle: TextStyle(color: colours.onPrimaryContainer),
                selectedDecoration: BoxDecoration(
                  color: colours.primary,
                  shape: BoxShape.circle,
                ),
                selectedTextStyle: TextStyle(color: colours.onPrimary),
              ),
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, day, events) =>
                    events.isEmpty ? null : _DayMarkers(entries: events),
                // Called for every day cell, so it also tags each cell with
                // its day for _dayAt. Ranges are not used otherwise.
                rangeHighlightBuilder: (context, day, _) {
                  final date = dateOnly(day);
                  final highlighted =
                      date == dragFrom || dragTargets.contains(date);
                  return Positioned.fill(
                    child: _DayCell(
                      day: date,
                      cells: _dayCells,
                      child: highlighted
                          ? Container(
                              margin: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: date == dragFrom
                                    ? colours.primaryContainer
                                    : colours.secondaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                            )
                          : null,
                    ),
                  );
                },
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    DateFormat('EEEE d MMMM').format(_selectedDay),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (entries.isNotEmpty)
                  Text(
                    entries.length == 1 ? '1 meal' : '${entries.length} meals',
                  ),
              ],
            ),
          ),
          Expanded(
            child: !_loaded
                ? const Center(child: CircularProgressIndicator())
                : entries.isEmpty
                ? EmptyState(
                    message: 'No meals planned for this day.',
                    showImage: false,
                    action: isTodayOrLater(_selectedDay)
                        ? FilledButton.tonalIcon(
                            onPressed: _planMeal,
                            icon: const Icon(Icons.add),
                            label: const Text('Plan a meal'),
                          )
                        : null,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 96),
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      return _PlannedMealTile(
                        key: ValueKey(entry.id),
                        entry: entry,
                        meal: _meals[entry.mealId]!,
                        onRemove: () => _remove(entry),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Marks a calendar cell with its [day], for finding the day under a drag.
class _DayCell extends SingleChildRenderObjectWidget {
  const _DayCell({required this.day, required this.cells, super.child});

  final DateTime day;
  final Set<_RenderDayCell> cells;

  @override
  _RenderDayCell createRenderObject(BuildContext context) =>
      _RenderDayCell(day, cells);

  @override
  void updateRenderObject(BuildContext context, _RenderDayCell renderObject) {
    renderObject.day = day;
  }
}

class _RenderDayCell extends RenderProxyBox {
  _RenderDayCell(this.day, this._cells);

  DateTime day;
  final Set<_RenderDayCell> _cells;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _cells.add(this);
  }

  @override
  void detach() {
    _cells.remove(this);
    super.detach();
  }
}

/// Up to four dots under a day, coloured by slot.
class _DayMarkers extends StatelessWidget {
  const _DayMarkers({required this.entries});

  final List<PlannedMeal> entries;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 4,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final entry in entries.take(4))
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: entry.slot.colour,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}

class _PlannedMealTile extends StatelessWidget {
  const _PlannedMealTile({
    required this.entry,
    required this.meal,
    required this.onRemove,
    super.key,
  });

  final PlannedMeal entry;
  final Meal meal;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colours = Theme.of(context).colorScheme;
    return Dismissible(
      key: ValueKey(entry.id),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) => onRemove(),
      background: ColoredBox(
        color: colours.errorContainer,
        child: Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Icon(Icons.delete, color: colours.onErrorContainer),
          ),
        ),
      ),
      child: ListTile(
        onTap: () => openMeal(context, meal.id),
        leading: ItemImage(
          source: meal.image,
          width: 56,
          height: 56,
          borderRadius: BorderRadius.circular(8),
        ),
        title: Text(meal.name),
        subtitle: Row(
          children: [
            Icon(entry.slot.icon, size: 16, color: entry.slot.colour),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                [
                  entry.slot.label,
                  if (meal.drink.isNotEmpty) meal.drink,
                ].join(' · '),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        trailing: IconButton(
          tooltip: 'Remove from plan',
          icon: const Icon(Icons.close),
          onPressed: onRemove,
        ),
      ),
    );
  }
}
