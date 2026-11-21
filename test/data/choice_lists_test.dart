// Dart imports:
import 'dart:convert';

// Package imports:
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast.dart';

// Project imports:
import 'package:yummealprep/app_services.dart';
import 'package:yummealprep/data/choice_list_repository.dart';
import 'package:yummealprep/data/sample_data.dart';
import 'package:yummealprep/models/meal.dart';
import 'package:yummealprep/models/meal_type.dart';
import 'package:yummealprep/models/recipe.dart';

void main() {
  late AppServices services;

  setUp(() async => services = await AppServices.inMemory());
  tearDown(() => services.close());

  String sampleJson({List<String>? sides, List<String>? drinks}) => jsonEncode({
    'format': 'yummealprep-backup',
    'version': 1,
    'sampleDataVersion': 1,
    'meals': [
      {
        'id': 'm',
        'name': 'Pelau',
        'type': 'lunch',
        'drink': 'Mauby',
        'sideDishes': ['Tossed Salad'],
      },
    ],
    'recipes': [
      {'id': 'r', 'name': 'Coleslaw', 'type': 'lunch', 'isSideDish': true},
    ],
    'sideDishes': ?sides,
    'drinks': ?drinks,
  });

  test('names are kept once, ignoring case, and listed A to Z', () async {
    await services.sideDishes.add(['Toast', 'coleslaw', ' ', 'Coleslaw']);
    await services.sideDishes.add(['TOAST', 'Baked Beans']);
    expect(await services.sideDishes.getAll(), [
      'Baked Beans',
      'coleslaw',
      'Toast',
    ]);
  });

  test('recipes with the Side dish switch on join the side dishes', () async {
    await services.recipes.save(
      const Recipe(id: 'a', name: 'Rice', type: MealType.lunch),
    );
    await services.recipes.save(
      const Recipe(
        id: 'b',
        name: 'Potato Salad',
        type: MealType.lunch,
        isSideDish: true,
      ),
    );
    expect(await services.sideDishes.getAll(), ['Potato Salad']);
  });

  test('a saved meal adds its drink and side dishes', () async {
    await services.meals.save(
      const Meal(
        id: 'm',
        name: 'Pelau',
        type: MealType.lunch,
        drink: 'Mauby',
        sideDishes: ['Coleslaw'],
      ),
    );
    expect(await services.drinks.getAll(), ['Mauby']);
    expect(await services.sideDishes.getAll(), ['Coleslaw']);
  });

  test('renaming changes the meals that use the name', () async {
    await services.meals.save(
      const Meal(
        id: 'm',
        name: 'Pelau',
        type: MealType.lunch,
        drink: 'Juice',
        sideDishes: ['Slaw', 'Toast'],
      ),
    );
    expect(await services.sideDishes.rename('Slaw', 'Coleslaw'), 1);
    expect(await services.drinks.rename('Juice', 'Orange Juice'), 1);

    final meal = (await services.meals.get('m'))!;
    expect(meal.sideDishes, ['Coleslaw', 'Toast']);
    expect(meal.drink, 'Orange Juice');
    expect(await services.sideDishes.getAll(), ['Coleslaw', 'Toast']);
  });

  test('removing a name leaves the meals that use it alone', () async {
    await services.meals.save(
      const Meal(
        id: 'm',
        name: 'Pelau',
        type: MealType.lunch,
        sideDishes: ['Coleslaw'],
      ),
    );
    await services.sideDishes.remove('Coleslaw');
    expect(await services.sideDishes.getAll(), isEmpty);
    expect((await services.meals.get('m'))!.sideDishes, ['Coleslaw']);
  });

  group('sample data', () {
    test('a new install starts with the sample lists', () async {
      await SampleData(
        services.database,
        services.settings,
      ).addFromJson(sampleJson(sides: ['Toast'], drinks: ['Water']));
      // Names the sample meals and recipes use are included too.
      expect(await services.sideDishes.getAll(), [
        'Coleslaw',
        'Toast',
        'Tossed Salad',
      ]);
      expect(await services.drinks.getAll(), ['Mauby', 'Water']);
    });

    test('an older install builds its lists from what it has', () async {
      // Sample data added before the lists existed, then a meal of its own.
      await services.settings.setSeedVersion(1);
      await services.database.db.transaction((transaction) async {
        await services.meals.store
            .record('own')
            .put(
              transaction,
              const Meal(
                id: 'own',
                name: 'Roti',
                type: MealType.lunch,
                drink: 'Sorrel',
              ).toMap(),
            );
      });
      await SampleData(
        services.database,
        services.settings,
      ).addFromJson(sampleJson(sides: ['Toast'], drinks: ['Water']));
      expect(await services.sideDishes.getAll(), ['Toast']);
      expect(await services.drinks.getAll(), ['Sorrel', 'Water']);
    });

    test('lists edited in the app are left alone', () async {
      final sample = SampleData(services.database, services.settings);
      await sample.addFromJson(sampleJson(sides: ['Toast']));
      await services.sideDishes.remove('Toast');
      await sample.addFromJson(sampleJson(sides: ['Toast']));
      expect(await services.sideDishes.getAll(), isNot(contains('Toast')));
    });
  });

  group('backups', () {
    test('carry the lists to another copy of the app', () async {
      await services.sideDishes.add(['Toast']);
      await services.drinks.add(['Water']);
      final backup = await services.backup.export();

      final other = await AppServices.inMemory();
      await other.backup.restore(backup);
      expect(await other.sideDishes.getAll(), ['Toast']);
      expect(await other.drinks.getAll(), ['Water']);
      await other.close();
    });

    test('replacing everything takes the file lists as they are', () async {
      await services.sideDishes.add(['Toast']);
      await services.backup.restore(
        utf8.encode(sampleJson(sides: ['Rice'], drinks: [])),
        replaceAll: true,
      );
      expect(await services.sideDishes.getAll(), [
        'Coleslaw',
        'Rice',
        'Tossed Salad',
      ]);
      expect(await services.drinks.getAll(), ['Mauby']);
    });

    test('a file without lists keeps the current ones', () async {
      await services.sideDishes.add(['Toast']);
      await services.backup.restore(
        utf8.encode(sampleJson()),
        replaceAll: true,
      );
      expect(
        await services.sideDishes.getAll(),
        containsAll(<String>['Toast', 'Coleslaw']),
      );
    });

    test('lists are written to the file', () async {
      await services.sideDishes.add(['Toast']);
      final json =
          jsonDecode(utf8.decode(await services.backup.export())) as Map;
      expect(json[ChoiceList.sideDishes.name], ['Toast']);
      expect(json[ChoiceList.drinks.name], isEmpty);
    });
  });
}
