import 'package:card_settings/card_settings.dart';
import 'package:flutter/material.dart';
import 'package:yummealprep/models/meal_item_model.dart';
import 'package:yummealprep/models/recipe_model.dart';
import 'package:yummealprep/utils/constants.dart';

const List<PickerModel> drinkTypes = <PickerModel>[
  PickerModel('Alcohol', code: 'Alc'),
  PickerModel('Coffee', code: 'Cof'),
  PickerModel('Soda', code: 'Sod'),
  PickerModel('Tea', code: 'Tea'),
  PickerModel('Water', code: 'Wat'),
];

const List<PickerModel> mealTypes = <PickerModel>[
  PickerModel('Appetisers', code: 'App'),
  PickerModel('Breakfast', code: 'Bre'),
  PickerModel('Lunch', code: 'Lun'),
  PickerModel('Dinner', code: 'Din'),
  PickerModel('Dessert', code: 'Des'),
  PickerModel('Smoothies', code: 'Smo'),
];

const List<PickerModel> recipeTypes = <PickerModel>[
  PickerModel('Appetisers', code: 'App'),
  PickerModel('Breakfast', code: 'Bre'),
  PickerModel('Lunch', code: 'Lun'),
  PickerModel('Dinner', code: 'Din'),
  PickerModel('Dessert', code: 'Des'),
  PickerModel('Smoothies', code: 'Smo'),
];

List<String> mealTypes1 = <String>[
  'Appetisers',
  'Breakfast',
  'Lunch',
  'Dinner',
  'Dessert',
  'Smoothies',
];

List<MealItemModel> mealTypes2 = const [
  MealItemModel(image: '${Constants.imageDir}food1.png', type: 'Appetisers'),
  MealItemModel(image: '${Constants.imageDir}food2.png', type: 'Breakfast'),
  MealItemModel(image: '${Constants.imageDir}food3.png', type: 'Lunch'),
  MealItemModel(image: '${Constants.imageDir}food4.png', type: 'Dinner'),
  MealItemModel(image: '${Constants.imageDir}food5.png', type: 'Dessert'),
  MealItemModel(image: '${Constants.imageDir}food6.png', type: 'Smoothies'),
];

List<RecipeModel> recipeTypes2 = const [
  RecipeModel(image: '${Constants.imageDir}food1.png', type: 'Appetisers'),
  RecipeModel(image: '${Constants.imageDir}food2.png', type: 'Breakfast'),
  RecipeModel(image: '${Constants.imageDir}food3.png', type: 'Lunch'),
  RecipeModel(image: '${Constants.imageDir}food4.png', type: 'Dinner'),
  RecipeModel(image: '${Constants.imageDir}food5.png', type: 'Dessert'),
  RecipeModel(image: '${Constants.imageDir}food6.png', type: 'Smoothies'),
];

List<Color> mealTypes1Colours = <Color>[
  Colors.green,
  Colors.amber,
  Colors.brown,
  Colors.purple,
  Colors.orange,
  Colors.pink
];

List<String> initialSideDishes = <String>[
  'Coleslaw',
  'Garlic Bread',
  'Macaroni Salad',
  'Potato Salad',
  'Tossed Salad'
];

List<String> appFeatures = <String>[
  '"Calendar" screen enables one to choose a day and the meals one would like to have on that day',
  '"Meals" screen which shows different types of meals and allows one to add a new meal',
  '"Recipe" screen which shows appetisers, breakfast, lunch, dinner, dessert and smoothie recipes',
];

const List<String> allSideDishes = <String>[
  'Baked Beans',
  'Baked Potatoes',
  'Broccoli',
  'Boiled Corn',
  'Coleslaw',
  'Dinner Rolls',
  'French Fries',
  'Fried Plantains',
  'Fruit Salad',
  'Garlic Bread',
  'Macaroni Salad',
  'Potato Salad',
  'Mashed Potatoes',
  'Roast Potatoes',
  'Roasted Vegetables',
  'Steamed Vegetables',
  'Sweat Ground Provisions',
  'Tossed Salad',
];

List<Map<String, dynamic>> allMeals = [
  {
    'category': 'Meals',
    'description':
        'Pancake with scrambled eggs is one of the most popular of foods worldwide. It is easy, quick and tastes delicious.',
    'drink': 'Chocolate Tea',
    'id': 'i9T9zZ2nxAN7gfz2iSLE',
    'image':
        'https://firebasestorage.googleapis.com/v0/b/yummealprep-adb3b.appspot.com/o/meals%2Fbreakfast%2Fpancake_and_scrambled_eggs.jpeg?alt=media&token=57f88e7c-4bcb-47b6-b474-8a45b2b28d51',
    //'gs://yummealprep-adb3b.appspot.com/meals/pancake_and_scrambled_eggs.png',
    'name': 'Pancake and Scrambled Eggs',
    'nutritionFacts':
        'gs://yummealprep-adb3b.appspot.com/nutrition_facts/pancake_and_scrambled_eggs_nutrition_facts.png',
    'searchKeywords': [
      'p',
      'pa',
      'pan',
      'panc',
      'panca',
      'pancak',
      'pancake',
      'pancake ',
      'pancake a',
      'pancake an',
      'pancake and',
      'pancake and ',
      'pancake and e',
      'pancake and eg',
      'pancake and egg',
      'pancake and eggs',
      'scrambled eggs',
    ],
    'sideDish': 'toast',
    'type': 'Breakfast'
  },
  {
    'category': 'Meals',
    'description':
        'Pelau is rice cooked with meats and vegetables where the meat is brown in sugar. It is a variation of East Indian pilau which originated in Persia where it is called polow.',
    'drink': 'Sorrel',
    'id': 't8jSPG4N7NwXt3t69lIk',
    'image':
        'https://firebasestorage.googleapis.com/v0/b/yummealprep-adb3b.appspot.com/o/meals%2Flunch%2Fpelau.jpeg?alt=media&token=19b0bd51-9abb-4850-bdf5-be730a50e96b',
    //'gs://yummealprep-adb3b.appspot.com/meals/pelau.png',
    'isMealLiked': false,
    'name': 'Pelau',
    'nutritionFacts':
        'gs://yummealprep-adb3b.appspot.com/nutrition_facts/pelau_nutrition_facts.png',
    'searchKeywords': ['p', 'pe', 'pel', 'pela', 'pelau'],
    'sideDish': 'coleslaw',
    'type': 'Lunch'
  },
];

List<Map<String, String>> mealSlotOption = [
  {
    'value': 'bmw-x1',
    'title': 'BMW X1',
    'slotName': 'Breakfast',
    'body': 'SUV'
  },
  {
    'value': 'bmw-x7',
    'title': 'BMW X7',
    'slotName': 'Breakfast',
    'body': 'SUV'
  },
  {
    'value': 'bmw-x2',
    'title': 'BMW X2',
    'slotName': 'Breakfast',
    'body': 'SUV'
  },
  {
    'value': 'bmw-x4',
    'title': 'BMW X4',
    'slotName': 'Breakfast',
    'body': 'SUV'
  },
  {
    'value': 'bmw-i3',
    'title': 'BMW i3',
    'slotName': 'Breakfast',
    'body': 'Hatchback'
  },
  {
    'value': 'bmw-sgc',
    'title': 'BMW 4-serie Gran Coupe',
    'slotName': 'Breakfast',
    'body': 'Hatchback'
  },
  {
    'value': 'bmw-sgt',
    'title': 'BMW 6-serie GT',
    'slotName': 'Breakfast',
    'body': 'Hatchback'
  },
];
